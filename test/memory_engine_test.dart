import 'dart:math';
import 'package:entegram/src/memories/memory_catalog.dart';
import 'package:entegram/src/memories/memory_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fixtures.dart';

void main() {
  final now = DateTime(2026, 10, 28, 15);
  test('anniversaries use the exact calendar date across the full archive', () {
    final result = MemoryEngine(now: now).build([
      photo(1, DateTime(1995, 10, 28, 10)),
      photo(2, DateTime(2025, 10, 28, 23)),
      photo(3, DateTime(2025, 10, 27)),
      photo(4, DateTime(2025, 10, 29)),
    ], []);
    final anniversaries = result.where(
      (m) => m.category == MemoryCategory.onThisDay,
    );
    expect(
      anniversaries.map((m) => m.title),
      containsAll(['31 years ago today', 'A year ago today']),
    );
    expect(anniversaries.expand((m) => m.fileIds).toSet(), {1, 2});
  });
  test('leap day never rolls an anniversary into March', () {
    final result = MemoryEngine(now: DateTime(2025, 3, 1)).build([
      photo(1, DateTime(2024, 2, 29)),
      photo(2, DateTime(2024, 3, 1)),
    ], []);
    expect(
      result
          .where((m) => m.category == MemoryCategory.onThisDay)
          .single
          .fileIds,
      [2],
    );
  });
  test('last week uses a complete calendar week across a year boundary', () {
    final result = MemoryEngine(now: DateTime(2026, 1, 5, 12)).build([
      photo(1, DateTime(2025, 12, 29)),
      photo(2, DateTime(2025, 12, 31)),
      photo(3, DateTime(2026, 1, 4, 23)),
      photo(4, DateTime(2026, 1, 5, 1)),
    ], []);
    expect(result.singleWhere((m) => m.title == 'Last week').fileIds, [
      1,
      2,
      3,
    ]);
  });
  test(
    'duplicates, future/deleted/invalid files and screenshots do not become highlights',
    () {
      final deleted = photo(4, DateTime(2024, 1, 1))..isDeleted = true;
      final invalid = photo(5, DateTime(2024, 1, 1))..creationTime = 0;
      final result = MemoryEngine(now: now).build([
        photo(1, DateTime(2020, 1, 1), hash: 'same'),
        photo(2, DateTime(2020, 1, 2), hash: 'same'),
        photo(3, DateTime(2030, 1, 1)),
        deleted,
        invalid,
        photo(6, DateTime(2020, 1, 1), title: 'Screenshot_20200101.png'),
      ], []);
      expect(result.expand((m) => m.fileIds).toSet(), {1});
    },
  );
  test(
    'hidden people are excluded and the most photographed person is never guessed to be you',
    () {
      final files = List.generate(
        8,
        (i) => photo(i + 1, DateTime(2025, 10, 28, i)),
      );
      final result = MemoryEngine(now: now).build(files, [
        person('a', 'Alex', [1, 2, 3, 4]),
        person('b', 'Hidden', [5, 6, 7, 8], hidden: true),
      ]);
      expect(
        result.expand((m) => m.fileIds).toSet(),
        isNot(contains(anyOf(5, 6, 7, 8))),
      );
      expect(result.any((m) => m.title.contains('You and')), isFalse);
    },
  );
  test('a shared date is not evidence two people appear together', () {
    final files = List.generate(
      8,
      (i) => photo(i + 1, DateTime(2020, 6, 4, i)),
    );
    final result = MemoryEngine(now: now).build(files, [
      person('a', 'Alex', [1, 2, 3, 4]),
      person('b', 'Sam', [5, 6, 7, 8]),
    ]);
    expect(result.any((m) => m.signature.contains(':together:')), isFalse);
  });
  test('every slide of a together memory contains both people', () {
    final files = List.generate(
      9,
      (i) => photo(i + 1, DateTime(2020, 6, i + 1)),
    );
    final result = MemoryEngine(now: now).build(files, [
      person('a', 'Alex', [1, 2, 3, 4, 5, 6]),
      person('b', 'Sam', [4, 5, 6, 7, 8, 9]),
    ]);
    final together = result.singleWhere(
      (m) => m.signature.contains(':together:'),
    );
    expect(together.fileIds.toSet(), {4, 5, 6});
    expect(together.personIds, ['a', 'b']);
  });
  test(
    'home evidence counts distinct dates; returning home separates trips',
    () {
      final files = [
        for (var i = 0; i < 8; i++)
          photo(i + 1, DateTime(2020, 1, 1 + i * 6), lat: 12, lon: 77),
        for (var i = 0; i < 4; i++)
          photo(20 + i, DateTime(2020, 3, 1, 8 + i * 2), lat: 20, lon: 80),
        photo(30, DateTime(2020, 3, 2), lat: 12, lon: 77),
        for (var i = 0; i < 4; i++)
          photo(40 + i, DateTime(2020, 3, 2, 8 + i * 2), lat: 20, lon: 80),
      ];
      final trips = MemoryEngine(now: now)
          .build(files, [])
          .where((m) => m.category == MemoryCategory.trip)
          .toList();
      expect(trips, hasLength(2));
      expect(trips.expand((m) => m.fileIds), isNot(contains(30)));
    },
  );
  test('a short vacation burst cannot be inferred as home', () {
    final files = List.generate(
      30,
      (i) => photo(i + 1, DateTime(2020, 6, 1, i), lat: 12, lon: 77),
    );
    final result = MemoryEngine(now: now).build(files, []);
    expect(result.any((m) => m.category == MemoryCategory.trip), isFalse);
  });
  test('seasons respect hemispheres and span December to February', () {
    for (final lat in [30.0, -30.0]) {
      final files = [
        for (var i = 0; i < 4; i++)
          photo(i + 1, DateTime(2024, 12, 10 + i), lat: lat, lon: 77),
        for (var i = 0; i < 4; i++)
          photo(i + 5, DateTime(2025, 1, 10 + i), lat: lat, lon: 77),
      ];
      final result = MemoryEngine(now: DateTime(2025, 4, 1)).build(files, []);
      final season = result.singleWhere(
        (m) => m.category == MemoryCategory.season,
      );
      expect(season.title, lat > 0 ? 'Winter 2025' : 'Summer 2025');
      expect(season.fileIds, hasLength(8));
    }
  });
  test('an unfinished season is not presented as a completed recap', () {
    final files = List.generate(
      8,
      (i) => photo(i + 1, DateTime(2025, 9, i + 1), lat: 30, lon: 70),
    );
    final result = MemoryEngine(now: DateTime(2025, 10, 28)).build(files, []);
    expect(result.any((m) => m.category == MemoryCategory.season), isFalse);
  });
  test('year highlights cover the year rather than one large burst', () {
    final files = [
      for (var month = 1; month <= 12; month++)
        for (var i = 0; i < 4; i++)
          photo(month * 100 + i, DateTime(2020, month, 5 + i)),
      for (var i = 0; i < 100; i++)
        photo(2000 + i, DateTime(2020, 7, 20, 0, i)),
    ];
    final result = MemoryEngine(now: DateTime(2026, 2, 2)).build(files, []);
    final year = result.singleWhere((m) => m.category == MemoryCategory.year);
    final byId = {for (final f in files) f.id: f};
    expect(year.fileIds, hasLength(24));
    expect(
      year.fileIds
          .map(
            (id) => DateTime.fromMicrosecondsSinceEpoch(
              byId[id]!.creationTime,
            ).month,
          )
          .toSet(),
      hasLength(12),
    );
    expect(year.fileIds, contains(year.coverFileId));
  });
  test(
    'selection is bounded, content-diverse, and deterministic under reordered inputs',
    () {
      final files = List.generate(
        600,
        (i) => photo(i + 1, DateTime(2010 + i ~/ 36, i % 12 + 1, i % 27 + 1)),
      );
      final a = MemoryEngine(now: now, maxMemories: 20).build(files, []);
      final b = MemoryEngine(
        now: now,
        maxMemories: 20,
      ).build(List.of(files)..shuffle(Random(4)), []);
      expect(a.length, lessThanOrEqualTo(20));
      expect(a.map((m) => m.signature), b.map((m) => m.signature));
      expect(a.map((m) => m.fileIds), b.map((m) => m.fileIds));
      expect(a.map((m) => m.coverFileId).toSet(), hasLength(a.length));
      final uses = <int, int>{};
      for (final m in a) {
        expect(m.fileIds.length, lessThanOrEqualTo(24));
        for (final id in m.fileIds) {
          uses[id] = (uses[id] ?? 0) + 1;
        }
      }
      expect(uses.values.every((count) => count <= 2), isTrue);
    },
  );
  test(
    'feed reconciliation updates content in place and never repeats signatures',
    () {
      final first = memory(1),
          second = memory(2),
          changed = memory(1, files: [15]),
          third = memory(3);
      final result = reconcileMemories(
        [first, second],
        [third, second, changed],
      );
      expect(result.map((m) => m.id), [1, 2, 3]);
      expect(result.first.fileIds, [15]);
      expect(reconcileMemories(result, [third]).map((m) => m.id), [3]);
    },
  );
  test(
    'calendar weeks retain midnight boundaries through daylight-saving changes',
    () {
      final result = MemoryEngine(now: DateTime(2026, 11, 2, 12)).build([
        photo(1, DateTime(2026, 10, 26, 0, 10)),
        photo(2, DateTime(2026, 10, 27, 12)),
        photo(3, DateTime(2026, 11, 1, 23, 30)),
        photo(4, DateTime(2026, 11, 2, 0, 10)),
      ], []);
      expect(result.singleWhere((m) => m.title == 'Last week').fileIds, [
        1,
        2,
        3,
      ]);
    },
  );
  test(
    'seen fingerprints survive rebuilds but change when story content changes',
    () {
      final a = memory(1);
      final b = memory(1)
        ..id = 999
        ..generatedAt = 123;
      expect(a.storyFingerprint, b.storyFingerprint);
      b.fileIds = [10, 12];
      expect(a.storyFingerprint, isNot(b.storyFingerprint));
      b.fileIds = a.fileIds;
      b.title = 'Another year ago';
      expect(a.storyFingerprint, isNot(b.storyFingerprint));
    },
  );
}
