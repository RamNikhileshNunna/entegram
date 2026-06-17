import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../db/models/ente_file.dart';
import '../network/ente_api.dart';
import '../sync/crypto_isolate.dart';

/// Fetches and decrypts file thumbnails for the feed.
///
/// Flow per file: in-memory cache → on-disk cache → download encrypted bytes
/// ([EnteApi.downloadThumbnail]) → decrypt in the [CryptoIsolate] → cache. The
/// decrypted plaintext JPEG is what the UI renders; key material never leaves
/// the isolate.
///
/// Network downloads are throttled to [_maxConcurrent] simultaneous requests
/// (same limit the official Ente app uses) so the server doesn't rate-limit us
/// when a memory with 30+ slides first loads.
class ThumbnailService {
  ThumbnailService({required EnteApi api, required CryptoIsolate crypto})
    : _api = api,
      _crypto = crypto;

  final EnteApi _api;
  final CryptoIsolate _crypto;

  // LRU in-memory cache capped at _kMaxMemory entries. A LinkedHashMap is
  // insertion-ordered; on a cache hit we remove-then-reinsert to bubble the
  // entry to the "recently used" end, so the oldest entry is always first.
  // 1000 matches the official Ente app's in-memory thumbnail LRU.
  static const int _kMaxMemory = 1000;
  final _memory = <int, Uint8List>{};
  final Map<int, Future<Uint8List?>> _inflight = {};
  Directory? _cacheDir;

  // Download concurrency semaphore. The thumbnails are served from the
  // edge-cached CDN worker (or the endpoint), which comfortably handles a high
  // fan-out, so we allow more parallelism than the old conservative limit for
  // snappier grid fills.
  static const _maxConcurrent = 40;
  var _activeDownloads = 0;
  final _waiters = <Completer<void>>[];

  Future<void> _acquireSlot() async {
    while (_activeDownloads >= _maxConcurrent) {
      final c = Completer<void>();
      _waiters.add(c);
      await c.future;
    }
    _activeDownloads++;
  }

  void _releaseSlot() {
    _activeDownloads--;
    // Serve the most recent waiter first (LIFO). When the user scrolls, the
    // thumbnails now on screen were requested last, so they jump ahead of the
    // pile of stale off-screen prefetches — what's visible loads first instead
    // of waiting behind everything ever requested.
    if (_waiters.isNotEmpty) _waiters.removeLast().complete();
  }

  Future<Directory> _dir() async {
    final cached = _cacheDir;
    if (cached != null) return cached;
    final base = await getApplicationCacheDirectory();
    final dir = Directory('${base.path}/thumbs');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return _cacheDir = dir;
  }

  void _memoryPut(int id, Uint8List bytes) {
    _memory.remove(id); // move to end if already present
    _memory[id] = bytes;
    if (_memory.length > _kMaxMemory) {
      _memory.remove(_memory.keys.first); // evict oldest
    }
  }

  /// Kicks off thumbnail downloads in the background for [files].
  /// Idempotent — already-cached or in-flight files are skipped automatically.
  void prefetch(Iterable<EnteFile> files) {
    for (final f in files) {
      get(f).ignore();
    }
  }

  /// Synchronous peek into the in-memory LRU. Returns already-decrypted
  /// thumbnail bytes if present, else null — lets callers (e.g. the story
  /// viewer) paint the cover instantly without awaiting a future or flashing a
  /// spinner. On a hit the entry is bubbled to the most-recently-used end.
  Uint8List? cached(EnteFile file) {
    final hit = _memory[file.id];
    if (hit != null) {
      _memory.remove(file.id);
      _memory[file.id] = hit;
    }
    return hit;
  }

  /// Returns decrypted thumbnail bytes, or null if this file can't produce one
  /// (e.g. missing key material). De-duplicates concurrent requests.
  Future<Uint8List?> get(EnteFile file) {
    final hit = _memory[file.id];
    if (hit != null) {
      // Bubble to most-recently-used end.
      _memory.remove(file.id);
      _memory[file.id] = hit;
      return Future.value(hit);
    }
    var f = _inflight[file.id];
    if (f == null) {
      f = _load(file);
      _inflight[file.id] = f;
      // .ignore() on the whenComplete-derived future so its error (e.g. Dio
      // cancel on app close) doesn't become an unhandled exception — the
      // original future `f` is what callers await and handle errors on.
      f.whenComplete(() => _inflight.remove(file.id)).ignore();
    }
    return f;
  }

  static const _maxRetries = 3;

  Future<Uint8List?> _load(EnteFile file) async {
    final encryptedKey = file.encryptedKey;
    final nonce = file.keyDecryptionNonce;
    final header = file.thumbnailDecryptionHeader;
    if (encryptedKey == null || nonce == null || header == null) return null;

    final cacheFile = File('${(await _dir()).path}/${file.id}.jpg');
    if (cacheFile.existsSync()) {
      final bytes = await cacheFile.readAsBytes();
      if (bytes.length > 64) {
        _memoryPut(file.id, bytes);
        return bytes;
      }
      // Truncated or corrupt — delete and re-download.
      await cacheFile.delete();
    }

    // A concurrency slot is held ONLY for the actual network call — never
    // across the retry backoff — so a slow/failing thumbnail can't park a slot
    // and starve everything else in the queue.
    Uint8List? encrypted;
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      await _acquireSlot();
      try {
        encrypted = await _api.downloadThumbnail(file.id);
        break;
      } on DioException catch (e) {
        if (attempt == _maxRetries - 1) rethrow;
        // Retry timeouts, dropped connections, and transient server errors
        // (429 rate-limit / 5xx) — common when many downloads briefly hit the
        // server at once.
        if (!EnteApi.isTransient(e)) rethrow;
      } finally {
        _releaseSlot();
      }
      // Backoff happens with no slot held.
      await Future.delayed(Duration(seconds: attempt + 1));
    }

    final plain = await _crypto.decryptThumbnail(
      collectionID: file.collectionID,
      encryptedFileKeyB64: encryptedKey,
      keyNonceB64: nonce,
      thumbnailHeaderB64: header,
      encryptedBytes: encrypted!,
    );

    _memoryPut(file.id, plain);
    await cacheFile.writeAsBytes(plain, flush: true);
    return plain;
  }
}
