import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/models/ente_file.dart';
import '../../db/models/memory_cluster.dart';
import '../../providers.dart';
import 'fullscreen_viewer.dart';
import 'person_chips.dart';
import 'thumbnail_image.dart';

/// One Instagram-style "Memory" card: a header (avatar + title + date), a
/// swipeable photo rail, action buttons, and a caption.
class MemoryCard extends ConsumerStatefulWidget {
  const MemoryCard({super.key, required this.memory});

  final MemoryCluster memory;

  @override
  ConsumerState<MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends ConsumerState<MemoryCard> {
  final _page = PageController();
  int _index = 0;
  List<EnteFile> _files = [];

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memory = widget.memory;
    final filesAsync = ref.watch(memoryFilesProvider(memory.id));

    // Collapse memories that resolve to no displayable files — e.g. every
    // referenced file was deleted after the memory was built. Without this an
    // empty "0 photos" card with a black box leaks into the feed.
    if (filesAsync.hasValue && filesAsync.value!.isEmpty) {
      return const SizedBox.shrink();
    }

    final count = filesAsync.value?.length ?? memory.fileIds.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(memory: memory),
        AspectRatio(
          aspectRatio: 1,
          child: filesAsync.when(
            loading: () => const ColoredBox(color: Colors.black12),
            error: (e, _) => const ColoredBox(
              color: Colors.black12,
              child: Center(child: Icon(Icons.error_outline)),
            ),
            data: (files) {
              if (files.isEmpty) {
                return const ColoredBox(color: Colors.black12);
              }
              ref.read(thumbnailServiceProvider)?.prefetch(files);
              if (_files != files) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) { if (mounted) setState(() => _files = files); },
                );
              }
              return PageView.builder(
                controller: _page,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: files.length,
                itemBuilder: (_, i) => _FileTile(
                  file: files[i],
                  overrideIds: (memory.kind == MemoryKind.people &&
                          memory.personIds.isNotEmpty)
                      ? memory.personIds.join(',')
                      : null,
                  onTap: () => openFullscreenViewer(
                    context,
                    files: files,
                    initialIndex: i,
                    memory: memory,
                  ),
                ),
              );
            },
          ),
        ),
        // Dots reflect the actual rendered pages (resolved files), so the
        // indicator never disagrees with the PageView.
        if ((filesAsync.value?.length ?? 0) > 1)
          _DotIndicator(
            count: filesAsync.value!.length,
            current: _index.clamp(0, filesAsync.value!.length - 1),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: memory.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: '  $count photos'),
              ],
            ),
          ),
        ),
        // Just the date here — a single line, so it never changes height. The
        // per-photo name chips are overlaid on the photo itself (see
        // _FileTile), so there's no reserved chip space under every post.
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: SizedBox(
            height: 18,
            child: (_files.isNotEmpty && _index < _files.length)
                ? Text(
                    _fileDate(_files[_index]),
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

// ── Feed photo tile ───────────────────────────────────────────────────────────

class _FileTile extends StatelessWidget {
  const _FileTile({required this.file, required this.onTap, this.overrideIds});

  final EnteFile file;
  final VoidCallback onTap;

  /// Comma-joined remote person IDs for the memory (people-kind memories), so
  /// the titled people always appear in the overlay.
  final String? overrideIds;

  @override
  Widget build(BuildContext context) {
    // The feed only ever shows thumbnails — full videos and high-res originals
    // are downloaded lazily in the full-screen / story viewer, never here, so
    // scrolling the home feed doesn't pull heavy media over the network.
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ThumbnailImage(file: file, fit: BoxFit.cover),
          if (file.fileType == 1)
            const Positioned(
              bottom: 8,
              right: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.play_arrow, color: Colors.white, size: 20),
                ),
              ),
            ),
          // Per-photo name chips overlaid on the bottom of the image (over a
          // gradient scrim). Renders nothing when the photo has no named people.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PersonChipsRow(
              fileId: file.id,
              overrideIds: overrideIds,
              overlay: true,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.memory});

  final MemoryCluster memory;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            child: Icon(_iconFor(memory.kind), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memory.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _dateRange(memory.startTime, memory.endTime),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(MemoryKind kind) => switch (kind) {
    MemoryKind.people => Icons.people,
    MemoryKind.trip => Icons.luggage,
    MemoryKind.onThisDay => Icons.today,
  };
}

// ── Dot indicator ─────────────────────────────────────────────────────────────

/// Instagram-style page dots: a fixed-width strip showing up to [_maxVisible]
/// dots. The active dot is bright and slightly larger; when there are more
/// pages than fit, a window slides to keep the active dot centred and the dots
/// at the "more beyond" edges render smaller. Built on a stable layout so it
/// never jumps, with each dot animating its size/colour as you swipe.
class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.count, required this.current});

  final int count;
  final int current;

  static const int _maxVisible = 7;
  static const double _slot = 14; // per-dot horizontal slot (dot + gap)

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox(height: 22);

    final visible = count < _maxVisible ? count : _maxVisible;
    // Window start (whole-slot aligned) that keeps the active dot centred. The
    // strip slides by exactly one slot per swipe in the middle range, so every
    // swipe produces visible motion; at the ends the strip is pinned and the
    // active dot itself moves. Either way, something always moves.
    final start = count <= _maxVisible
        ? 0
        : (current - visible ~/ 2).clamp(0, count - visible);

    return SizedBox(
      height: 22,
      child: Center(
        child: ClipRect(
          child: SizedBox(
            width: visible * _slot,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  top: 0,
                  bottom: 0,
                  left: -start * _slot,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < count; i++)
                        _Dot(
                          active: i == current,
                          // Shrink a boundary dot only when more pages exist
                          // past that edge of the visible window.
                          edge: (i == start && start > 0) ||
                              (i == start + visible - 1 &&
                                  start + visible < count),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active, required this.edge});

  final bool active;
  final bool edge;

  @override
  Widget build(BuildContext context) {
    final double size = active ? 7 : (edge ? 4 : 6);
    final color = active
        ? const Color.fromRGBO(29, 185, 84, 1) // Ente green
        : Colors.white.withValues(alpha: edge ? 0.25 : 0.45);
    return SizedBox(
      width: _DotIndicator._slot,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}

String _fileDate(EnteFile file) {
  if (file.creationTime <= 0) return '';
  final dt = DateTime.fromMicrosecondsSinceEpoch(file.creationTime);
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final day = dt.day.toString().padLeft(2, '0');
  return '$day ${months[dt.month - 1]} ${dt.year}';
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _dateRange(int startUs, int endUs) {
  final start = DateTime.fromMicrosecondsSinceEpoch(startUs);
  final end = DateTime.fromMicrosecondsSinceEpoch(endUs);
  String label(DateTime d) => '${_months[d.month - 1]} ${d.year}';
  final a = label(start);
  final b = label(end);
  return a == b ? a : '$a – $b';
}
