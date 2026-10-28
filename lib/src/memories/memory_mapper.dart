import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';

import '../db/isar_db.dart';
import '../db/models/ente_file.dart';
import '../db/models/memory_cluster.dart';
import '../db/models/person.dart';
import 'memory_engine.dart';

/// Retained solely to remove the old, guessed owner identity on sign out.
const String kSelfRemoteIdPref = 'self_remote_id';

/// One snapshot read, off-thread curation, and an atomic diff. Stable ids let
/// Riverpod, carousels and an open story survive progressive archive sync.
class MemoryMapper {
  MemoryMapper(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;
  final IsarDb _db;
  final DateTime Function() _clock;
  Future<int>? _running;
  bool _rerun = false;

  Future<void> waitUntilIdle() async {
    await _running;
  }

  Future<int> rebuild() {
    if (_running != null) {
      _rerun = true;
      return _running!;
    }
    final future = _rebuildUntilCurrent();
    _running = future;
    future.whenComplete(() => _running = null).ignore();
    return future;
  }

  Future<int> _rebuildUntilCurrent() async {
    var count = 0;
    do {
      _rerun = false;
      count = await _rebuild();
    } while (_rerun);
    return count;
  }

  Future<int> _rebuild() async {
    final isar = _db.isar;
    final files = await isar.enteFiles
        .filter()
        .isDeletedEqualTo(false)
        .findAll();
    final people = await isar.persons
        .filter()
        .isDeletedEqualTo(false)
        .findAll();
    final now = _clock();
    final memories = await compute(
      _generateMemories,
      _MemoryInput(files, people, now),
    );
    final previous = await isar.memoryClusters.where().findAll();
    final bySignature = {for (final m in previous) m.signature: m};
    final updated = <MemoryCluster>[];
    for (final memory in memories) {
      final old = bySignature.remove(memory.signature);
      if (old != null) memory.id = old.id;
      if (old == null || !_sameContent(old, memory)) updated.add(memory);
    }
    if (updated.isNotEmpty || bySignature.isNotEmpty) {
      await isar.writeTxn(() async {
        await isar.memoryClusters.deleteAll(
          bySignature.values.map((m) => m.id).toList(),
        );
        await isar.memoryClusters.putAll(updated);
      });
    }
    return memories.length;
  }

  static bool _sameContent(MemoryCluster a, MemoryCluster b) =>
      a.title == b.title &&
      a.kind == b.kind &&
      a.startTime == b.startTime &&
      a.endTime == b.endTime &&
      a.coverFileId == b.coverFileId &&
      listEquals(a.fileIds, b.fileIds) &&
      listEquals(a.personIds, b.personIds);
}

class _MemoryInput {
  const _MemoryInput(this.files, this.people, this.now);
  final List<EnteFile> files;
  final List<Person> people;
  final DateTime now;
}

List<MemoryCluster> _generateMemories(_MemoryInput input) =>
    MemoryEngine(now: input.now).build(input.files, input.people);
