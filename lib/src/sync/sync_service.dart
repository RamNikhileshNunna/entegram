import 'package:dio/dio.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/isar_db.dart';
import '../db/models/ente_collection.dart';
import '../db/models/ente_file.dart';
import '../db/models/person.dart';
import '../network/ente_api.dart';
import 'crypto_isolate.dart';

class SyncProgress {
  const SyncProgress({
    required this.insertedFiles,
    required this.hasMore,
    this.deletedFiles = 0,
  });
  final int insertedFiles;
  final int deletedFiles;
  final bool hasMore;
  int get changedFiles => insertedFiles + deletedFiles;
}

class _FilesCursor {
  _FilesCursor(this.collectionID, this.sinceTime, {this.persist = false});
  final int collectionID;
  final bool persist;
  int sinceTime;
  bool done = false;
}

/// Backfill progress is independent from recent-priority inserts. Taking MAX
/// of local file timestamps here loses the unsynced archive after a restart.
class SyncService {
  SyncService({
    required EnteApi api,
    required IsarDb db,
    required CryptoIsolate crypto,
    required SharedPreferences preferences,
    required String cursorNamespace,
  }) : _api = api,
       _db = db,
       _crypto = crypto,
       _preferences = preferences,
       _namespace = cursorNamespace;
  final EnteApi _api;
  final IsarDb _db;
  final CryptoIsolate _crypto;
  final SharedPreferences _preferences;
  final String _namespace;
  Isar get _isar => _db.isar;
  final _cursors = <_FilesCursor>[];
  final _recent = <_FilesCursor>[];
  int _round = 0;
  bool _reconciled = false;
  String _cursorKey(int id) => 'files_cursor_v3:$_namespace:$id';

  Future<void> syncCollections() async {
    final since =
        await _isar.enteCollections
            .where()
            .sortByUpdationTimeDesc()
            .updationTimeProperty()
            .findFirst() ??
        0;
    final raw = await _api.collections(sinceTime: since);
    if (raw.isNotEmpty) {
      final collections = await _crypto.decryptCollections(raw);
      await _isar.writeTxn(() async {
        await _isar.enteCollections.putAll(collections);
        final removed = collections
            .where((c) => c.isDeleted)
            .map((c) => c.collectionID)
            .toSet();
        if (removed.isNotEmpty) {
          for (final file in await _isar.enteFiles.where().findAll()) {
            if (file.collectionKeys.isEmpty) {
              if (removed.contains(file.collectionID)) {
                await _isar.enteFiles.delete(file.id);
              }
            } else if (file.collectionKeys.any(
              (k) => removed.contains(k.collectionID),
            )) {
              file.collectionKeys = file.collectionKeys
                  .where((k) => !removed.contains(k.collectionID))
                  .toList();
              await _retainLinkedFile(file);
            }
          }
        }
      });
    }
    final collections = await _isar.enteCollections
        .filter()
        .isDeletedEqualTo(false)
        .sortByUpdationTimeDesc()
        .findAll();
    _cursors.clear();
    _recent.clear();
    _round = 0;
    _reconciled = false;
    final recentStart = DateTime.now()
        .subtract(const Duration(days: 365))
        .microsecondsSinceEpoch;
    for (final c in collections) {
      final since = _preferences.getInt(_cursorKey(c.collectionID)) ?? 0;
      _cursors.add(_FilesCursor(c.collectionID, since, persist: true));
      if (since < recentStart) {
        _recent.add(_FilesCursor(c.collectionID, recentStart));
      }
    }
  }

  Future<SyncProgress> syncNextFilesPage({bool prioritizeRecent = true}) async {
    final cursor =
        (prioritizeRecent ? _pending(_recent) : null) ?? _pending(_cursors);
    if (cursor == null) {
      final removed = await _finishBackfill();
      return SyncProgress(
        insertedFiles: 0,
        deletedFiles: removed,
        hasMore: false,
      );
    }
    return _syncPage(cursor);
  }

  _FilesCursor? _pending(List<_FilesCursor> cursors) {
    if (cursors.isEmpty) return null;
    for (var i = 0; i < cursors.length; i++) {
      final cursor = cursors[(_round + i) % cursors.length];
      if (!cursor.done) {
        _round = (_round + i + 1) % cursors.length;
        return cursor;
      }
    }
    return null;
  }

  Future<SyncProgress> _syncPage(_FilesCursor cursor) async {
    final page = await _api.collectionDiff(
      collectionID: cursor.collectionID,
      sinceTime: cursor.sinceTime,
    );
    var inserted = 0;
    var deleted = 0;
    if (page.items.isNotEmpty) {
      final files = await _crypto.decryptFiles(cursor.collectionID, page.items);
      final next = files.fold<int>(
        cursor.sinceTime,
        (time, f) => f.updationTime > time ? f.updationTime : time,
      );
      if (page.hasMore && next <= cursor.sinceTime) {
        throw StateError('File diff cursor did not advance');
      }
      await _isar.writeTxn(() async {
        // Diff deletion is scoped to this album. Preserve the global file and
        // a usable wrapped key while any other verified album link survives.
        final previous = await _isar.enteFiles.getAll(
          files.map((f) => f.id).toList(),
        );
        final byId = {for (final f in previous.whereType<EnteFile>()) f.id: f};
        final updates = <EnteFile>[];
        final removals = <int>[];
        for (final file in files) {
          final old = byId[file.id];
          final keys = (old?.collectionKeys ?? <FileCollectionKey>[])
              .where((k) => k.collectionID != cursor.collectionID)
              .toList();
          if (file.isDeleted) {
            if (old == null) continue;
            // A legacy row has no verified links yet. Keep it offline until
            // every album has been replayed; final reconciliation removes it
            // if no active album has confirmed it.
            if (old.collectionKeys.isEmpty) continue;
            old.collectionKeys = keys;
            if (keys.isEmpty) {
              removals.add(old.id);
              byId.remove(old.id);
            } else {
              _selectKey(old);
              updates.add(old);
              byId[old.id] = old;
            }
          } else {
            file.collectionKeys = [
              ...keys,
              FileCollectionKey()
                ..collectionID = cursor.collectionID
                ..encryptedKey = file.encryptedKey
                ..keyDecryptionNonce = file.keyDecryptionNonce,
            ];
            updates.add(file);
            byId[file.id] = file;
          }
        }
        await _isar.enteFiles.putAll(updates);
        deleted = await _isar.enteFiles.deleteAll(removals);
        inserted = updates.length;
      });
      // A crash between the transaction and this write safely replays a page.
      if (cursor.persist) {
        await _preferences.setInt(_cursorKey(cursor.collectionID), next);
      }
      cursor.sinceTime = next;
    } else if (page.hasMore) {
      throw StateError('Empty file diff cannot have a following page');
    }
    cursor.done = !page.hasMore;
    deleted += await _finishBackfill();
    return SyncProgress(
      insertedFiles: inserted,
      deletedFiles: deleted,
      hasMore: _cursors.any((c) => !c.done) || _recent.any((c) => !c.done),
    );
  }

  /// All key fields must describe the same surviving album.
  void _selectKey(EnteFile file) {
    final key = file.collectionKeys.firstWhere(
      (k) => k.collectionID == file.collectionID,
      orElse: () => file.collectionKeys.first,
    );
    file.collectionID = key.collectionID;
    file.encryptedKey = key.encryptedKey;
    file.keyDecryptionNonce = key.keyDecryptionNonce;
  }

  Future<void> _retainLinkedFile(EnteFile file) async {
    if (file.collectionKeys.isEmpty) {
      await _isar.enteFiles.delete(file.id);
    } else {
      _selectKey(file);
      await _isar.enteFiles.put(file);
    }
  }

  Future<int> _finishBackfill() async {
    if (_reconciled || _cursors.any((c) => !c.done)) return 0;
    // v3 cursors deliberately replay the archive once after the schema upgrade.
    // No verified links means a legacy row is no longer in any active album.
    final legacy = await _isar.enteFiles
        .filter()
        .collectionKeysLengthEqualTo(0)
        .idProperty()
        .findAll();
    final deleted = await _isar.writeTxn(
      () => _isar.enteFiles.deleteAll(legacy),
    );
    _reconciled = true;
    return deleted;
  }

  Future<SyncProgress> syncRecentFiles({int maxPages = 3}) async {
    var inserted = 0;
    var deleted = 0;
    for (var i = 0; i < maxPages; i++) {
      final cursor = _pending(_recent);
      if (cursor == null) break;
      final progress = await _syncPage(cursor);
      inserted += progress.insertedFiles;
      deleted += progress.deletedFiles;
    }
    return SyncProgress(
      insertedFiles: inserted,
      deletedFiles: deleted,
      hasMore: _recent.any((c) => !c.done) || _cursors.any((c) => !c.done),
    );
  }

  Future<int> syncPersons() async {
    final Map<String, dynamic> key;
    try {
      key = await _api.entityKey('cgroup');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return 0;
      rethrow;
    }
    await _crypto.loadEntityKey(key);
    var since =
        await _isar.persons
            .where()
            .sortByUpdationTimeDesc()
            .updationTimeProperty()
            .findFirst() ??
        0;
    var total = 0;
    while (true) {
      final raw = await _api.entityDiff(type: 'cgroup', sinceTime: since);
      if (raw.isEmpty) return total;
      final persons = await _crypto.decryptPersons(raw);
      await _isar.writeTxn(() async {
        // Upsert by the unique remote identity, retaining local ids.
        await _isar.persons.putAllByRemoteID(
          persons.where((p) => !p.isDeleted).toList(),
        );
        await _isar.persons.deleteAllByRemoteID(
          persons.where((p) => p.isDeleted).map((p) => p.remoteID).toList(),
        );
      });
      total += persons.length;
      final next = raw.fold<int>(since, (time, item) {
        final updated = (item['updationTime'] as num?)?.toInt() ?? 0;
        return updated > time ? updated : time;
      });
      if (raw.length < 500) return total;
      if (next <= since) throw StateError('Person diff cursor did not advance');
      since = next;
    }
  }
}
