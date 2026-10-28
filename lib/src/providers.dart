import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:pointycastle/digests/sha256.dart';
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
import 'memories/memory_catalog.dart';
import 'network/ente_api.dart';
import 'sync/crypto_isolate.dart';
import 'sync/sync_service.dart';

/// The local database — the single source of truth the UI reads from.
final isarDbProvider = FutureProvider<IsarDb>((ref) => IsarDb.open());

/// Preloaded SharedPreferences instance. Overridden in main() before runApp so
/// both EndpointController and SessionNotifier can read it synchronously in
/// their build() methods — eliminating the async race where bootstrap started
/// against the wrong endpoint before the saved URL was loaded.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  );
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
  Future<void>? _signingOut;
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

  Future<void> logout() {
    if (_signingOut != null) return _signingOut!;
    final future = _logout();
    _signingOut = future;
    future.whenComplete(() => _signingOut = null).ignore();
    return future;
  }

  Future<void> _logout() async {
    final controller = ref.read(syncControllerProvider).value;
    controller?.dispose();
    await controller?.drain();
    try {
      await controller?.clearMedia();
    } catch (e) {
      debugPrint('[media] cache cleanup: $e');
    }
    final prefs = ref.read(sharedPreferencesProvider);
    for (final k in [_kToken, _kMasterKey, _kSecretKey, _kPublicKey]) {
      await prefs.remove(k);
    }
    await prefs.remove(_kUserID);
    await prefs.remove(kSelfRemoteIdPref);
    for (final key
        in prefs
            .getKeys()
            .where(
              (k) =>
                  k.startsWith('seen_stories_v2:') ||
                  k.startsWith('files_cursor_'),
            )
            .toList()) {
      await prefs.remove(key);
    }
    try {
      final db = await ref.read(isarDbProvider.future);
      await db.isar.writeTxn(() async {
        await db.isar.enteFiles.clear();
        await db.isar.enteCollections.clear();
        await db.isar.persons.clear();
        await db.isar.memoryClusters.clear();
      });
    } finally {
      state = null;
    }
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
      final result = await ref
          .read(authServiceProvider)
          .login(email: email, password: password);
      switch (result) {
        case LoginSuccess(:final session):
          await ref.read(sessionProvider.notifier).set(session);
          state = const LoginIdle();
        case LoginTwoFactorRequired(
          :final sessionID,
          :final kek,
          :final isPasskey,
        ):
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
      final session = await ref
          .read(authServiceProvider)
          .verifyTotp(sessionID: sessionID, code: code.trim(), kek: kek);
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

final loginControllerProvider = NotifierProvider<LoginController, LoginUiState>(
  LoginController.new,
);

/// The reactive feed of memories. The UI watches this; the background pipeline
/// writes [MemoryCluster]s into Isar and the stream pushes updates here.
/// Includes all memory kinds so accounts without ML (no people memories) still
/// see onThisDay/trip/season memories in the feed.
final memoriesProvider = StreamProvider<List<MemoryCluster>>((ref) async* {
  final db = await ref.watch(isarDbProvider.future);
  yield* db.isar.memoryClusters.where().watch(fireImmediately: true);
});

/// One local calendar-day value; curation refreshes even across a midnight.
final memoryDayProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  final day = DateTime(now.year, now.month, now.day);
  final timer = Timer(
    DateTime(now.year, now.month, now.day + 1).difference(now),
    ref.invalidateSelf,
  );
  ref.onDispose(timer.cancel);
  return day;
});

final storiesMemoriesProvider = Provider<AsyncValue<List<MemoryCluster>>>((
  ref,
) {
  final day = ref.watch(memoryDayProvider);
  return ref
      .watch(memoriesProvider)
      .whenData((memories) => curateMemories(memories, day, limit: 10));
});

class MemoryFeedController extends Notifier<List<MemoryCluster>> {
  List<MemoryCluster> _previous = [];
  @override
  List<MemoryCluster> build() {
    final incoming = ref.watch(memoriesProvider).value;
    final day = ref.watch(memoryDayProvider);
    if (incoming == null) return _previous;
    return _previous = reconcileMemories(
      _previous,
      curateMemories(incoming, day),
    );
  }

  void reorder() {
    _previous = curateMemories(
      ref.read(memoriesProvider).value ?? [],
      ref.read(memoryDayProvider),
    );
    state = _previous;
  }
}

final memoryFeedProvider =
    NotifierProvider<MemoryFeedController, List<MemoryCluster>>(
      MemoryFeedController.new,
    );

class SeenStories extends Notifier<Map<String, String>> {
  late String _key;
  @override
  Map<String, String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final session = ref.watch(sessionProvider);
    _key =
        'seen_stories_v2:${ref.watch(endpointProvider)}:${session?.userID ?? 0}:${session == null ? "" : base64Url.encode(session.publicKey)}';
    try {
      return Map<String, String>.from(
        jsonDecode(prefs.getString(_key) ?? '{}') as Map,
      );
    } catch (_) {
      return {};
    }
  }

  void mark(MemoryCluster memory) {
    final updated = Map<String, String>.from(state)..remove(memory.signature);
    updated[memory.signature] = memory.storyFingerprint;
    while (updated.length > 200) {
      updated.remove(updated.keys.first);
    }
    state = updated;
    unawaited(
      ref.read(sharedPreferencesProvider).setString(_key, jsonEncode(updated)),
    );
  }
}

final seenStoriesProvider = NotifierProvider<SeenStories, Map<String, String>>(
  SeenStories.new,
);

/// Owns the decryption isolate + sync orchestration for the logged-in session.
final syncControllerProvider = FutureProvider<SyncController?>((ref) async {
  final session = ref.watch(sessionProvider);
  if (session == null) return null;
  final db = await ref.watch(isarDbProvider.future);
  final controller = SyncController(
    api: ref.watch(enteApiProvider),
    db: db,
    session: session,
    preferences: ref.read(sharedPreferencesProvider),
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
  ref.watch(memoryDayProvider);
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

/// Shared people index: one stream and one inversion instead of a database
/// scan (and multiple queries per face) for every visible photo.
final namedPeopleProvider = StreamProvider<List<Person>>((ref) async* {
  final db = await ref.watch(isarDbProvider.future);
  yield* db.isar.persons
      .filter()
      .isDeletedEqualTo(false)
      .isHiddenEqualTo(false)
      .watch(fireImmediately: true);
});
final peopleByFileProvider = Provider<AsyncValue<Map<int, List<Person>>>>((
  ref,
) {
  return ref.watch(namedPeopleProvider).whenData((people) {
    final index = <int, List<Person>>{};
    for (final person in people) {
      if (person.name?.trim().isEmpty ?? true) continue;
      for (final id in person.fileIds.toSet()) {
        index.putIfAbsent(id, () => []).add(person);
      }
    }
    return index;
  });
});
final personsForFileProvider = Provider.family<AsyncValue<List<Person>>, int>(
  (ref, fileId) => ref
      .watch(peopleByFileProvider)
      .whenData((people) => people[fileId] ?? []),
);
final personsForRemoteIdsProvider =
    Provider.family<AsyncValue<List<Person>>, String>(
      (ref, ids) => ref.watch(namedPeopleProvider).whenData((people) {
        final selected = ids.split(',').toSet();
        return people
            .where(
              (p) =>
                  selected.contains(p.remoteID) &&
                  (p.name?.trim().isNotEmpty ?? false),
            )
            .toList();
      }),
    );

/// Both memory edits and file edits invalidate the resolved slides. Keep their
/// curated order, and release subscriptions when the card/viewer goes away.
final memoryFilesProvider = StreamProvider.autoDispose
    .family<List<EnteFile>, int>((ref, id) async* {
      final db = await ref.watch(isarDbProvider.future);
      if (!ref.mounted) return;
      final changes = StreamController<void>();
      final memorySub = db.isar.memoryClusters
          .watchObject(id, fireImmediately: true)
          .listen((_) => changes.add(null));
      final filesSub = db.isar.enteFiles.watchLazy().listen(
        (_) => changes.add(null),
      );
      ref.onDispose(() {
        unawaited(memorySub.cancel());
        unawaited(filesSub.cancel());
        unawaited(changes.close());
      });
      await for (final _ in changes.stream) {
        final memory = await db.isar.memoryClusters.get(id);
        if (memory == null) {
          yield [];
          continue;
        }
        final files = await db.isar.enteFiles.getAll(memory.fileIds);
        yield files.whereType<EnteFile>().where((f) => !f.isDeleted).toList();
      }
    });

/// Serializes cursor mutations, coalesces refreshes, and batches off-thread
/// curation while the archive fills. A busy pager never reports exhaustion.
class SyncController {
  SyncController({
    required EnteApi api,
    required IsarDb db,
    required Session session,
    required SharedPreferences preferences,
  }) : _api = api,
       _db = db,
       _session = session,
       _preferences = preferences;
  final EnteApi _api;
  final IsarDb _db;
  final Session _session;
  final SharedPreferences _preferences;
  CryptoIsolate? _crypto;
  late SyncService _sync;
  late MemoryMapper _mapper;
  late ThumbnailService _thumbnails;
  late FullResService _fullRes;
  ThumbnailService get thumbnails => _thumbnails;
  FullResService get fullRes => _fullRes;
  bool _disposed = false;
  bool _initialized = false;
  bool _backgroundSyncRunning = false;
  Future<void> _queue = Future.value();
  Future<void>? _bootstrap;
  Future<bool>? _page;

  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _queue.then((_) {
      if (_disposed) throw StateError('Sync stopped');
      return action();
    });
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> init() async {
    _api.authToken = _session.token;
    final crypto = await CryptoIsolate.spawn(
      masterKey: _session.masterKey,
      secretKey: _session.secretKey,
      publicKey: _session.publicKey,
      currentUserID: _session.userID,
    );
    if (_disposed) {
      crypto.dispose();
      return;
    }
    _crypto = crypto;
    _sync = SyncService(
      api: _api,
      db: _db,
      crypto: crypto,
      preferences: _preferences,
      cursorNamespace:
          '${_api.baseUrl}:${base64Url.encode(_session.publicKey)}',
    );
    _mapper = MemoryMapper(_db);
    final account = SHA256Digest().process(
      Uint8List.fromList(
        utf8.encode('${_api.baseUrl}:${base64Url.encode(_session.publicKey)}'),
      ),
    );
    final namespace = account
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    _thumbnails = ThumbnailService(
      api: _api,
      crypto: crypto,
      cacheNamespace: namespace,
    );
    _fullRes = FullResService(
      api: _api,
      crypto: crypto,
      cacheNamespace: namespace,
    );
    _initialized = true;
    final known = await _db.isar.enteCollections
        .filter()
        .isDeletedEqualTo(false)
        .findAll();
    if (_disposed) return;
    await crypto.primeCollectionKeys([
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

  Future<void> bootstrap() {
    if (_bootstrap != null) return _bootstrap!;
    final future = _serial(() async {
      // Offline/cached libraries get today's memories before any network wait.
      await _mapper.rebuild();
      if (_disposed) return;
      await _sync.syncCollections();
      try {
        await _sync.syncPersons();
      } catch (e) {
        debugPrint('[sync] people unavailable: $e');
      }
      if (_disposed) return;
      await _sync.syncRecentFiles(maxPages: 3);
      await _sync.syncNextFilesPage(prioritizeRecent: false);
      if (!_disposed) await _mapper.rebuild();
    });
    _bootstrap = future;
    future.whenComplete(() {
      _bootstrap = null;
      if (!_disposed) unawaited(backgroundSync());
    }).ignore();
    return future;
  }

  Future<void> backgroundSync() async {
    if (_backgroundSyncRunning || _disposed) return;
    _backgroundSyncRunning = true;
    var changed = false;
    var pages = 0;
    var lastBuild = DateTime.now();
    try {
      await Future<void>.delayed(const Duration(seconds: 1));
      while (!_disposed) {
        final progress = await _serial(_sync.syncNextFilesPage);
        if (_disposed) break;
        changed = changed || progress.changedFiles > 0;
        pages++;
        if (changed &&
            (pages % 6 == 0 ||
                DateTime.now().difference(lastBuild).inSeconds >= 8)) {
          await _mapper.rebuild();
          changed = false;
          lastBuild = DateTime.now();
        }
        if (!progress.hasMore) break;
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      if (!_disposed && changed) await _mapper.rebuild();
    } catch (e) {
      if (!_disposed) debugPrint('[sync] archive paused; pull to retry: $e');
    } finally {
      _backgroundSyncRunning = false;
    }
  }

  Future<bool> loadMore() {
    if (_page != null) return _page!;
    final future = _serial(() async {
      final progress = await _sync.syncNextFilesPage();
      if (!_disposed && progress.changedFiles > 0) await _mapper.rebuild();
      return progress.hasMore;
    });
    _page = future;
    future.whenComplete(() => _page = null).ignore();
    return future;
  }

  Future<void> drain() async {
    await _queue;
    if (_initialized) await _mapper.waitUntilIdle();
  }

  Future<void> clearMedia() async {
    if (!_initialized) return;
    await Future.wait([_thumbnails.clearCache(), _fullRes.clearCache()]);
  }

  void dispose() {
    _disposed = true;
    if (_initialized) {
      _thumbnails.dispose();
      _fullRes.dispose();
    }
    _crypto?.dispose();
  }
}
