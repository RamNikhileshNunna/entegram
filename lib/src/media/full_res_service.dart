import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../db/models/ente_file.dart';
import '../network/ente_api.dart';
import '../sync/crypto_isolate.dart';

/// Thrown when a download was cancelled via [FullResService.cancelImage].
/// Callers should retry the fetch if the file is still needed.
class ImageDownloadCancelledException implements Exception {
  const ImageDownloadCancelledException();
}

/// Downloads and decrypts full-resolution files on demand.
///
/// Images: LRU in-memory cache capped at [_kMaxImages] entries.
/// Videos: streamed-download + chunk-decrypted to a temp file on disk.
///
/// Video progress: call [prepareVideoProgressTracking] before [getVideoPath]
/// to receive download/decrypt events; subscribe via [videoProgressStream].
/// Values 0..1 = download percentage; exactly 1.0 = decrypting phase.
class FullResService {
  FullResService({required EnteApi api, required CryptoIsolate crypto})
    : _api = api,
      _crypto = crypto;

  final EnteApi _api;
  final CryptoIsolate _crypto;

  // 50-entry memory LRU — enough to keep the current story bundle warm while
  // the user swipes through slides, without excessive RAM usage.
  static const int _kMaxImages = 50;
  final _imageCache = <int, Uint8List>{};
  final Map<int, String> _videoCache = {};
  final Map<int, Future<Uint8List>> _imageInflight = {};
  final Map<int, Future<String>> _videoInflight = {};
  // CancelTokens for in-flight image downloads — keyed by file ID.
  final Map<int, CancelToken> _imageCancelTokens = {};

  // Disk cache for decrypted image bytes — survives in-memory evictions so
  // swiping back through story slides doesn't re-download.
  Directory? _imageCacheDir;

  Future<Directory> _dir() async {
    if (_imageCacheDir != null) return _imageCacheDir!;
    final base = await getApplicationCacheDirectory();
    final dir = Directory('${base.path}/fullres');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return _imageCacheDir = dir;
  }

  // Broadcast StreamControllers for video download/decrypt progress.
  final Map<int, StreamController<double>> _progressControllers = {};

  // Broadcast StreamControllers for full-res image download progress. Lets the
  // story / full-screen viewer show a determinate loading indicator while the
  // crisp original streams in over the already-painted thumbnail.
  final Map<int, StreamController<double>> _imageProgressControllers = {};

  void _imagePut(int id, Uint8List bytes) {
    _imageCache.remove(id);
    _imageCache[id] = bytes;
    if (_imageCache.length > _kMaxImages) {
      _imageCache.remove(_imageCache.keys.first);
    }
  }

  bool hasImageCached(int fileId) => _imageCache.containsKey(fileId);

  /// Call this **before** [getImageBytes] to receive download progress for the
  /// image. No-op if a controller already exists. The stream emits the download
  /// fraction (0.0–1.0) and completes when the bytes are ready (or on error /
  /// cache hit, where no events are emitted before completion).
  void prepareImageProgressTracking(int fileId) {
    _imageProgressControllers.putIfAbsent(
      fileId,
      () => StreamController<double>.broadcast(),
    );
  }

  /// Stream of download-progress fractions (0.0–1.0) for image [fileId].
  Stream<double> imageProgressStream(int fileId) =>
      _imageProgressControllers[fileId]?.stream ?? const Stream.empty();

  /// Cancels the in-flight download for [fileId] if one is running.
  /// The inflight Future will complete with [ImageDownloadCancelledException].
  void cancelImage(int fileId) {
    _imageCancelTokens[fileId]?.cancel();
  }

  /// Cancels every in-flight image download whose ID is NOT in [keepIds].
  /// Call this when the viewer navigates so stale prefetches don't compete
  /// with the photo the user is actually looking at.
  void cancelAllImagesExcept(Set<int> keepIds) {
    for (final entry in _imageCancelTokens.entries.toList()) {
      if (!keepIds.contains(entry.key)) entry.value.cancel();
    }
  }

  bool canDecrypt(EnteFile file) =>
      file.encryptedKey != null &&
      file.keyDecryptionNonce != null &&
      file.fileDecryptionHeader != null;

  /// Call this **before** [getVideoPath] to receive progress events for the
  /// given file. If a controller already exists (e.g. from a prefetch), this
  /// is a no-op — you will still receive future events via the stream.
  void prepareVideoProgressTracking(int fileId) {
    _progressControllers.putIfAbsent(
      fileId,
      () => StreamController<double>.broadcast(),
    );
  }

  /// Stream of progress values for the video download of [fileId].
  /// Values 0.0 – <1.0 = download fraction; 1.0 = decrypting.
  /// Completes when the download/decrypt finishes or errors.
  Stream<double> videoProgressStream(int fileId) =>
      _progressControllers[fileId]?.stream ?? const Stream.empty();

  /// Returns decrypted image bytes for [file]. LRU-cached in memory.
  Future<Uint8List> getImageBytes(EnteFile file) {
    final hit = _imageCache[file.id];
    if (hit != null) {
      _imageCache.remove(file.id);
      _imageCache[file.id] = hit;
      // Already in memory — no download will run, so tear down any progress
      // channel a caller optimistically prepared.
      _imageProgressControllers.remove(file.id)?.close();
      return Future.value(hit);
    }
    var f = _imageInflight[file.id];
    if (f == null) {
      f = _fetchImage(file);
      _imageInflight[file.id] = f;
      f.whenComplete(() => _imageInflight.remove(file.id)).ignore();
    }
    return f;
  }

  Future<Uint8List> _fetchImage(EnteFile file) async {
    final progressCtrl = _imageProgressControllers[file.id];
    try {
      // Check disk cache before hitting the network.
      final dir = await _dir();
      final cached = File('${dir.path}/${file.id}');
      if (cached.existsSync()) {
        final bytes = await cached.readAsBytes();
        if (bytes.length > 64) {
          debugPrint('[fullres] disk cache hit ${file.id}');
          _imagePut(file.id, bytes);
          return bytes;
        }
        await cached.delete();
      }

      debugPrint('[fullres] downloading image ${file.id}');
      final cancelToken = CancelToken();
      _imageCancelTokens[file.id] = cancelToken;
      try {
        final encrypted = await _downloadWithRetry(
          file.id,
          cancelToken,
          onProgress: progressCtrl == null
              ? null
              : (received, total) {
                  if (total > 0 && !progressCtrl.isClosed) {
                    progressCtrl.add((received / total).clamp(0.0, 1.0));
                  }
                },
        );
        final bytes = await _crypto.decryptFileContent(
          collectionID: file.collectionID,
          encryptedFileKeyB64: file.encryptedKey!,
          keyNonceB64: file.keyDecryptionNonce!,
          fileHeaderB64: file.fileDecryptionHeader!,
          encryptedBytes: encrypted,
        );
        _imagePut(file.id, bytes);
        // Write to disk cache in background — don't block the caller.
        cached.writeAsBytes(bytes, flush: true).ignore();
        return bytes;
      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel) {
          throw const ImageDownloadCancelledException();
        }
        rethrow;
      } finally {
        _imageCancelTokens.remove(file.id);
      }
    } finally {
      // Always tear down the progress channel so a subscribed viewer knows the
      // download is over (success, error, or cancel) and hides its indicator.
      _imageProgressControllers.remove(file.id)?.close();
    }
  }

  // Up to 3 attempts for a full-res download — a single transient blip
  // (timeout, 429 rate-limit, 5xx) otherwise leaves the story/post stuck on
  // the blurry thumbnail forever because callers swallow the error.
  static const int _maxImageRetries = 3;

  Future<Uint8List> _downloadWithRetry(
    int fileId,
    CancelToken token, {
    void Function(int received, int total)? onProgress,
  }) async {
    for (var attempt = 0; ; attempt++) {
      try {
        return await _api.downloadFile(
          fileId,
          cancelToken: token,
          onReceiveProgress: onProgress,
        );
      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel) rethrow;
        final lastAttempt = attempt >= _maxImageRetries - 1;
        if (lastAttempt || !EnteApi.isTransient(e)) rethrow;
        // Linear backoff: 0.5s, 1s. Keeps a rate-limited server from being
        // hammered while still recovering quickly from a one-off blip.
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        if (token.isCancelled) rethrow;
      }
    }
  }

  /// Returns the path to a decrypted video temp file.
  /// Subscribe to [videoProgressStream] before calling this to receive progress.
  Future<String> getVideoPath(EnteFile file) {
    final hit = _videoCache[file.id];
    if (hit != null && File(hit).existsSync()) return Future.value(hit);
    var f = _videoInflight[file.id];
    if (f == null) {
      f = _fetchVideo(file);
      _videoInflight[file.id] = f;
      f.whenComplete(() => _videoInflight.remove(file.id)).ignore();
    }
    return f;
  }

  Future<String> _fetchVideo(EnteFile file) async {
    debugPrint('[fullres] streaming video ${file.id}');
    final dir = await getTemporaryDirectory();
    final ext = _videoExt(file.title);
    final encPath = '${dir.path}/ente_enc_${file.id}';
    final decPath = '${dir.path}/ente_vid_${file.id}.$ext';
    final progressCtrl = _progressControllers[file.id];
    try {
      await _api.downloadFileToDisk(
        file.id,
        encPath,
        onProgress: progressCtrl == null
            ? null
            : (received, total) {
                if (total > 0) {
                  final frac = (received / total).clamp(0.0, 0.99);
                  if (!progressCtrl.isClosed) progressCtrl.add(frac);
                }
              },
      );
      // Signal decrypting phase
      if (progressCtrl != null && !progressCtrl.isClosed) {
        progressCtrl.add(1.0);
      }
      await _crypto.decryptFileToDisk(
        collectionID: file.collectionID,
        encryptedFileKeyB64: file.encryptedKey!,
        keyNonceB64: file.keyDecryptionNonce!,
        fileHeaderB64: file.fileDecryptionHeader!,
        inputPath: encPath,
        outputPath: decPath,
      );
      _videoCache[file.id] = decPath;
      return decPath;
    } finally {
      try {
        await File(encPath).delete();
      } catch (_) {}
      _progressControllers.remove(file.id)?.close();
    }
  }

  /// Kicks off full-res image downloads in the background for the first
  /// [limit] image files.
  void prefetchImages(Iterable<EnteFile> files, {int limit = 4}) {
    var count = 0;
    for (final f in files) {
      if (count >= limit) break;
      if (f.fileType != 0) continue;
      if (!canDecrypt(f)) continue;
      if (_imageCache.containsKey(f.id)) continue;
      count++;
      getImageBytes(f).ignore();
    }
  }

  static String _videoExt(String? title) {
    if (title == null) return 'mp4';
    final dot = title.lastIndexOf('.');
    return dot >= 0 ? title.substring(dot + 1).toLowerCase() : 'mp4';
  }
}
