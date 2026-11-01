import 'package:flutter/material.dart';
import '../../db/models/ente_file.dart';
import 'thumbnail_image.dart';

/// A bounded 2×2 preview. Each tile opens its actual position in the gallery.
class MemoryCollage extends StatelessWidget {
  const MemoryCollage({
    super.key,
    required this.files,
    required this.onOpen,
    this.coverFileId,
  });
  final List<EnteFile> files;
  final int? coverFileId;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final indices = <int>[
      if (files.any((f) => f.id == coverFileId))
        files.indexWhere((f) => f.id == coverFileId),
      for (var i = 0; i < files.length; i++)
        if (files[i].id != coverFileId) i,
    ].take(4).toList();
    if (indices.isEmpty) return const SizedBox.shrink();
    Widget tile(int position) {
      final index = indices[position];
      final file = files[index];
      return Semantics(
        label:
            'Open ${file.fileType == 1 ? 'video' : 'photo'} ${index + 1} of ${files.length}',
        button: true,
        child: InkWell(
          onTap: () => onOpen(index),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ThumbnailImage(key: ValueKey('collage:${file.id}'), file: file),
              if (file.fileType == 1)
                const Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              if (position == indices.length - 1 &&
                  files.length > indices.length)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black45,
                    child: Center(
                      child: Text(
                        '+${files.length - indices.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (indices.length == 1) return tile(0);
    if (indices.length < 4) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: tile(0)),
          const SizedBox(width: 3),
          Expanded(
            child: Column(
              children: [
                for (var i = 1; i < indices.length; i++) ...[
                  if (i > 1) const SizedBox(height: 3),
                  Expanded(child: tile(i)),
                ],
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: tile(0)),
              const SizedBox(width: 3),
              Expanded(child: tile(1)),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Expanded(
          child: Row(
            children: [
              Expanded(child: tile(2)),
              const SizedBox(width: 3),
              Expanded(child: tile(3)),
            ],
          ),
        ),
      ],
    );
  }
}
