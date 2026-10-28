import '../db/models/memory_cluster.dart';

/// Presentation taxonomy kept outside the persisted enum, so existing libraries
/// upgrade without a destructive schema migration.
enum MemoryCategory {
  onThisDay,
  flashback,
  people,
  trip,
  recent,
  season,
  year,
  day,
}

extension MemoryPresentation on MemoryCluster {
  MemoryCategory get category {
    final parts = signature.split(':');
    final type = parts.first == 'v2' && parts.length > 1
        ? parts[1]
        : parts.first;
    return switch (type) {
      'anniversary' || 'onthisday' => MemoryCategory.onThisDay,
      'flashback' => MemoryCategory.flashback,
      'people' ||
      'together' ||
      'spotlight' ||
      'lasttime' => MemoryCategory.people,
      'trip' => MemoryCategory.trip,
      'recent' => MemoryCategory.recent,
      'season' => MemoryCategory.season,
      'year' => MemoryCategory.year,
      _ => switch (kind) {
        MemoryKind.people => MemoryCategory.people,
        MemoryKind.onThisDay => MemoryCategory.flashback,
        MemoryKind.trip => MemoryCategory.day,
      },
    };
  }

  String get categoryLabel => switch (category) {
    MemoryCategory.onThisDay => 'On this day',
    MemoryCategory.flashback => 'A little nostalgia',
    MemoryCategory.people => 'People in your life',
    MemoryCategory.trip => 'Days away',
    MemoryCategory.recent => 'Recently',
    MemoryCategory.season => 'Seasonal highlights',
    MemoryCategory.year => 'Your year in photos',
    MemoryCategory.day => 'A day to remember',
  };

  /// A rebuild with unchanged slides must not make a watched story unread.
  String get storyFingerprint => '$signature|$title|${fileIds.join(",")}';
}

int stableMemoryHash(String value) {
  var hash = 2166136261;
  for (final code in value.codeUnits) {
    hash = ((hash ^ code) * 16777619) & 0x7fffffff;
  }
  return hash;
}

/// Daily rotation is deterministic, independent of Isar ids and input ordering.
/// Round-robin categories prevent a large people collection dominating the rail.
List<MemoryCluster> curateMemories(
  Iterable<MemoryCluster> memories,
  DateTime day, {
  int? limit,
}) {
  final seen = <String>{};
  final buckets = <MemoryCategory, List<MemoryCluster>>{};
  for (final memory in memories) {
    if (memory.fileIds.isEmpty || !seen.add(memory.signature)) continue;
    buckets.putIfAbsent(memory.category, () => []).add(memory);
  }
  final seed = '${day.year}-${day.month}-${day.day}';
  for (final bucket in buckets.values) {
    bucket.sort((a, b) {
      if (a.category == MemoryCategory.recent ||
          a.category == MemoryCategory.day) {
        final date = b.endTime.compareTo(a.endTime);
        if (date != 0) return date;
      }
      final rank = stableMemoryHash(
        '$seed:${a.signature}',
      ).compareTo(stableMemoryHash('$seed:${b.signature}'));
      return rank != 0 ? rank : a.signature.compareTo(b.signature);
    });
  }
  const order = [
    MemoryCategory.onThisDay,
    MemoryCategory.recent,
    MemoryCategory.trip,
    MemoryCategory.people,
    MemoryCategory.flashback,
    MemoryCategory.season,
    MemoryCategory.year,
    MemoryCategory.day,
  ];
  final output = <MemoryCluster>[];
  for (var index = 0; ; index++) {
    var added = false;
    for (final category in order) {
      final bucket = buckets[category];
      if (bucket == null || index >= bucket.length) continue;
      output.add(bucket[index]);
      added = true;
      if (limit != null && output.length >= limit) return output;
    }
    if (!added) return output;
  }
}

/// Replace changed content in place, remove deleted memories, append discoveries.
/// Scrolling a feed never changes the order of memories already on screen.
List<MemoryCluster> reconcileMemories(
  List<MemoryCluster> previous,
  List<MemoryCluster> incoming,
) {
  final remaining = {for (final m in incoming) m.signature: m};
  return [
    for (final old in previous)
      if (remaining.containsKey(old.signature))
        remaining.remove(old.signature)!,
    ...remaining.values,
  ];
}

const memoryMonths = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String memoryDate(int micros, {bool includeYear = true}) {
  final date = DateTime.fromMicrosecondsSinceEpoch(micros);
  return '${date.day} ${memoryMonths[date.month - 1]}'
      '${includeYear ? ' ${date.year}' : ''}';
}

String memoryDateRange(MemoryCluster memory) {
  final start = DateTime.fromMicrosecondsSinceEpoch(memory.startTime);
  final end = DateTime.fromMicrosecondsSinceEpoch(memory.endTime);
  if (start.year == end.year && start.month == end.month) {
    if (start.day == end.day) return memoryDate(memory.startTime);
    return '${start.day}–${end.day} ${memoryMonths[end.month - 1]} ${end.year}';
  }
  return '${memoryDate(memory.startTime)} – ${memoryDate(memory.endTime)}';
}
