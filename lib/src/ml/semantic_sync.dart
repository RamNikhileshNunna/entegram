import 'package:dio/dio.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/isar_db.dart';
import '../db/models/ente_file.dart';
import '../db/models/file_ml.dart';
import '../network/ente_api.dart';
import '../sync/crypto_isolate.dart';
import 'semantic_catalog.dart';
import 'semantic_prompts.dart';

enum SemanticSyncState { idle, syncing, ready, unavailable, error }

class MlProgress {
  const MlProgress({this.changed = 0, this.hasMore = false});
  final int changed;
  final bool hasMore;
}

/// Reuses Ente's existing encrypted ML index. Never indexes photos remotely or
/// uploads new embeddings. Persisted retry rows cannot get lost behind a cursor.
class SemanticSyncService {
  SemanticSyncService({
    required this.api,
    required this.db,
    required this.crypto,
    required this.preferences,
    required this.namespace,
    required this.prompts,
    this.onState,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;
  final EnteApi api;
  final IsarDb db;
  final CryptoIsolate crypto;
  final SharedPreferences preferences;
  final String namespace;
  final SemanticPrompts prompts;
  final void Function(SemanticSyncState)? onState;
  final DateTime Function() clock;
  final _cancel = CancelToken();
  bool _initialized = false;
  bool _unavailable = false;
  bool _disposed = false;
  String get _cursorKey => 'ml_status_v1:$namespace';

  void refresh() {
    _initialized = false;
    _unavailable = false;
  }

  void dispose() {
    _disposed = true;
    _cancel.cancel('ML sync stopped');
  }

  Future<void> _initialize() async {
    // Also seeds existing v0.0.2 libraries whose metadata has not changed.
    final files = await db.isar.enteFiles.where().findAll();
    for (var start = 0; start < files.length && !_disposed; start += 1000) {
      final batch = files.skip(start).take(1000).toList();
      await db.isar.writeTxn(() async {
        final old = await db.isar.fileMls.getAll(
          batch.map((f) => f.id).toList(),
        );
        final updates = <FileMl>[];
        for (var i = 0; i < batch.length; i++) {
          final file = batch[i];
          final record = old[i] ?? (FileMl()..id = file.id);
          final needsRevision = record.promptRevision != semanticPromptRevision;
          if (!record.hasFile ||
              record.creationTime != file.creationTime ||
              (needsRevision && !record.pending)) {
            record.hasFile = true;
            record.creationTime = file.creationTime;
            if (needsRevision) {
              record.pending = true;
              record.retryAt = 0;
            }
            updates.add(record);
          }
        }
        await db.isar.fileMls.putAll(updates);
      });
    }
    var since = preferences.getInt(_cursorKey) ?? 0;
    for (var page = 0; page < 1000 && !_disposed; page++) {
      final entries = await api.mlStatusDiff(
        sinceTime: since,
        cancelToken: _cancel,
      );
      if (entries.isEmpty) {
        _initialized = true;
        return;
      }
      var next = since;
      await db.isar.writeTxn(() async {
        for (final entry in entries) {
          final updated = (entry['updatedAt'] as num).toInt();
          if (updated > next) next = updated;
          if (entry['type'] != 'mldata') continue;
          final id = (entry['fileID'] as num).toInt();
          if (id <= 0) continue;
          final record = await db.isar.fileMls.get(id) ?? (FileMl()..id = id);
          if (updated <= record.updatedAt) continue;
          record.updatedAt = updated;
          record.pending = entry['isDeleted'] != true;
          record.retryAt = 0;
          record.issue = null;
          if (!record.pending) record.scores = [];
          await db.isar.fileMls.put(record);
        }
      });
      if (next <= since) throw StateError('ML status cursor did not advance');
      await preferences.setInt(_cursorKey, next);
      since = next;
    }
    if (!_disposed) throw StateError('ML status diff exceeded page limit');
  }

  Future<MlProgress> syncNextPage({int limit = 32}) async {
    if (_disposed || _unavailable) return const MlProgress();
    if (limit < 1 || limit > 64) throw ArgumentError.value(limit, 'limit');
    onState?.call(SemanticSyncState.syncing);
    try {
      if (!_initialized) await _initialize();
      if (_disposed) return const MlProgress();
      final now = clock().microsecondsSinceEpoch;
      final pending = await db.isar.fileMls
          .filter()
          .hasFileEqualTo(true)
          .pendingEqualTo(true)
          .updatedAtGreaterThan(0)
          .retryAtLessThan(now, include: true)
          .sortByCreationTimeDesc()
          .limit(limit)
          .findAll();
      if (pending.isEmpty) {
        onState?.call(SemanticSyncState.ready);
        return const MlProgress();
      }
      final ids = pending.map((r) => r.id).toList();
      final files = (await db.isar.enteFiles.getAll(
        ids,
      )).whereType<EnteFile>().toList();
      final response = files.isEmpty
          ? <String, dynamic>{}
          : await api.fetchMlData(
              files.map((f) => f.id).toList(),
              cancelToken: _cancel,
            );
      if (_disposed) return const MlProgress();
      final data = ((response['data'] as List?) ?? [])
          .cast<Map<String, dynamic>>();
      final results = files.isEmpty || data.isEmpty
          ? []
          : await crypto.classifyMlData(files, data, prompts.vectors);
      if (_disposed) return const MlProgress();
      final byId = {for (final result in results) result.fileId: result};
      final available = files.map((f) => f.id).toSet();
      final errors = ((response['errFileIDs'] as List?) ?? []).toSet();
      final indexing = ((response['pendingIndexFileIDs'] as List?) ?? [])
          .toSet();
      await db.isar.writeTxn(() async {
        for (final record in pending) {
          if (!available.contains(record.id)) {
            await db.isar.fileMls.delete(record.id);
            continue;
          }
          final result = byId[record.id];
          record.promptRevision = semanticPromptRevision;
          record.issue =
              result?.issue ??
              (result != null
                  ? null
                  : errors.contains(record.id)
                  ? 'remote-error'
                  : indexing.contains(record.id)
                  ? 'indexing'
                  : 'not-indexed');
          if (record.issue == null) {
            record.scores = result!.scores;
            record.pending = false;
            record.retryAt = 0;
          } else {
            record.scores = [];
            record.pending = record.issue != 'incompatible';
            record.retryAt =
                now +
                Duration(
                  minutes: record.issue == 'not-indexed' ? 24 * 60 : 5,
                ).inMicroseconds;
          }
          await db.isar.fileMls.put(record);
        }
      });
      final more =
          await db.isar.fileMls
              .filter()
              .hasFileEqualTo(true)
              .pendingEqualTo(true)
              .updatedAtGreaterThan(0)
              .retryAtLessThan(now, include: true)
              .count() >
          0;
      onState?.call(more ? SemanticSyncState.syncing : SemanticSyncState.ready);
      return MlProgress(changed: pending.length, hasMore: more);
    } on DioException catch (e) {
      if (_disposed) return const MlProgress();
      if (e.response?.statusCode == 404 || e.response?.statusCode == 501) {
        _unavailable = true;
        onState?.call(SemanticSyncState.unavailable);
        return const MlProgress();
      }
      onState?.call(SemanticSyncState.error);
      rethrow;
    } catch (_) {
      if (!_disposed) onState?.call(SemanticSyncState.error);
      rethrow;
    }
  }
}
