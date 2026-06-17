import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/models/person.dart';
import '../../providers.dart';

/// Face-name chips for a photo. Shows **everyone detected in the image**
/// (per-photo face data, including the account owner), unioned with the
/// memory's titled people in [overrideIds] (so e.g. "You and Alex" still names
/// them even when a frame's face data is sparse). Rendered as a multi-line Wrap
/// so all names are visible; the parent reserves a fixed height so the card
/// doesn't resize while swiping.
class PersonChipsRow extends ConsumerWidget {
  const PersonChipsRow({
    super.key,
    required this.fileId,
    this.overrideIds,
    this.overlay = false,
  });

  final int fileId;

  /// Comma-joined remote person IDs (from memory.personIds.join(',')).
  final String? overrideIds;

  /// When true, the chips are laid over a bottom gradient scrim — used to float
  /// them on the bottom of a photo in the feed (no layout space reserved).
  final bool overlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoPeople =
        ref.watch(personsForFileProvider(fileId)).asData?.value ??
            const <Person>[];
    final overridePeople = (overrideIds != null && overrideIds!.isNotEmpty)
        ? ref.watch(personsForRemoteIdsProvider(overrideIds!)).asData?.value ??
            const <Person>[]
        : const <Person>[];

    // Titled people first, then everyone else in the photo (incl. the owner);
    // de-duped by id, unnamed removed.
    final seen = <String>{};
    final people = <Person>[];
    for (final p in [...overridePeople, ...photoPeople]) {
      if (p.name == null || p.name!.isEmpty) continue;
      if (seen.add(p.remoteID)) people.add(p);
    }

    if (people.isEmpty) return const SizedBox.shrink();
    final wrap = Wrap(
      spacing: 6,
      runSpacing: 4,
      children:
          people.take(6).map<Widget>((p) => _Chip(name: p.name!)).toList(),
    );
    if (!overlay) return wrap;
    // Float over the bottom of a photo with a gradient scrim for readability.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 26, 10, 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: wrap,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.face_outlined, color: Colors.white60, size: 13),
          const SizedBox(width: 4),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
