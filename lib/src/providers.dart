import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth/auth_models.dart';
import 'auth/auth_service.dart';
import 'db/isar_db.dart';
import 'db/models/ente_collection.dart';
import 'db/models/ente_file.dart';
import 'db/models/memory_cluster.dart';
import 'db/models/person.dart';
import 'media/full_res_service.dart';
import 'media/thumbnail_service.dart';
import 'memories/memory_mapper.dart';
import 'network/ente_api.dart';
import 'sync/crypto_isolate.dart';
import 'sync/sync_service.dart';

/// The local database — the single source of truth the UI reads from.
final isarDbProvider = FutureProvider<IsarDb>((ref) => IsarDb.open());

/// The remote ID of the account owner (used to filter "self" chips from feed).
/// Written by MemoryMapper after self-detection; null until first rebuild.
/// Synchronous because sharedPreferencesProvider is preloaded before runApp.
final selfRemoteIdProvider = Provider<String?>((ref) {
  return ref.watch(sharedPreferencesProvider).getString(kSelfRemoteIdPref);
});

/// Preloaded SharedPreferences instance. Overridden in main() before runApp so
/// both EndpointController and SessionNotifier can read it synchronously in
/// their build() methods — eliminating the async race where bootstrap started
/// against the wrong endpoint before the saved URL was loaded.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main()');
});

/// The Ente server endpoint. Defaults to the official api.ente.io and can be
/// pointed at a self-hosted instance via the 7-tap developer dialog. Persisted
/// across launches via SharedPreferences.
const String kDefaultEndpoint = 'https://api.ente.io';
const String _endpointPrefKey = 'ente_endpoint';

class EndpointController extends Notifier<String> {
  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getString(_endpointPrefKey);
    return (saved != null && saved.isNotEmpty) ? saved : kDefaultEndpoint;
  }

  /// Normalizes (keeps an explicit http/https scheme, otherwise assumes https;
  /// trims a trailing slash), stores, and persists a user-entered endpoint.
  /// Empty resets to the default.
  Future<void> set(String raw) async {
    final url = normalize(raw);
    state = url;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_endpointPrefKey, url);
  }

  static String normalize(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return kDefaultEndpoint;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }
}

final endpointProvider = NotifierProvider<EndpointController, String>(
  EndpointController.new,
);

/// Ente REST client (no auth token until login), bound to the active endpoint.
final enteApiProvider = Provider<EnteApi>(
  (ref) => EnteApi(baseUrl: ref.watch(endpointProvider)),
);

/// SRP login service.
final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(enteApiProvider)),
);

const _kToken = 'session_token';
const _kMasterKey = 'session_master_key';
const _kSecretKey = 'session_secret_key';
const _kPublicKey = 'session_public_key';
const _kUserID = 'session_user_id';

/// Current session (null until logged in). Persisted to SharedPreferences so
/// the user stays logged in across restarts. Reads synchronously from the
/// preloaded sharedPreferencesProvider so session is available immediately
/// (no async race with endpoint or bootstrap).
class SessionNotifier extends Notifier<Session?> {
  @override
  Session? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final token = prefs.getString(_kToken);
    if (token == null || token.isEmpty) return null;
    final mk = prefs.getString(_kMasterKey);
    final sk = prefs.getString(_kSecretKey);
    final pk = prefs.getString(_kPublicKey);
    if (mk == null || sk == null || pk == null) return null;
    return Session(
      token: token,
      masterKey: base64Decode(mk),
      secretKey: base64Decode(sk),
      publicKey: base64Decode(pk),
      userID: prefs.getInt(_kUserID) ?? 0,
    );
  }

  Future<void> set(Session session) async {
    state = session;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kToken, session.token);
    await prefs.setString(_kMasterKey, base64Encode(session.masterKey));
    await prefs.setString(_kSecretKey, base64Encode(session.secretKey));
    await prefs.setString(_kPublicKey, base64Encode(session.publicKey));
    await prefs.setInt(_kUserID, session.userID);
  }

  Future<void> logout() async {
    state = null;
    final prefs = ref.read(sharedPreferencesProvider);
    for (final k in [_kToken, _kMasterKey, _kSecretKey, _kPublicKey]) {
      await prefs.remove(k);
    }
    await prefs.remove(_kUserID);
    final db = await ref.read(isarDbProvider.future);
    await db.isar.writeTxn(() async {
      await db.isar.enteFiles.clear();
      await db.isar.enteCollections.clear();
      await db.isar.persons.clear();
      await db.isar.memoryClusters.clear();
    });
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, Session?>(
  SessionNotifier.new,
);

/// UI state for the multi-step login flow.
sealed class LoginUiState {
  const LoginUiState();
}

class LoginIdle extends LoginUiState {
  const LoginIdle([this.error]);
  final String? error;
}

class LoginSubmitting extends LoginUiState {
  const LoginSubmitting();
}

class LoginNeedsTotp extends LoginUiState {
  const LoginNeedsTotp([this.error]);
  final String? error;
}

/// Drives sign-in: SRP, optional TOTP second factor, then sets [sessionProvider].
class LoginController extends Notifier<LoginUiState> {
  String? _sessionID;
  Uint8List? _kek;

  @override
  LoginUiState build() => const LoginIdle();

  Future<void> signIn({
    required String email,
    required String password,
    String endpoint = '',
  }) async {
    if (endpoint.isNotEmpty) {
      await ref.read(endpointProvider.notifier).set(endpoint);
    }
    state = const LoginSubmitting();
    try {
      final result = await ref.read(authServiceProvider).login(
        email: email,
        password: password,
      );
      switch (result) {
        case LoginSuccess(:final session):
          await ref.read(sessionProvider.notifier).set(session);
          state = const LoginIdle();
        case LoginTwoFactorRequired(:final sessionID, :final kek, :final isPasskey):
          if (isPasskey) {
            state = const LoginIdle(
              'Passkey 2FA isn\'t supported yet. Use an authenticator app or '
              'a recovery code.',
            );
            return;
          }
          _sessionID = sessionID;
          _kek = kek;
          state = const LoginNeedsTotp();
      }
    } on EmailMfaUnsupportedException catch (e) {
      state = LoginIdle(e.toString());
    } catch (e) {
      state = LoginIdle(_friendlyError(e));
    }
  }

  Future<void> submitTotp(String code) async {
    final sessionID = _sessionID;
    final kek = _kek;
    if (sessionID == null || kek == null) {
      state = const LoginIdle('Session expired — please sign in again.');
      return;
    }
    state = const LoginSubmitting();
    try {
      final session = await ref.read(authServiceProvider).verifyTotp(
        sessionID: sessionID,
        code: code.trim(),
        kek: kek,
      );
      await ref.read(sessionProvider.notifier).set(session);
      _sessionID = null;
      _kek = null;
      state = const LoginIdle();
    } catch (e) {
      final status = e is DioException ? e.response?.statusCode : null;
      state = LoginNeedsTotp(
        status == 404
            ? 'Session expired — please sign in again.'
            : 'Incorrect or expired code.',
      );
    }
  }

  void cancelTotp() {
    _sessionID = null;
    _kek = null;
    state = const LoginIdle();
  }

  /// Turns a raw error (usually a [DioException]) into a concise, server-aware
  /// message including the HTTP status and any message the server returned.
  static String _friendlyError(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      final serverMsg = data is Map
          ? (data['message'] ?? data['code'] ?? data).toString()
          : (data?.toString());
      final where = e.requestOptions.path;
      return 'Sign-in failed (HTTP ${status ?? 'no response'}) at $where'
          '${serverMsg != null && serverMsg.isNotEmpty ? ': $serverMsg' : ''}';
    }
    return 'Sign-in failed: $e';
  }
}

final loginControllerProvider =
    NotifierProvider<LoginController, LoginUiState>(LoginController.new);

/// The reactive feed of memories. The UI watches this; the background pipeline
/// writes [MemoryCluster]s into Isar and the stream pushes updates here.
/// Includes all memory kinds so accounts without ML (no people memories) still
/// see onThisDay/trip/season memories in the feed.
final memoriesProvider = StreamProvider<List<MemoryCluster>>((ref) async* {
  final db = await ref.watch(isarDbProvider.future);
  yield* db.isar.memoryClusters.where().watch(fireImmediately: true);
});

/// Stories bar: all memory kinds — people sessions/spotlight/last-time,
/// on-this-day (including recent "last week" etc.), and year/season summaries.
final storiesMemoriesProvider = StreamProvider<List<MemoryCluster>>((ref) async* {
  final db = await ref.watch(isarDbProvider.future);
  yield* db.isar.memoryClusters
      .filter()
      .kindEqualTo(MemoryKind.people)
      .or()
      .kindEqualTo(MemoryKind.onThisDay)
      .or()
      .kindEqualTo(MemoryKind.trip)
      .watch(fireImmediately: true);
});

/// Owns the decryption isolate + sync orchestration for the logged-in session.
final syncControllerProvider = FutureProvider<SyncController?>((ref) async {
  final session = ref.watch(sessionProvider);
  if (session == null) return null;
  final db = await ref.watch(isarDbProvider.future);
  final controller = SyncController(
    api: ref.watch(enteApiProvider),
    db: db,
    session: session,
  );
  ref.onDispose(controller.dispose);
  await controller.init();
  return controller;
});

/// The thumbnail service for the active session (null until logged in / ready).
final thumbnailServiceProvider = Provider<ThumbnailService?>(
  (ref) => ref.watch(syncControllerProvider).value?.thumbnails,
);

/// The full-resolution service for the active session (null until logged in).
final fullResServiceProvider = Provider<FullResService?>(
  (ref) => ref.watch(syncControllerProvider).value?.fullRes,
);

/// Runs the one-time initial sync (collections + people + first page + memory
/// build) once the controller is ready. The feed watches this for its initial
/// loading state.
final bootstrapProvider = FutureProvider<void>((ref) async {
  final controller = await ref.watch(syncControllerProvider.future);
  if (controller != null) await controller.bootstrap();
});

/// Indirection for "load the next page", returning whether more remain. Going
/// through a provider keeps the feed's pagination logic testable without a live
/// crypto isolate (override this in tests).
final loadMoreProvider = Provider<Future<bool> Function()>((ref) {
  return () async {
    final controller = ref.read(syncControllerProvider).value;
    if (controller == null) return false;
    return controller.loadMore();
  };
});

/// Named people detected in the file with [fileId]. Returns only persons that
/// have a non-empty name; unnamed clusters are omitted.
///
/// StreamProvider so it automatically re-emits when the persons table is
/// written (i.e. after syncPersons() completes) — chips appear without a
/// restart even if persons arrived after the first render.
final personsForFileProvider = StreamProvider
    .family<List<Person>, int>((ref, fileId) async* {
  final db = await ref.watch(isarDbProvider.future);

  Future<List<Person>> query() async {
    final file = await db.isar.enteFiles.get(fileId);
    final personIds = file?.personIds ?? const [];

    bool keep(Person p) => !p.isDeleted && (p.name?.isNotEmpty ?? false);

    if (personIds.isNotEmpty) {
      final result = <Person>[];
      for (final pid in personIds) {
        final p = await db.isar.persons.filter().remoteIDEqualTo(pid).findFirst();
        if (p != null && keep(p)) result.add(p);
      }
      return result;
    }

    // Fallback: scan persons whose fileIds include this file
    final all = await db.isar.persons.filter().isDeletedEqualTo(false).findAll();
    return all.where((p) => keep(p) && p.fileIds.contains(fileId)).toList();
  }

  await for (final _ in db.isar.persons
      .filter()
      .isDeletedEqualTo(false)
      .watchLazy(fireImmediately: true)) {
    yield await query();
  }
});

/// Looks up named persons by their comma-joined remote IDs. Used by people-kind
/// memories to show the same chips on every photo regardless of per-photo face data.
/// StreamProvider so chips auto-update when syncPersons() writes to Isar.
final personsForRemoteIdsProvider = StreamProvider
    .family<List<Person>, String>((ref, idsKey) async* {
  if (idsKey.isEmpty) { yield const []; return; }
  final db = await ref.watch(isarDbProvider.future);
  final ids = idsKey.split(',');

  Future<List<Person>> query() async {
    final result = <Person>[];
    for (final id in ids) {
      final p = await db.isar.persons.filter().remoteIDEqualTo(id).findFirst();
      if (p != null && !p.isDeleted && (p.name?.isNotEmpty ?? false)) {
        result.add(p);
      }
    }
    return result;
  }

  await for (final _ in db.isar.persons
      .filter()
      .isDeletedEqualTo(false)
      .watchLazy(fireImmediately: true)) {
    yield await query();
  }
});

/// The (capture-time ascending) files that make up a memory, looked up by the
/// memory's Isar id.
final memoryFilesProvider = FutureProvider.family<List<EnteFile>, int>((
  ref,
  memoryDbId,
) async {
  final db = await ref.watch(isarDbProvider.future);
  final memory = await db.isar.memoryClusters.get(memoryDbId);
  if (memory == null) return const [];
  final files = await db.isar.enteFiles.getAll(memory.fileIds);
  return files.whereType<EnteFile>().where((f) => !f.isDeleted).toList()
    ..sort((a, b) => a.creationTime.compareTo(b.creationTime));
});

/// Glue around [SyncService] + [MemoryMapper] with a simple "load more" entry
/// point for the feed's infinite scroll.
class SyncController {
  SyncController({
    required EnteApi api,
    required IsarDb db,
    required Session session,
  }) : _api = api,
       _db = db,
       _session = session;

  final EnteApi _api;
  final IsarDb _db;
  final Session _session;

  late final CryptoIsolate _crypto;
  late final SyncService _sync;
  late final MemoryMapper _mapper;
  late final ThumbnailService _thumbnails;
  late final FullResService _fullRes;

  ThumbnailService get thumbnails => _thumbnails;
  FullResService get fullRes => _fullRes;

  bool _loading = false;
  bool _disposed = false;
  bool _backgroundSyncRunning = false;

  Future<void> init() async {
    _api.authToken = _session.token;
    _crypto = await CryptoIsolate.spawn(
      masterKey: _session.masterKey,
      secretKey: _session.secretKey,
      publicKey: _session.publicKey,
      currentUserID: _session.userID,
    );
    _sync = SyncService(api: _api, db: _db, crypto: _crypto);
    _mapper = MemoryMapper(_db);
    _thumbnails = ThumbnailService(api: _api, crypto: _crypto);
    _fullRes = FullResService(api: _api, crypto: _crypto);

    // Re-prime the isolate's collection-key cache from any already-synced
    // collections so thumbnails decrypt immediately after a cold start.
    final known = await _db.isar.enteCollections
        .filter()
        .isDeletedEqualTo(false)
        .findAll();
    if (known.isNotEmpty) {
      await _crypto.primeCollectionKeys([
        for (final c in known)
          if (c.encryptedKey != null)
            {
              'id': c.collectionID,
              'isOwned': c.isOwned,
              'encryptedKey': c.encryptedKey,
              'keyDecryptionNonce': c.keyDecryptionNonce,
            },
      ]);
    }
  }

  /// Initial sync: collections + people + first page, then build memories.
  /// Each phase is logged (visible in `flutter logs`/logcat) with its outcome
  /// so failures are diagnosable on-device.
  Future<void> bootstrap() async {
    debugPrint('[sync] bootstrap: start (endpoint ${_api.baseUrl})');
    await _phase('collections', () async {
      await _sync.syncCollections();
    });
    try {
      await _phase('persons', () async {
        final n = await _sync.syncPersons();
        debugPrint('[sync] persons synced: $n');
      });
    } catch (_) {}
    await _phase('files (recent)', () async {
      final p = await _sync.syncRecentFiles();
      debugPrint('[sync] recent: +${p.insertedFiles} files synced');
    });
    await _phase('files (first page)', () async {
      final p = await _sync.syncNextFilesPage();
      debugPrint('[sync] first page: +${p.insertedFiles} files, hasMore=${p.hasMore}');
    });
    try {
      await _phase('memories', () async {
        final m = await _mapper.rebuild();
        debugPrint('[sync] memories built: $m');
      });
    } catch (_) {}
    debugPrint('[sync] bootstrap: done');
    // Keep syncing the rest of the library in the background so older memories
    // (years ago, seasons, "this month N years ago") appear on their own,
    // without the user having to scroll to page the whole archive in.
    unawaited(backgroundSync());
  }

  /// Pages the remainder of the library after bootstrap, rebuilding memories
  /// every few pages so older flashbacks surface progressively. Yields to any
  /// user-driven [loadMore] via the shared `_loading` guard.
  Future<void> backgroundSync() async {
    if (_backgroundSyncRunning) return;
    _backgroundSyncRunning = true;
    debugPrint('[sync] background sync: start');
    try {
      // Let the first screen + its thumbnails settle before we start paging the
      // archive — otherwise the heavy decrypt/rebuild work competes with the
      // initial render and the app feels sluggish on launch.
      await Future.delayed(const Duration(seconds: 4));

      var pages = 0;
      var insertedSinceRebuild = 0;
      while (!_disposed) {
        if (_loading) {
          await Future.delayed(const Duration(milliseconds: 200));
          continue;
        }
        _loading = true;
        SyncProgress progress;
        try {
          progress = await _sync.syncNextFilesPage();
        } catch (e) {
          debugPrint('[sync] background page failed: $e');
          _loading = false;
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }
        _loading = false;
        if (_disposed) break;

        insertedSinceRebuild += progress.insertedFiles;
        pages++;
        // Rebuild periodically (not every page) so new memories appear as we go
        // without thrashing on the full-library scan each page.
        if (insertedSinceRebuild > 0 && pages % 12 == 0) {
          await _mapper.rebuild();
          insertedSinceRebuild = 0;
        }
        if (!progress.hasMore) break;
        // Pace pages so the UI thread stays responsive while scrolling/viewing.
        await Future.delayed(const Duration(milliseconds: 120));
      }
      if (!_disposed && insertedSinceRebuild > 0) await _mapper.rebuild();
      debugPrint('[sync] background sync: done');
    } finally {
      _backgroundSyncRunning = false;
    }
  }

  Future<void> _phase(String name, Future<void> Function() body) async {
    debugPrint('[sync] $name: start');
    try {
      await body();
      debugPrint('[sync] $name: ok');
    } catch (e, s) {
      debugPrint('[sync] $name: FAILED: $e\n$s');
      rethrow;
    }
  }

  /// Fetch + decrypt + persist one more page, then refresh memories. Called by
  /// the scroll controller as the feed nears its end.
  Future<bool> loadMore() async {
    if (_loading) return false;
    _loading = true;
    try {
      final progress = await _sync.syncNextFilesPage();
      if (progress.insertedFiles > 0) {
        await _mapper.rebuild();
      }
      return progress.hasMore;
    } finally {
      _loading = false;
    }
  }

  void dispose() {
    _disposed = true;
    _crypto.dispose();
  }
}
