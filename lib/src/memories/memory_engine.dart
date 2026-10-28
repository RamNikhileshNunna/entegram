import 'dart:math';

import '../db/models/ente_file.dart';
import '../db/models/memory_cluster.dart';
import '../db/models/person.dart';
import 'memory_catalog.dart';

/// Metadata-only curation. No network, database, device-owner guesses, or
/// claims of visual/semantic understanding. Safe to run in a worker isolate.
class MemoryEngine {
  MemoryEngine({required this.now, this.maxMemories = 80, this.maxSlides = 24});

  final DateTime now;
  final int maxMemories;
  final int maxSlides;
  final _candidates = <_Candidate>[];

  List<MemoryCluster> build(List<EnteFile> source, List<Person> persons) {
    _candidates.clear();
    if (maxMemories <= 0 || maxSlides <= 0) return [];
    final hiddenPeople = persons.where((p) => p.isHidden).toList();
    final hiddenIds = hiddenPeople.map((p) => p.remoteID).toSet();
    final hiddenFiles = hiddenPeople.expand((p) => p.fileIds).toSet();
    final hiddenHashes = source
        .where(
          (f) =>
              hiddenFiles.contains(f.id) || f.personIds.any(hiddenIds.contains),
        )
        .map((f) => f.hash?.trim())
        .whereType<String>()
        .where((h) => h.isNotEmpty)
        .toSet();
    final sorted =
        source
            .where(
              (f) =>
                  !hiddenFiles.contains(f.id) &&
                  !hiddenHashes.contains(f.hash?.trim()) &&
                  !f.personIds.any(hiddenIds.contains) &&
                  !f.isDeleted &&
                  f.creationTime > 0 &&
                  f.creationTime <= now.microsecondsSinceEpoch &&
                  f.fileType >= 0 &&
                  f.fileType <= 2 &&
                  !_isUtility(f),
            )
            .toList()
          ..sort(_chronological);
    final canonical = <String, EnteFile>{};
    final aliases = <int, int>{};
    for (final file in sorted) {
      final hash = file.hash?.trim();
      final key = hash != null && hash.isNotEmpty
          ? 'hash:$hash'
          : 'id:${file.id}';
      final existing = canonical[key];
      if (existing == null) {
        canonical[key] = file;
        aliases[file.id] = file.id;
      } else {
        aliases[file.id] = existing.id;
      }
    }
    final files = canonical.values.toList();
    if (files.isEmpty) return [];
    final byId = {for (final f in files) f.id: f};
    final byYear = <int, List<EnteFile>>{};
    final byMonth = <String, List<EnteFile>>{};
    final byDay = <String, List<EnteFile>>{};
    for (final file in files) {
      final date = _date(file);
      byYear.putIfAbsent(date.year, () => []).add(file);
      byMonth.putIfAbsent('${date.year}-${date.month}', () => []).add(file);
      byDay.putIfAbsent(_dayKey(date), () => []).add(file);
    }

    // Exact calendar dates, across the whole archive, including leap years.
    for (final entry in byYear.entries) {
      if (entry.key >= now.year) continue;
      final years = now.year - entry.key;
      final anniversary = entry.value.where((f) {
        final d = _date(f);
        return d.month == now.month && d.day == now.day;
      }).toList();
      _add(
        'anniversary:${entry.key}:${now.month}-${now.day}',
        years == 1 ? 'A year ago today' : '$years years ago today',
        MemoryKind.onThisDay,
        anniversary,
        1000,
        minFiles: 1,
      );
      _add(
        'flashback:${entry.key}:${now.month}',
        years == 1 ? 'This month, last year' : 'This month, $years years ago',
        MemoryKind.onThisDay,
        byMonth['${entry.key}-${now.month}'] ?? [],
        780,
      );
      if (entry.value.length >= 12) {
        _add(
          'year:${entry.key}',
          'Highlights of ${entry.key}',
          MemoryKind.trip,
          entry.value,
          380,
          minFiles: 6,
        );
      }
    }

    final today = DateTime(now.year, now.month, now.day);
    final weekStart = DateTime(
      today.year,
      today.month,
      today.day - today.weekday + 1,
    );
    _add(
      'recent:week:${_dayKey(weekStart)}',
      'Last week',
      MemoryKind.onThisDay,
      _between(
        files,
        DateTime(weekStart.year, weekStart.month, weekStart.day - 7),
        weekStart,
      ),
      650,
    );
    final monthStart = DateTime(now.year, now.month);
    _add(
      'recent:month:${now.year}-${now.month}',
      'Last month',
      MemoryKind.onThisDay,
      _between(files, DateTime(now.year, now.month - 1), monthStart),
      560,
    );

    _people(persons, byId, aliases);
    _trips(files);
    _seasons(files);
    for (final entry in byDay.entries.toList().reversed.take(40)) {
      final day = _date(entry.value.first);
      if (!day.isBefore(today)) continue;
      _add(
        'day:${entry.key}',
        '${memoryMonths[day.month - 1]} ${day.day}, ${day.year}',
        MemoryKind.trip,
        entry.value,
        200,
        minFiles: 1,
      );
    }
    // Small/new libraries still have an honest starting point, never a fake trip.
    if (_candidates.isEmpty) {
      _add(
        'recent:latest',
        'Your latest moments',
        MemoryKind.onThisDay,
        files.length > maxSlides
            ? files.sublist(files.length - maxSlides)
            : files,
        100,
        minFiles: 1,
      );
    }
    return _select();
  }

  void _people(
    List<Person> persons,
    Map<int, EnteFile> byId,
    Map<int, int> aliases,
  ) {
    final named =
        persons
            .where(
              (p) =>
                  !p.isHidden &&
                  !p.isDeleted &&
                  (p.name?.trim().isNotEmpty ?? false),
            )
            .toList()
          ..sort((a, b) => a.remoteID.compareTo(b.remoteID));
    final memberships = <int, List<Person>>{};
    final tagged = <String, Set<int>>{};
    for (final file in byId.values) {
      for (final id in file.personIds) {
        tagged.putIfAbsent(id, () => {}).add(file.id);
      }
    }
    for (final person in named) {
      final ids = <int>{
        for (final id in person.fileIds)
          if (aliases[id] != null) aliases[id]!,
        ...?tagged[person.remoteID],
      };
      final photos = ids.map((id) => byId[id]).whereType<EnteFile>().toList()
        ..sort(_chronological);
      if (photos.length >= 4) {
        _add(
          'people:${person.remoteID}',
          'Moments with ${person.name!.trim()}',
          MemoryKind.people,
          photos,
          630,
          people: [person.remoteID],
          minFiles: 4,
        );
      }
      for (final id in ids) {
        memberships.putIfAbsent(id, () => []).add(person);
      }
    }
    // Invert memberships: pairs cost O(faces per photo²), not O(all people²).
    final pairs = <String, List<EnteFile>>{};
    final pairPeople = <String, List<Person>>{};
    for (final entry in memberships.entries) {
      final people = entry.value;
      // Large crowd photos are poor evidence for a personal relationship.
      if (people.length > 8) continue;
      for (var i = 0; i < people.length; i++) {
        for (var j = i + 1; j < people.length; j++) {
          final pair = [people[i], people[j]];
          final key = '${pair[0].remoteID}:${pair[1].remoteID}';
          pairs.putIfAbsent(key, () => []).add(byId[entry.key]!);
          pairPeople[key] = pair;
        }
      }
    }
    for (final entry in pairs.entries) {
      if (entry.value.length < 3) continue;
      final people = pairPeople[entry.key]!;
      // Every slide must actually contain BOTH titled people.
      _add(
        'together:${entry.key}',
        '${people[0].name} & ${people[1].name}',
        MemoryKind.people,
        entry.value..sort(_chronological),
        720,
        people: people.map((p) => p.remoteID).toList(),
        minFiles: 3,
      );
    }
  }

  void _trips(List<EnteFile> files) {
    final located = files.where(_hasLocation).toList();
    final cells = <String, List<EnteFile>>{};
    for (final file in located) {
      final key =
          '${(file.latitude! * 4).floor()}:${(file.longitude! * 4).floor()}';
      cells.putIfAbsent(key, () => []).add(file);
    }
    if (cells.isEmpty) return;
    int days(List<EnteFile> group) =>
        group.map((f) => _dayKey(_date(f))).toSet().length;
    final ranked = cells.entries.toList()
      ..sort((a, b) {
        final byDays = days(b.value).compareTo(days(a.value));
        return byDays != 0 ? byDays : a.key.compareTo(b.key);
      });
    final home = ranked.first.value;
    // A vacation burst must not become "home". Require evidence over a month.
    if (days(home) < 5 ||
        _date(home.last).difference(_date(home.first)).inDays < 30) {
      return;
    }
    final lat =
        home.map((f) => f.latitude!).reduce((a, b) => a + b) / home.length;
    final lon =
        home.map((f) => f.longitude!).reduce((a, b) => a + b) / home.length;
    var trip = <EnteFile>[];
    void flush() {
      if (trip.length >= 4) {
        final start = _date(trip.first);
        final end = _date(trip.last);
        if (end.difference(start).inHours >= 4) {
          _add(
            'trip:${_dayKey(start)}:${trip.first.id}',
            'A getaway in ${memoryMonths[start.month - 1]}',
            MemoryKind.trip,
            trip,
            740,
            minFiles: 4,
          );
        }
      }
      trip = [];
    }

    for (final file in located) {
      if (_distance(lat, lon, file.latitude!, file.longitude!) < 60) {
        flush(); // An observed return home separates visits even on the same day.
        continue;
      }
      if (trip.isNotEmpty &&
          (_date(file).difference(_date(trip.last)).inHours > 48 ||
              _date(file).difference(_date(trip.first)).inDays >= 21)) {
        flush();
      }
      trip.add(file);
    }
    flush();
  }

  void _seasons(List<EnteFile> files) {
    final groups = <String, List<EnteFile>>{};
    final ends = <String, DateTime>{};
    for (final file in files) {
      final d = _date(file);
      final southern = _hasLocation(file) && file.latitude! < 0;
      final quarter = d.month == 12 ? 0 : d.month ~/ 3;
      final season = (quarter + (southern ? 2 : 0)) % 4;
      // Unknown hemisphere: use neutral quarters rather than invent a season.
      final label = !_hasLocation(file)
          ? 'Q${(d.month - 1) ~/ 3 + 1} ${d.year}'
          : '${['Winter', 'Spring', 'Summer', 'Autumn'][season]} ${d.month == 12 ? d.year + 1 : d.year}';
      groups.putIfAbsent(label, () => []).add(file);
      ends[label] = !_hasLocation(file)
          ? DateTime(d.year, ((d.month - 1) ~/ 3 + 1) * 3 + 1)
          : DateTime(
              d.year + (d.month == 12 ? 1 : 0),
              quarter == 0 ? 3 : quarter * 3 + 3,
            );
    }
    for (final entry in groups.entries) {
      if (entry.value.length < 8) continue;
      // Only completed seasons/quarters, never a misleading future recap.
      if (now.isBefore(ends[entry.key]!)) continue;
      _add(
        'season:${entry.key}',
        entry.key,
        MemoryKind.trip,
        entry.value,
        350,
        minFiles: 6,
      );
    }
  }

  void _add(
    String key,
    String title,
    MemoryKind kind,
    List<EnteFile> files,
    int priority, {
    int minFiles = 3,
    List<String> people = const [],
  }) {
    if (files.length < minFiles) return;
    _candidates.add(
      _Candidate(key, title, kind, List.of(files), priority, minFiles, people),
    );
  }

  List<MemoryCluster> _select() {
    final day = _dayKey(now);
    _candidates.sort((a, b) {
      final rank = b.priority.compareTo(a.priority);
      if (rank != 0) return rank;
      return stableMemoryHash(
        '$day:${a.key}',
      ).compareTo(stableMemoryHash('$day:${b.key}'));
    });
    final usage = <int, int>{};
    final covers = <int>{};
    final categoryCounts = <String, int>{};
    final output = <MemoryCluster>[];
    for (final candidate in _candidates) {
      if (output.length >= maxMemories) break;
      final type = candidate.key.split(':').first;
      final cap = switch (type) {
        'day' => 20,
        'year' => 6,
        'season' => 8,
        _ => 12,
      };
      if ((categoryCounts[type] ?? 0) >= cap) continue;
      final available = candidate.files
          .where((f) => (usage[f.id] ?? 0) < 2)
          .toList();
      if (available.length < candidate.minFiles) continue;
      final sampled = _sample(available);
      final novel = sampled.where((f) => !usage.containsKey(f.id)).length;
      if (output.isNotEmpty && novel < (sampled.length * 0.5).ceil()) continue;
      final coverOptions = sampled
          .where((f) => !covers.contains(f.id))
          .toList();
      if (coverOptions.isEmpty) continue;
      coverOptions.sort((a, b) {
        final quality = _quality(b).compareTo(_quality(a));
        return quality != 0 ? quality : a.id.compareTo(b.id);
      });
      sampled.sort(_chronological);
      final memory = MemoryCluster()
        ..signature = 'v2:${candidate.key}'
        ..title = candidate.title
        ..kind = candidate.kind
        ..startTime = candidate.files.first.creationTime
        ..endTime = candidate.files.last.creationTime
        ..personIds = candidate.people
        ..fileIds = sampled.map((f) => f.id).toList()
        ..coverFileId = coverOptions.first.id
        ..generatedAt = now.microsecondsSinceEpoch;
      output.add(memory);
      covers.add(memory.coverFileId!);
      categoryCounts[type] = (categoryCounts[type] ?? 0) + 1;
      for (final file in sampled) {
        usage[file.id] = (usage[file.id] ?? 0) + 1;
      }
    }
    return output;
  }

  /// Round-robin days before taking extra frames; long bursts cannot crowd out
  /// an entire year. Within a day choose quality first, then temporal novelty.
  List<EnteFile> _sample(List<EnteFile> files) {
    if (files.length <= maxSlides) return List.of(files);
    final days = <String, List<EnteFile>>{};
    for (final file in files) {
      days.putIfAbsent(_dayKey(_date(file)), () => []).add(file);
    }
    final buckets = days.values.toList();
    for (final bucket in buckets) {
      bucket.sort((a, b) {
        final score = _quality(b).compareTo(_quality(a));
        return score != 0 ? score : a.id.compareTo(b.id);
      });
    }
    final chosen = <EnteFile>[];
    if (buckets.length > maxSlides) {
      for (var i = 0; i < maxSlides; i++) {
        chosen.add(
          buckets[(i *
                      (buckets.length - 1) /
                      (maxSlides - 1).clamp(1, maxSlides))
                  .round()]
              .first,
        );
      }
      return chosen;
    }
    for (var round = 0; chosen.length < maxSlides; round++) {
      for (final bucket in buckets) {
        if (round < bucket.length) chosen.add(bucket[round]);
        if (chosen.length == maxSlides) break;
      }
    }
    return chosen;
  }

  static bool _isUtility(EnteFile f) => RegExp(
    r'(^|[/_\s-])(screenshot|screen[ _-]?shot|screen[ _-]?record|receipt)([_\s.\d-]|$)',
    caseSensitive: false,
  ).hasMatch(f.title ?? '');
  static DateTime _date(EnteFile f) =>
      DateTime.fromMicrosecondsSinceEpoch(f.creationTime);
  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static int _chronological(EnteFile a, EnteFile b) {
    final date = a.creationTime.compareTo(b.creationTime);
    return date != 0 ? date : a.id.compareTo(b.id);
  }

  static List<EnteFile> _between(
    List<EnteFile> files,
    DateTime start,
    DateTime end,
  ) => files
      .where(
        (f) =>
            f.creationTime >= start.microsecondsSinceEpoch &&
            f.creationTime < end.microsecondsSinceEpoch,
      )
      .toList();
  static double _quality(EnteFile f) {
    final w = f.width ?? 0;
    final h = f.height ?? 0;
    final pixels = w > 0 && h > 0 ? log(1 + w.toDouble() * h) : 0.0;
    return pixels + (f.fileType != 1 ? 2 : 0) + (w > h && h > 0 ? 1 : 0);
  }

  static bool _hasLocation(EnteFile f) =>
      f.latitude != null &&
      f.longitude != null &&
      f.latitude!.isFinite &&
      f.longitude!.isFinite &&
      f.latitude!.abs() <= 90 &&
      f.longitude!.abs() <= 180 &&
      !(f.latitude == 0 && f.longitude == 0);
  static double _distance(double lat1, double lon1, double lat2, double lon2) {
    double rad(double d) => d * pi / 180;
    final a =
        (pow(sin(rad(lat2 - lat1) / 2), 2) +
                cos(rad(lat1)) *
                    cos(rad(lat2)) *
                    pow(sin(rad(lon2 - lon1) / 2), 2))
            .clamp(0.0, 1.0);
    return 6371 * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}

class _Candidate {
  const _Candidate(
    this.key,
    this.title,
    this.kind,
    this.files,
    this.priority,
    this.minFiles,
    this.people,
  );
  final String key;
  final String title;
  final MemoryKind kind;
  final List<EnteFile> files;
  final int priority;
  final int minFiles;
  final List<String> people;
}
