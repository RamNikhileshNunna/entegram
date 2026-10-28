import 'package:flutter/foundation.dart';

import '../db/models/ente_file.dart';
import '../db/models/memory_cluster.dart';

/// Navigation independent of rendering and timers. Every asynchronous load is
/// generation-checked; late results can never replace a newer story.
class StoryPlayback extends ChangeNotifier {
  StoryPlayback({
    required List<MemoryCluster> memories,
    required this.loadFiles,
    this.onCompleted,
    int initialMemoryIndex = 0,
  }) : memories = List.unmodifiable(memories),
       memoryIndex = memories.isEmpty
           ? 0
           : initialMemoryIndex.clamp(0, memories.length - 1);
  final List<MemoryCluster> memories;
  final Future<List<EnteFile>> Function(MemoryCluster memory) loadFiles;
  final void Function(MemoryCluster memory)? onCompleted;
  int memoryIndex;
  int photoIndex = 0;
  List<EnteFile> files = const [];
  bool loading = false;
  bool finished = false;
  Object? error;
  int _generation = 0;
  bool _disposed = false;
  final _visited = <String, Set<int>>{};
  MemoryCluster? get memory => memories.isEmpty ? null : memories[memoryIndex];
  EnteFile? get file => files.isEmpty ? null : files[photoIndex];
  String get slideKey => '${memory?.signature}:${file?.id}';

  Future<void> start() => _load(memoryIndex);
  Future<void> retry() => _load(memoryIndex);
  Future<void> next() async {
    if (loading || finished) return;
    if (photoIndex + 1 < files.length) {
      photoIndex++;
      _visit();
      notifyListeners();
    } else {
      final current = memory;
      if (current != null &&
          files.isNotEmpty &&
          (_visited[current.signature]?.length ?? 0) >= files.length) {
        onCompleted?.call(current);
      }
      await _load(memoryIndex + 1);
    }
  }

  Future<void> previous() async {
    if (finished) return;
    if (!loading && photoIndex > 0) {
      photoIndex--;
      _visit();
      notifyListeners();
    } else if (memoryIndex > 0) {
      await _load(memoryIndex - 1, backwards: true);
    }
  }

  Future<void> nextMemory() => _load(memoryIndex + 1);
  Future<void> previousMemory() =>
      memoryIndex > 0 ? _load(memoryIndex - 1) : Future.value();

  void _visit() {
    if (file != null && memory != null) {
      _visited.putIfAbsent(memory!.signature, () => {}).add(file!.id);
    }
  }

  Future<void> _load(int target, {bool backwards = false}) async {
    if (_disposed) return;
    final generation = ++_generation;
    loading = true;
    error = null;
    files = const [];
    photoIndex = 0;
    // Empty/deleted memories are skipped iteratively, not with recursive loads.
    while (target >= 0 && target < memories.length) {
      memoryIndex = target;
      notifyListeners();
      try {
        final result = await loadFiles(memories[target]);
        if (_disposed || generation != _generation) return;
        final seen = <int>{};
        final live = result
            .where((f) => !f.isDeleted && seen.add(f.id))
            .toList();
        if (live.isEmpty) {
          target += backwards ? -1 : 1;
          continue;
        }
        files = List.unmodifiable(live);
        photoIndex = backwards ? files.length - 1 : 0;
        loading = false;
        _visit();
        notifyListeners();
        return;
      } catch (e) {
        if (_disposed || generation != _generation) return;
        error = e;
        loading = false;
        notifyListeners();
        return;
      }
    }
    if (_disposed || generation != _generation) return;
    loading = false;
    finished = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
