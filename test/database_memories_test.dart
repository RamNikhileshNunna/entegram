import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:convert';
import 'package:entegram/src/db/isar_db.dart';
import 'package:entegram/src/db/models/ente_collection.dart';
import 'package:entegram/src/db/models/ente_file.dart';
import 'package:entegram/src/db/models/memory_cluster.dart';
import 'package:entegram/src/memories/memory_mapper.dart';
import 'package:entegram/src/network/ente_api.dart';
import 'package:entegram/src/providers.dart';
import 'package:entegram/src/sync/crypto_isolate.dart';
import 'package:entegram/src/sync/sync_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fixtures.dart';

class _Api extends EnteApi {
  final requests = <int>[];
  bool stalled = false;
  bool deleting = false;
  final old = DateTime(2020, 1, 1).microsecondsSinceEpoch;
  final recent = DateTime.now().microsecondsSinceEpoch;
  @override
  Future<List<Map<String, dynamic>>> collections({int sinceTime = 0}) async =>
      [];
  @override
  Future<EnteDiffPage> collectionDiff({
    required int collectionID,
    required int sinceTime,
  }) async {
    requests.add(sinceTime);
    if (stalled) {
      return EnteDiffPage(
        items: [
          {'id': 1, 'time': sinceTime},
        ],
        hasMore: true,
      );
    }
    if (deleting) {
      return EnteDiffPage(
        items: [
          {'id': 1, 'time': recent + 1, 'deleted': true},
        ],
        hasMore: false,
      );
    }
    if (sinceTime < old) {
      return EnteDiffPage(
        items: [
          {'id': 1, 'time': old},
        ],
        hasMore: true,
      );
    }
    return EnteDiffPage(
      items: [
        {'id': 2, 'time': recent},
      ],
      hasMore: false,
    );
  }
}

class _MembershipApi extends _Api {
  final links = <int, Map<String, dynamic>>{};
  final collectionChanges = <Map<String, dynamic>>[];
  void link(int collection, int time, {bool deleted = false}) {
    links[collection] = {'id': 1, 'time': time, 'deleted': deleted};
  }

  @override
  Future<List<Map<String, dynamic>>> collections({int sinceTime = 0}) async =>
      collectionChanges;
  @override
  Future<EnteDiffPage> collectionDiff({
    required int collectionID,
    required int sinceTime,
  }) async {
    requests.add(sinceTime);
    final entry = links[collectionID];
    return EnteDiffPage(
      items: [if (entry != null && (entry['time'] as int) > sinceTime) entry],
      hasMore: false,
    );
  }
}

class _Crypto implements CryptoIsolate {
  @override
  Future<List<EnteCollection>> decryptCollections(
    List<Map<String, dynamic>> raw,
  ) async => [
    for (final item in raw)
      EnteCollection()
        ..id = item['id'] as int
        ..collectionID = item['id'] as int
        ..ownerID = 1
        ..updationTime = item['time'] as int
        ..isDeleted = item['deleted'] == true,
  ];
  @override
  Future<List<EnteFile>> decryptFiles(
    int collectionID,
    List<Map<String, dynamic>> raw,
  ) async => [
    for (final item in raw)
      photo(item['id'] as int, DateTime(2020, 1, 1))
        ..collectionID = collectionID
        ..encryptedKey = 'wrapped-key-$collectionID'
        ..keyDecryptionNonce = 'nonce-$collectionID'
        ..updationTime = item['time'] as int
        ..isDeleted = item['deleted'] == true,
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Controller implements SyncController {
  final stopped = Completer<void>();
  bool disposed = false;
  @override
  void dispose() {
    disposed = true;
  }

  @override
  Future<void> drain() => stopped.future;
  @override
  Future<void> clearMedia() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late IsarDb db;
  late SharedPreferences preferences;
  setUpAll(() async {
    if (!Platform.isLinux) return;
    final configFile = File('.dart_tool/package_config.json').absolute;
    final config = jsonDecode(await configFile.readAsString()) as Map;
    final package = (config['packages'] as List).cast<Map>().singleWhere(
      (p) => p['name'] == 'isar_community_flutter_libs',
    );
    final root = configFile.uri.resolve('${package['rootUri']}/');
    await Isar.initializeIsarCore(
      libraries: {Abi.current(): root.resolve('linux/libisar.so').toFilePath()},
    );
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('entegram-memories-');
    db = await IsarDb.open(directoryOverride: directory.path);
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    await db.isar.writeTxn(
      () => db.isar.enteCollections.put(
        EnteCollection()
          ..id = 1
          ..collectionID = 1
          ..ownerID = 1
          ..updationTime = 0,
      ),
    );
  });
  tearDown(() async {
    await db.isar.close(deleteFromDisk: true);
    await directory.delete(recursive: true);
  });

  test(
    'mapper upserts stable ids and skips unchanged writes',
    () async {
      final mapper = MemoryMapper(db, clock: () => DateTime(2026, 10, 28, 15));
      await db.isar.writeTxn(
        () => db.isar.enteFiles.putAll([
          photo(1, DateTime(2025, 10, 28, 10)),
          photo(2, DateTime(2025, 10, 28, 11)),
        ]),
      );
      await mapper.rebuild();
      final original = await db.isar.memoryClusters.where().findAll();
      await mapper.rebuild();
      final unchanged = await db.isar.memoryClusters.where().findAll();
      expect(unchanged.map((m) => m.id), original.map((m) => m.id));
      expect(
        unchanged.map((m) => m.generatedAt),
        original.map((m) => m.generatedAt),
      );
      await db.isar.writeTxn(
        () => db.isar.enteFiles.put(photo(3, DateTime(2025, 10, 28, 12))),
      );
      await mapper.rebuild();
      final updated = await db.isar.memoryClusters.where().findAll();
      final anniversary = updated.singleWhere(
        (m) => m.signature.contains(':anniversary:'),
      );
      expect(
        anniversary.id,
        original.singleWhere((m) => m.signature == anniversary.signature).id,
      );
      expect(anniversary.fileIds, [1, 2, 3]);
    },
    skip: !Platform.isLinux,
  );

  test(
    'sign out drains writers before clearing data and exposing login',
    () async {
      for (final key in [
        'session_token',
        'session_master_key',
        'session_secret_key',
        'session_public_key',
      ]) {
        await preferences.setString(key, 'AQID');
      }
      await preferences.setString('seen_stories_v2:test', '{}');
      await db.isar.writeTxn(
        () => db.isar.enteFiles.put(photo(10, DateTime(2020))),
      );
      final controller = _Controller();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          isarDbProvider.overrideWith((_) async => db),
          syncControllerProvider.overrideWith((_) async => controller),
        ],
      );
      await container.read(syncControllerProvider.future);
      final notifier = container.read(sessionProvider.notifier);
      final first = notifier.logout();
      expect(identical(first, notifier.logout()), isTrue);
      expect(controller.disposed, isTrue);
      expect(container.read(sessionProvider), isNotNull);
      controller.stopped.complete();
      await first;
      expect(container.read(sessionProvider), isNull);
      expect(await db.isar.enteFiles.count(), 0);
      expect(preferences.getString('session_master_key'), isNull);
      expect(preferences.getString('seen_stories_v2:test'), isNull);
      container.dispose();
    },
    skip: !Platform.isLinux,
  );

  test(
    'resolved memory files react to deletions without waiting for a rebuild',
    () async {
      await db.isar.writeTxn(() async {
        await db.isar.enteFiles.putAll([
          photo(10, DateTime(2020)),
          photo(11, DateTime(2020)),
        ]);
        await db.isar.memoryClusters.put(memory(1));
      });
      final container = ProviderContainer(
        overrides: [isarDbProvider.overrideWith((_) async => db)],
      );
      final deleted = Completer<void>();
      final subscription = container.listen(memoryFilesProvider(1), (_, next) {
        if (next.value?.length == 1 && !deleted.isCompleted) deleted.complete();
      });
      expect((await container.read(memoryFilesProvider(1).future)).length, 2);
      await db.isar.writeTxn(() => db.isar.enteFiles.delete(10));
      await deleted.future.timeout(const Duration(seconds: 3));
      expect(container.read(memoryFilesProvider(1)).value!.single.id, 11);
      subscription.close();
      container.dispose();
    },
    skip: !Platform.isLinux,
  );

  SyncService service(_Api api, {String account = 'test'}) => SyncService(
    api: api,
    db: db,
    crypto: _Crypto(),
    preferences: preferences,
    cursorNamespace: account,
  );
  test(
    'priority inserts cannot skip unsynced history after a restart',
    () async {
      final api = _Api();
      final first = service(api);
      await first.syncCollections();
      await first.syncRecentFiles(maxPages: 1);
      expect((await db.isar.enteFiles.where().findAll()).map((f) => f.id), [2]);
      final restarted = service(api);
      await restarted.syncCollections();
      await restarted.syncNextFilesPage(prioritizeRecent: false);
      expect(api.requests.last, 0);
      expect(await db.isar.enteFiles.get(1), isNotNull);
      final resumed = service(api);
      await resumed.syncCollections();
      await resumed.syncNextFilesPage(prioritizeRecent: false);
      expect(api.requests.last, api.old);
      final other = service(api, account: 'other');
      await other.syncCollections();
      await other.syncNextFilesPage(prioritizeRecent: false);
      expect(api.requests.last, 0);
    },
    skip: !Platform.isLinux,
  );
  Future<void> addSecondAlbum() async {
    await db.isar.writeTxn(
      () => db.isar.enteCollections.put(
        EnteCollection()
          ..id = 2
          ..collectionID = 2
          ..ownerID = 1
          ..updationTime = 0,
      ),
    );
  }

  Future<void> drain(SyncService sync) async {
    for (var i = 0; i < 10; i++) {
      final page = await sync.syncNextFilesPage(prioritizeRecent: false);
      if (!page.hasMore) return;
    }
    fail('Unexpectedly unbounded test archive');
  }

  test(
    'album unlink retains the shared file and switches its decryption key across restart',
    () async {
      await addSecondAlbum();
      final api = _MembershipApi()
        ..link(1, 10)
        ..link(2, 11);
      var sync = service(api);
      await sync.syncCollections();
      await drain(sync);
      final file = (await db.isar.enteFiles.get(1))!;
      expect(file.collectionKeys.map((k) => k.collectionID).toSet(), {1, 2});
      final removed = file.collectionID;
      final survivor = removed == 1 ? 2 : 1;
      api.link(removed, 20, deleted: true);
      sync = service(api);
      await sync.syncCollections();
      await drain(sync);
      await db.isar.close();
      db = await IsarDb.open(directoryOverride: directory.path);
      final retained = (await db.isar.enteFiles.get(1))!;
      expect(retained.collectionKeys.single.collectionID, survivor);
      expect(retained.collectionID, survivor);
      expect(retained.encryptedKey, 'wrapped-key-$survivor');
      expect(retained.keyDecryptionNonce, 'nonce-$survivor');
      api.link(survivor, 30, deleted: true);
      sync = service(api);
      await sync.syncCollections();
      await drain(sync);
      expect(await db.isar.enteFiles.get(1), isNull);
    },
    skip: !Platform.isLinux,
  );

  test(
    'deleted album removes only its links and preserves other album keys',
    () async {
      await addSecondAlbum();
      final api = _MembershipApi()
        ..link(1, 10)
        ..link(2, 11);
      var sync = service(api);
      await sync.syncCollections();
      await drain(sync);
      final primary = (await db.isar.enteFiles.get(1))!.collectionID;
      api.collectionChanges.add({'id': primary, 'time': 40, 'deleted': true});
      sync = service(api);
      await sync.syncCollections();
      final retained = (await db.isar.enteFiles.get(1))!;
      expect(retained.collectionKeys.length, 1);
      expect(retained.collectionID, isNot(primary));
      expect(retained.encryptedKey, 'wrapped-key-${retained.collectionID}');
    },
    skip: !Platform.isLinux,
  );

  test(
    'v2 cursor upgrade replays album links before pruning obsolete legacy files',
    () async {
      await preferences.setInt('files_cursor_v2:test:1', 999);
      await db.isar.writeTxn(
        () => db.isar.enteFiles.putAll([
          photo(1, DateTime(2020)),
          photo(99, DateTime(2020)),
        ]),
      );
      final api = _MembershipApi()..link(1, 10);
      final sync = service(api);
      await sync.syncCollections();
      expect(await db.isar.enteFiles.count(), 2);
      await drain(sync);
      expect(api.requests.first, 0);
      expect(
        (await db.isar.enteFiles.get(1))!.collectionKeys.single.collectionID,
        1,
      );
      expect(await db.isar.enteFiles.get(99), isNull);
    },
    skip: !Platform.isLinux,
  );

  test(
    'deletion-only pages count as changes and stalled pages cannot loop',
    () async {
      final api = _Api();
      final sync = service(api);
      await sync.syncCollections();
      await sync.syncNextFilesPage(prioritizeRecent: false);
      api.deleting = true;
      final progress = await sync.syncNextFilesPage(prioritizeRecent: false);
      expect(progress.deletedFiles, 1);
      expect(progress.changedFiles, 1);
      expect(await db.isar.enteFiles.get(1), isNull);
      api.deleting = false;
      api.stalled = true;
      await sync.syncCollections();
      await expectLater(
        sync.syncNextFilesPage(prioritizeRecent: false),
        throwsStateError,
      );
    },
    skip: !Platform.isLinux,
  );
}
