import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';

import '../db/isar_db.dart';
import '../db/models/ente_collection.dart';
import '../db/models/ente_file.dart';
import '../db/models/person.dart';
import '../network/ente_api.dart';
import 'crypto_isolate.dart';

/// Result of advancing the file pagination by one page.
class SyncProgress {
  const SyncProgress({required this.insertedFiles, required this.hasMore});
  final int insertedFiles;
  final bool hasMore;
}

/// Per-collection pagination cursor.
class _FilesCursor {
  _FilesCursor(this.collectionID, this.sinceTime);
  final int collectionID;
  int sinceTime;
  bool done = false;
}

/// Orchestrates the data pipeline:
///   network fetch (async IO, here) → libsodium decrypt (in [CryptoIsolate])
///   → Isar write (here, single writer).
///
/// The UI never calls this for data — it watches Isar. The UI only *triggers*
/// [syncNextFilesPage] when the feed nears its end.
class SyncService {
  SyncService({
    required EnteApi api,
    required IsarDb db,
    required CryptoIsolate crypto,
  }) : _api = api,
       _db = db,
       _crypto = crypto;

  final EnteApi _api;
  final IsarDb _db;
  final CryptoIsolate _crypto;

  Isar get _isar => _db.isar;

  final List<_FilesCursor> _cursors = [];
  int _cursorIndex = 0;

  // One-shot cursors used during bootstrap to fetch the last year of files
  // before the historical crawl catches up — ensures recent memories appear
  // in the feed immediately rather than after many loadMore() calls.
  final List<_FilesCursor> _recentCursors = [];

  /// Pulls the collections diff, decrypts it, persists it, and (re)builds the
  /// ordered set of file-pagination cursors — most-recently-updated first, so
  /// the feed surfaces fresh memories near the top.
  Future<void> syncCollections() async {
    final sinceTime = await _maxUpdationTime();
    final raw = await _api.collections(sinceTime: sinceTime);
    if (raw.isNotEmpty) {
      final collections = await _crypto.decryptCollections(raw);
      await _isar.writeTxn(() => _isar.enteCollections.putAll(collections));
    }

    final owned = await _isar.enteCollections
        .filter()
        .isDeletedEqualTo(false)
        .sortByUpdationTimeDesc()
        .findAll();

    _cursors.clear();
    _cursorIndex = 0;
    for (final c in owned) {
      final since = await _isar.enteFiles
          .where()
          .collectionIDEqualTo(c.collectionID)
          .sortByUpdationTimeDesc()
          .updationTimeProperty()
          .findFirst() ?? 0;
      _cursors.add(_FilesCursor(c.collectionID, since));
    }

    // Bootstrap priority: populate one-shot cursors starting from one year ago
    // so recent photos appear in the feed immediately instead of after many
    // historical pages.
    _recentCursors.clear();
    final oneYearAgo = DateTime.now()
        .subtract(const Duration(days: 365))
        .microsecondsSinceEpoch;
    for (final c in _cursors) {
      if (c.sinceTime < oneYearAgo) {
        _recentCursors.add(_FilesCursor(c.collectionID, oneYearAgo));
      }
    }
  }

  /// Advances pagination by exactly one diff page across the collection
  /// cursors. This is the call the scroll controller triggers near the bottom.
  Future<SyncProgress> syncNextFilesPage() async {
    final cursor = _nextPendingCursor();
    if (cursor == null) {
      return const SyncProgress(insertedFiles: 0, hasMore: false);
    }

    final page = await _api.collectionDiff(
      collectionID: cursor.collectionID,
      sinceTime: cursor.sinceTime,
    );

    var inserted = 0;
    if (page.items.isNotEmpty) {
      final files = await _crypto.decryptFiles(
        cursor.collectionID,
        page.items,
      );
      await _isar.writeTxn(() async {
        final live = files.where((f) => !f.isDeleted).toList();
        final dead = files.where((f) => f.isDeleted).map((f) => f.id).toList();
        await _isar.enteFiles.putAll(live);
        if (dead.isNotEmpty) await _isar.enteFiles.deleteAll(dead);
      });
      inserted = files.where((f) => !f.isDeleted).length;
      cursor.sinceTime = files
          .map((f) => f.updationTime)
          .fold<int>(cursor.sinceTime, (a, b) => b > a ? b : a);
    }

    if (!page.hasMore) cursor.done = true;
    return SyncProgress(insertedFiles: inserted, hasMore: _hasPendingWork());
  }

  /// Syncs `person` entities (the ML face groups) so memories can be titled.
  ///
  /// People are optional: an account that has never run face recognition has no
  /// person entity key, so `GET /user-entity/key?type=person` returns 404. That
  /// (and any other person-sync failure) is non-fatal — we just skip people and
  /// let the feed fall back to time-based memories.
  Future<int> syncPersons() async {
    final Map<String, dynamic> keyJson;
    try {
      keyJson = await _api.entityKey('cgroup');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        debugPrint('[sync] no person entity key (account has no ML data)');
        return 0;
      }
      rethrow;
    }
    await _crypto.loadEntityKey(keyJson);

    final sinceTime = await _isar.persons
        .where()
        .sortByUpdationTimeDesc()
        .updationTimeProperty()
        .findFirst();

    final raw = await _api.entityDiff(type: 'cgroup', sinceTime: sinceTime ?? 0);
    if (raw.isEmpty) return 0;

    final persons = await _crypto.decryptPersons(raw);
    await _isar.writeTxn(() async {
      final live = persons.where((p) => !p.isDeleted).toList();
      await _isar.persons.putAll(live);
      final deadIds = persons
          .where((p) => p.isDeleted)
          .map((p) => p.remoteID)
          .toList();
      if (deadIds.isNotEmpty) {
        await _isar.persons.deleteAllByRemoteID(deadIds);
      }
    });
    return persons.length;
  }

  /// Exhausts all recent-window cursors, fetching every page of files from the
  /// last year across all collections. Called once during bootstrap so 2025+
  /// photos land in Isar before the historical crawl reaches them.
  Future<SyncProgress> syncRecentFiles() async {
    var inserted = 0;
    for (final cursor in _recentCursors) {
      while (!cursor.done) {
        final page = await _api.collectionDiff(
          collectionID: cursor.collectionID,
          sinceTime: cursor.sinceTime,
        );
        if (page.items.isNotEmpty) {
          final files = await _crypto.decryptFiles(
            cursor.collectionID,
            page.items,
          );
          await _isar.writeTxn(() async {
            final live = files.where((f) => !f.isDeleted).toList();
            final dead =
                files.where((f) => f.isDeleted).map((f) => f.id).toList();
            await _isar.enteFiles.putAll(live);
            if (dead.isNotEmpty) await _isar.enteFiles.deleteAll(dead);
          });
          inserted += files.where((f) => !f.isDeleted).length;
          cursor.sinceTime = files
              .map((f) => f.updationTime)
              .fold<int>(cursor.sinceTime, (a, b) => b > a ? b : a);
        }
        if (!page.hasMore) cursor.done = true;
      }
    }
    return SyncProgress(insertedFiles: inserted, hasMore: _hasPendingWork());
  }

  _FilesCursor? _nextPendingCursor() {
    for (var i = 0; i < _cursors.length; i++) {
      final idx = (_cursorIndex + i) % _cursors.length;
      if (!_cursors[idx].done) {
        _cursorIndex = idx;
        return _cursors[idx];
      }
    }
    return null;
  }

  bool _hasPendingWork() => _cursors.any((c) => !c.done);

  Future<int> _maxUpdationTime() async {
    final t = await _isar.enteCollections
        .where()
        .sortByUpdationTimeDesc()
        .updationTimeProperty()
        .findFirst();
    return t ?? 0;
  }
}
