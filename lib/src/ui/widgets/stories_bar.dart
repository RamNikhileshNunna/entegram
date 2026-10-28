import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/models/memory_cluster.dart';
import '../../memories/memory_catalog.dart';
import '../../providers.dart';
import 'memory_style.dart';
import 'story_viewer.dart';
import 'thumbnail_image.dart';

class StoriesBar extends ConsumerWidget {
  const StoriesBar({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories =
        ref.watch(storiesMemoriesProvider).value ?? const <MemoryCluster>[];
    if (stories.isEmpty) return const SizedBox.shrink();
    final seen = ref.watch(seenStoriesProvider);
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final height = 206.0 + ((scale - 1) * 42).clamp(0, 80);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Rediscover',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.auto_awesome_outlined,
                size: 18,
                color: Color(0xFFA5D9BC),
              ),
            ],
          ),
        ),
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: stories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final memory = stories[i];
              final watched = seen[memory.signature] == memory.storyFingerprint;
              return SizedBox(
                width: 150,
                child: Semantics(
                  label:
                      '${memory.title}, ${watched ? 'viewed' : 'new'} memory',
                  button: true,
                  child: Material(
                    color: const Color(0xFF25342F),
                    borderRadius: BorderRadius.circular(22),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => openStoryViewer(
                        context,
                        memories: stories,
                        initialMemoryIndex: i,
                        ref: ref,
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _Cover(memory: memory),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black87],
                                stops: [0.25, 1],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Icon(
                              watched
                                  ? Icons.check_circle_outline
                                  : memoryIcon(memory),
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 14,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  memory.title,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${memory.fileIds.length} moments',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  width: watched ? 1 : 2,
                                  color: watched
                                      ? Colors.white24
                                      : memoryColor(memory),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Cover extends ConsumerWidget {
  const _Cover({required this.memory});
  final MemoryCluster memory;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(memoryFilesProvider(memory.id)).value;
    if (files == null || files.isEmpty) {
      return Center(
        child: Icon(memoryIcon(memory), size: 44, color: memoryColor(memory)),
      );
    }
    final cover = files.firstWhere(
      (f) => f.id == memory.coverFileId,
      orElse: () => files.first,
    );
    return ThumbnailImage(
      key: ValueKey(cover.id),
      file: cover,
      decodeWidth: 360,
    );
  }
}
