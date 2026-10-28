import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/models/ente_file.dart';
import '../../db/models/memory_cluster.dart';
import '../../memories/memory_catalog.dart';
import '../../providers.dart';
import 'fullscreen_viewer.dart';
import 'memory_style.dart';
import 'story_viewer.dart';
import 'thumbnail_image.dart';

class MemoryCard extends ConsumerStatefulWidget {
  const MemoryCard({super.key, required this.memory});
  final MemoryCluster memory;
  @override
  ConsumerState<MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends ConsumerState<MemoryCard> {
  final _page = PageController();
  int _index = 0;
  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memory = widget.memory;
    final resolved = ref.watch(memoryFilesProvider(memory.id));
    final files = resolved.value ?? const <EnteFile>[];
    final index = files.isEmpty ? 0 : _index.clamp(0, files.length - 1);
    if (resolved.hasValue && files.isEmpty) return const SizedBox.shrink();
    return RepaintBoundary(
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
              child: Row(
                children: [
                  Icon(
                    memoryIcon(memory),
                    size: 21,
                    color: memoryColor(memory),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          memory.categoryLabel,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: memoryColor(memory)),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          memory.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Play memory',
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    onPressed: () => openStoryViewer(
                      context,
                      memories: [memory],
                      initialMemoryIndex: 0,
                      ref: ref,
                    ),
                  ),
                ],
              ),
            ),
            AspectRatio(
              aspectRatio: 4 / 3,
              child: resolved.when(
                loading: () => const ColoredBox(
                  color: Color(0xFF25342F),
                  child: Center(
                    child: Icon(Icons.photo_outlined, color: Colors.white24),
                  ),
                ),
                error: (_, _) => Center(
                  child: TextButton.icon(
                    onPressed: () =>
                        ref.invalidate(memoryFilesProvider(memory.id)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reload photos'),
                  ),
                ),
                data: (files) => Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      key: PageStorageKey('photos:${memory.signature}'),
                      controller: _page,
                      itemCount: files.length,
                      onPageChanged: (value) {
                        setState(() => _index = value);
                        ref
                            .read(thumbnailServiceProvider)
                            ?.prefetch(files.skip(value + 1).take(2));
                      },
                      itemBuilder: (_, i) => Semantics(
                        label:
                            '${files[i].fileType == 1 ? 'Video' : 'Photo'} ${i + 1} of ${files.length}',
                        button: true,
                        child: GestureDetector(
                          onTap: () => openFullscreenViewer(
                            context,
                            files: files,
                            initialIndex: i,
                            memory: memory,
                          ),
                          child: ThumbnailImage(
                            key: ValueKey(files[i].id),
                            file: files[i],
                          ),
                        ),
                      ),
                    ),
                    if (files.length > 1)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _Pill('${index + 1} / ${files.length}'),
                      ),
                    if (files.isNotEmpty && files[index].fileType == 1)
                      const IgnorePointer(
                        child: Center(
                          child: Icon(
                            Icons.play_circle_outline,
                            size: 54,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(
                    memoryDateRange(memory),
                    maxLines: 2,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${files.isEmpty ? memory.fileIds.length : files.length} moments',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    ),
  );
}
