import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/models/ente_file.dart';
import '../../db/models/memory_cluster.dart';
import '../../providers.dart';
import 'story_viewer.dart';
import 'thumbnail_image.dart';

class StoriesBar extends ConsumerStatefulWidget {
  const StoriesBar({super.key});

  @override
  ConsumerState<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends ConsumerState<StoriesBar> {
  List<MemoryCluster> _shuffled = const [];
  Set<int> _seenIds = const {};

  static const int _maxStories = 10;

  void _onData(List<MemoryCluster> memories) {
    final ids = memories.map((m) => m.id).toSet();
    if (ids.length == _seenIds.length && ids.containsAll(_seenIds)) return;
    _seenIds = ids;
    final mixed = List<MemoryCluster>.from(memories)..shuffle();
    setState(() => _shuffled = mixed.take(_maxStories).toList());
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(storiesMemoriesProvider).whenData(_onData);

    if (_shuffled.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _shuffled.length,
        itemBuilder: (context, i) => _StoryBubble(
          memory: _shuffled[i],
          onTap: () => openStoryViewer(
            context,
            memories: _shuffled,
            initialMemoryIndex: i,
            ref: ref,
          ),
        ),
      ),
    );
  }
}

class _StoryBubble extends ConsumerWidget {
  const _StoryBubble({required this.memory, required this.onTap});

  final MemoryCluster memory;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CoverCircle(key: ValueKey(memory.id), memory: memory),
            const SizedBox(height: 4),
            SizedBox(
              width: 64,
              child: Text(
                memory.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverCircle extends ConsumerStatefulWidget {
  const _CoverCircle({super.key, required this.memory});

  final MemoryCluster memory;

  @override
  ConsumerState<_CoverCircle> createState() => _CoverCircleState();
}

class _CoverCircleState extends ConsumerState<_CoverCircle> {
  EnteFile? _coverFile;

  @override
  void initState() {
    super.initState();
    _loadCover();
  }

  Future<void> _loadCover() async {
    final files = await ref.read(
      memoryFilesProvider(widget.memory.id).future,
    );
    if (!mounted || files.isEmpty) return;
    final coverId = widget.memory.coverFileId;
    final cover = coverId != null
        ? files.firstWhere((f) => f.id == coverId, orElse: () => files.first)
        : files.first;
    setState(() => _coverFile = cover);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color(0xFF00C853), // bright green
            Color(0xFF1DB954), // Ente/app green
            Color(0xFF00897B), // teal
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(2.5),
      child: ClipOval(
        child: _coverFile != null
            // 64 px circle → decode small so the stories rail stays light.
            ? ThumbnailImage(file: _coverFile!, fit: BoxFit.cover, decodeWidth: 160)
            : const ColoredBox(color: Colors.black26),
      ),
    );
  }
}
