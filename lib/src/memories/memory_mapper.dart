import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/isar_db.dart';
import '../db/models/ente_file.dart';
import '../db/models/memory_cluster.dart';
import '../db/models/person.dart';

const String kSelfRemoteIdPref = 'self_remote_id';

/// Turns decrypted [Person] + [EnteFile] data into [MemoryCluster] read-models.
///
/// Memory types:
/// 1. **People sessions**   — date-contiguous sessions, titled naturally.
/// 2. **Person spotlight**  — all photos of a named person ("Alex").
/// 3. **Last time with X**  — dedicated memory when no photos < 1 year old.
/// 4. **On This Day**       — combined multi-year + per-year flashbacks.
/// 5. **Year / Season**     — "Photos from 2022", "Summer 2023".
class MemoryMapper {
  MemoryMapper(this._db);

  final IsarDb _db;
  Isar get _isar => _db.isar;

  // Two-day gap → distinct days/events; 3-day gap was merging unrelated encounters.
  static const int _sessionGap = 2 * 24 * 60 * 60 * 1000 * 1000;

  // ── People-memory confidence thresholds ──────────────────────────────────
  // Ente's face clusters carry false positives (a stray photo wrongly tagged
  // with a person). The user strongly prefers *no* memory over one titled with
  // someone who isn't in it, so naming is precision-first: "X and Y" memories
  // are built exclusively from photos where BOTH are tagged together — never
  // from a session where they merely both happen to appear — and must clear a
  // high co-occurrence bar before they can headline a card.

  /// Minimum photos for a solo person spotlight ("Amma").
  static const int _minSpotlightFiles = 6;

  /// Minimum photos for a "Last time with X" memory (lower than a spotlight —
  /// someone you haven't seen in years deserves a card even with few photos).
  static const int _minLastTimeFiles = 2;

  /// Minimum total together-tagged photos before two people can form a memory.
  static const int _minTogetherTotal = 4;

  /// Minimum together-photos within one time session for that session to become
  /// its own "together" memory.
  static const int _minTogetherSession = 3;

  /// "Last time with X" only triggers when all photos are older than this.
  static const int _lastTimeThreshold = 365 * 24 * 60 * 60 * 1000 * 1000; // 1 year

  static const int _minYearFiles = 10;
  static const int _minSeasonFiles = 6;

  Future<int> rebuild() async {
    final persons = await _isar.persons
        .filter()
        .isDeletedEqualTo(false)
        .isHiddenEqualTo(false)
        .findAll();

    final named = persons.where((p) => p.name?.isNotEmpty ?? false).toList();
    debugPrint('[mapper] persons: ${persons.length} total, ${named.length} named'
        ' (${named.map((p) => p.name).join(", ")})');

    await _backfillPersonTags(persons);

    final prefs = await SharedPreferences.getInstance();
    final storedSelfId = prefs.getString(kSelfRemoteIdPref);
    // Re-use a previously confirmed selfId so it stays stable across rebuilds.
    // Only (re-)detect when no value is stored yet.
    final selfId = (storedSelfId != null &&
            persons.any((p) => p.remoteID == storedSelfId))
        ? storedSelfId
        : _detectSelf(persons);
    if (selfId != null && storedSelfId == null) {
      await prefs.setString(kSelfRemoteIdPref, selfId);
    }
    debugPrint('[mapper] self: $selfId'
        ' (${persons.firstWhere((p) => p.remoteID == selfId, orElse: () => Person()..name = "?").name})');
    final byId = {for (final p in persons) p.remoteID: p};
    final now = DateTime.now().microsecondsSinceEpoch;

    // Load every (live) file ONCE and share it with all the time-based builders.
    // Previously each builder ran its own full findAll() — six scans of the
    // whole library per rebuild, which was the main source of startup lag.
    final allFiles =
        await _isar.enteFiles.filter().isDeletedEqualTo(false).findAll();

    final memories = <MemoryCluster>[];

    if (persons.isNotEmpty) {
      final peopleMemories = await _buildPeopleMemories(byId, selfId, now);
      debugPrint('[mapper] people memories: ${peopleMemories.length}');
      memories.addAll(peopleMemories);
    }

    memories.addAll(_buildOnThisDayMemories(allFiles, now));
    memories.addAll(_buildMonthFlashbacks(allFiles, now));
    memories.addAll(_buildRecentMemories(allFiles, now));
    memories.addAll(_buildTripMemories(allFiles, now));
    memories.addAll(_buildTimeMemories(allFiles, now));

    if (memories.isEmpty) {
      memories.addAll(_buildMonthlyFallback(allFiles, now));
    }

    final seen = <String>{};
    final deduped = memories.where((m) => seen.add(m.signature)).toList();
    final selected = _selectMemories(deduped);

    if (kDebugMode) {
      final typeHist = <String, int>{};
      for (final m in selected) {
        final t = m.signature.split(':').first;
        typeHist[t] = (typeHist[t] ?? 0) + 1;
      }
      debugPrint('[mapper] files=${allFiles.length} memories: '
          '${deduped.length} built → ${selected.length} kept · '
          '${typeHist.entries.map((e) => '${e.key}=${e.value}').join(' ')}');
    }

    await _isar.writeTxn(() async {
      await _isar.memoryClusters.clear();
      await _isar.memoryClusters.putAll(selected);
    });
    return selected.length;
  }

  // ---------------------------------------------------------------------------
  // Cross-memory de-duplication
  //
  // Every builder draws from the same file pool, so without coordination one
  // photo ends up headlining a person session, an "On This Day", a season card
  // and a year card all at once — the feed feels repetitive. We fix this the
  // way the official app does in spirit: walk memories best-first and let each
  // *claim* its photos; a weaker memory that mostly repeats already-claimed
  // photos is dropped. Specific people memories are always kept (they're the
  // headline), but they still claim, so broad time buckets stop echoing them.
  // ---------------------------------------------------------------------------

  /// Only "together" memories (every pair × every session) can explode on a
  /// social library. Everything else is naturally bounded — one spotlight /
  /// last-time per person, a handful of trips/seasons/years/on-this-day — so we
  /// cap only "together" and keep all the rest. This guarantees "Last time with
  /// Sam", spotlights, "4 years ago", "Last month", etc. are never starved.
  static const int _maxTogetherMemories = 150;

  List<MemoryCluster> _selectMemories(List<MemoryCluster> memories) {
    final together = <MemoryCluster>[];
    final keep = <MemoryCluster>[];
    for (final m in memories) {
      (m.signature.startsWith('together:') ? together : keep).add(m);
    }
    if (together.length > _maxTogetherMemories) {
      // Keep the most recent encounters.
      together.sort((a, b) => b.endTime.compareTo(a.endTime));
      together.removeRange(_maxTogetherMemories, together.length);
    }
    return [...keep, ...together];
  }

  // ---------------------------------------------------------------------------
  // Self detection
  // ---------------------------------------------------------------------------

  String? _detectSelf(List<Person> persons) {
    if (persons.isEmpty) return null;
    // Only consider persons the user has explicitly named in Ente — unnamed
    // clusters are unreliable and often aren't the device owner.
    final named = persons.where((p) => p.name?.isNotEmpty ?? false).toList();
    final pool = named.isNotEmpty ? named : persons;
    Person? best;
    for (final p in pool) {
      if (best == null || p.fileIds.length > best.fileIds.length) best = p;
    }
    return best?.remoteID;
  }

  // ---------------------------------------------------------------------------
  // People memories (precision-first)
  //
  // Two kinds, both resistant to face-cluster false positives:
  //  • "Together"  — "You and Amma" / "Amma and Nanna". Built ONLY from photos
  //    where both people are tagged together, requiring several such photos in
  //    one time session. A stray mis-tag (one photo) can never name a card.
  //  • "Spotlight" — "Amma" / "Last time with Amma". A solo person with enough
  //    photos; the name claim is just "these are photos of Amma", which a few
  //    outliers don't invalidate.
  //
  // The old approach — counting everyone who appeared anywhere in a time window
  // and naming the top few — is what produced "Nanna and Amma" on photos with
  // neither, and is deliberately gone.
  // ---------------------------------------------------------------------------

  Future<List<MemoryCluster>> _buildPeopleMemories(
    Map<String, Person> byId,
    String? selfId,
    int now,
  ) async {
    final named = byId.values
        .where((p) => p.remoteID != selfId && (p.name?.isNotEmpty ?? false))
        .toList();
    if (named.isEmpty) return [];

    final selfPerson = selfId != null ? byId[selfId] : null;

    // Load every file referenced by any named person (+ self) once.
    final allIds = <int>{
      for (final p in named) ...p.fileIds,
      if (selfPerson != null) ...selfPerson.fileIds,
    };
    final raw = await _isar.enteFiles.getAll(allIds.toList());
    final fileById = <int, EnteFile>{
      for (final f in raw.whereType<EnteFile>())
        if (!f.isDeleted && f.creationTime > 0) f.id: f,
    };

    List<EnteFile> resolve(Iterable<int> ids) =>
        ids.map((id) => fileById[id]).whereType<EnteFile>().toList();

    final memories = <MemoryCluster>[];

    // ── "Together" memories ────────────────────────────────────────────────
    // [coIds] = file ids where both [a] and [b] are tagged. We split those into
    // time sessions and emit one memory per session with enough joint photos.
    void addTogether(Person a, Person b, Set<int> coIds) {
      if (coIds.length < _minTogetherTotal) return;
      final co = resolve(coIds)
        ..sort((x, y) => x.creationTime.compareTo(y.creationTime));
      for (final session in _splitIntoSessions(co)) {
        if (session.length < _minTogetherSession) continue;
        final selfIsA = a.remoteID == selfId;
        final selfIsB = b.remoteID == selfId;
        final String title;
        final List<String> chips;
        if (selfIsA || selfIsB) {
          final other = selfIsA ? b : a;
          title = 'You and ${other.name!}';
          chips = [other.remoteID];
        } else {
          title = '${a.name!} and ${b.name!}';
          chips = [a.remoteID, b.remoteID];
        }
        memories.add(
          MemoryCluster()
            ..signature =
                'together:${a.remoteID}:${b.remoteID}:${session.first.creationTime}'
            ..title = title
            ..kind = MemoryKind.people
            ..startTime = session.first.creationTime
            ..endTime = session.last.creationTime
            ..personIds = chips
            ..fileIds = _sampleFileIds(session)
            ..coverFileId = _pickCover(session)
            ..generatedAt = now,
        );
      }
    }

    // self + each named person → "You and X"
    if (selfPerson != null) {
      final selfFiles = selfPerson.fileIds.toSet();
      for (final p in named) {
        addTogether(
          selfPerson,
          p,
          p.fileIds.where(selfFiles.contains).toSet(),
        );
      }
    }
    // each unordered pair of named non-self people → "X and Y"
    for (var i = 0; i < named.length; i++) {
      final aFiles = named[i].fileIds.toSet();
      for (var j = i + 1; j < named.length; j++) {
        addTogether(
          named[i],
          named[j],
          named[j].fileIds.where(aFiles.contains).toSet(),
        );
      }
    }

    // ── Solo spotlights + "last time with" ─────────────────────────────────
    final recentCutoff = now - _lastTimeThreshold;
    for (final p in named) {
      final pf = resolve(p.fileIds)
        ..sort((x, y) => y.creationTime.compareTo(x.creationTime)); // newest first
      if (pf.isEmpty) continue;

      // Spotlight needs a healthy photo count.
      if (pf.length >= _minSpotlightFiles) {
        memories.add(
          MemoryCluster()
            ..signature = 'spotlight:${p.remoteID}'
            ..title = p.name!
            ..kind = MemoryKind.people
            ..startTime = pf.last.creationTime
            ..endTime = pf.first.creationTime
            ..personIds = [p.remoteID]
            ..fileIds = _sampleFileIds(pf.reversed.toList()) // chrono for sample
            ..coverFileId = pf.first.id // most recent as cover
            ..generatedAt = now,
        );
      }

      // "Last time with X": every photo of them is over a year old. Decoupled
      // from the spotlight gate — a person you haven't seen in years is worth a
      // card even with just a couple of photos.
      if (pf.length >= _minLastTimeFiles &&
          !pf.any((f) => f.creationTime > recentCutoff)) {
        final last = _findLastDaySession(pf); // newest first
        if (last.isNotEmpty) {
          final ago = _agoLabel(last.first.creationTime, now);
          memories.add(
            MemoryCluster()
              ..signature = 'lasttime:${p.remoteID}'
              ..title = ago != null
                  ? 'Last time with ${p.name!} ($ago)'
                  : 'Last time with ${p.name!}'
              ..kind = MemoryKind.people
              ..startTime = last.last.creationTime
              ..endTime = last.first.creationTime
              ..personIds = [p.remoteID]
              ..fileIds = _sampleFileIds(last.reversed.toList())
              ..coverFileId = last.first.id
              ..generatedAt = now,
          );
        }
      }
    }

    return memories;
  }

  // Returns the most recent day-session from [pFiles] (newest-first).
  // A session boundary is a gap > 24 hours between consecutive photos.
  List<EnteFile> _findLastDaySession(List<EnteFile> pFiles) {
    if (pFiles.isEmpty) return const [];
    const oneDayUs = 24 * 60 * 60 * 1000 * 1000;
    final session = <EnteFile>[pFiles.first];
    for (var i = 1; i < pFiles.length; i++) {
      if (session.last.creationTime - pFiles[i].creationTime > oneDayUs) break;
      session.add(pFiles[i]);
    }
    return session;
  }

  // ---------------------------------------------------------------------------
  // On This Day
  // ---------------------------------------------------------------------------

  List<MemoryCluster> _buildOnThisDayMemories(List<EnteFile> allFiles, int now) {
    final today = DateTime.now();
    final memories = <MemoryCluster>[];
    const windowDays = 7; // ±7 days around the same calendar date

    // ── Combined "On This Day" across all previous years ───────────────────
    final combinedFiles = <EnteFile>[];
    for (int yearsAgo = 1; yearsAgo <= 10; yearsAgo++) {
      final targetYear = today.year - yearsAgo;
      final targetDay = _clampDay(today.day, today.month, targetYear);
      final centre = DateTime(targetYear, today.month, targetDay);
      final wStart = centre.subtract(const Duration(days: windowDays)).microsecondsSinceEpoch;
      final wEnd = centre.add(const Duration(days: windowDays)).microsecondsSinceEpoch;
      combinedFiles.addAll(allFiles.where((f) =>
          f.creationTime >= wStart && f.creationTime <= wEnd));
    }
    combinedFiles.sort((a, b) => a.creationTime.compareTo(b.creationTime));

    if (combinedFiles.length >= 2) {
      memories.add(
        MemoryCluster()
          ..signature = 'onthisday:combined'
          ..title = 'On This Day'
          ..kind = MemoryKind.onThisDay
          ..startTime = combinedFiles.first.creationTime
          ..endTime = combinedFiles.last.creationTime
          ..personIds = const []
          ..fileIds = _sampleFileIds(combinedFiles)
          ..coverFileId = _pickCover(combinedFiles)
          ..generatedAt = now,
      );
    }

    // ── Per-year memories: "1 year ago today", "4 years ago today" … ───────
    for (int yearsAgo = 1; yearsAgo <= 10; yearsAgo++) {
      final targetYear = today.year - yearsAgo;
      final targetDay = _clampDay(today.day, today.month, targetYear);
      final centre = DateTime(targetYear, today.month, targetDay);
      final wStart = centre.subtract(const Duration(days: windowDays)).microsecondsSinceEpoch;
      final wEnd = centre.add(const Duration(days: windowDays)).microsecondsSinceEpoch;

      final windowFiles = allFiles
          .where((f) => f.creationTime >= wStart && f.creationTime <= wEnd)
          .toList()
        ..sort((a, b) => a.creationTime.compareTo(b.creationTime));

      if (windowFiles.isEmpty) continue;

      final label = yearsAgo == 1 ? '1 year ago today' : '$yearsAgo years ago today';
      memories.add(
        MemoryCluster()
          ..signature = 'onthisday:$targetYear'
          ..title = label
          ..kind = MemoryKind.onThisDay
          ..startTime = windowFiles.first.creationTime
          ..endTime = windowFiles.last.creationTime
          ..personIds = const []
          ..fileIds = _sampleFileIds(windowFiles)
          ..coverFileId = _pickCover(windowFiles)
          ..generatedAt = now,
      );
    }

    return memories;
  }

  // ---------------------------------------------------------------------------
  // Month flashbacks ("A year ago this month", "2 years ago this month", …)
  //
  // Broader than on-this-day (which needs photos within ±7 days of today's
  // exact date): this groups every photo from the *same calendar month* in each
  // previous year, so a trip you took in June 2022 surfaces every June — the
  // "2 years ago this month" / "last year" cards the feed was missing.
  // ---------------------------------------------------------------------------

  static const int _minFlashbackFiles = 4;

  List<MemoryCluster> _buildMonthFlashbacks(List<EnteFile> allFiles, int now) {
    final today = DateTime.now();
    final memories = <MemoryCluster>[];
    for (var yearsAgo = 1; yearsAgo <= 10; yearsAgo++) {
      final year = today.year - yearsAgo;
      final files = allFiles.where((f) {
        if (f.creationTime <= 0) return false;
        final d = DateTime.fromMicrosecondsSinceEpoch(f.creationTime);
        return d.year == year && d.month == today.month;
      }).toList()
        ..sort((a, b) => a.creationTime.compareTo(b.creationTime));

      if (files.length < _minFlashbackFiles) continue;

      final label = yearsAgo == 1
          ? 'A year ago this month'
          : '$yearsAgo years ago this month';
      memories.add(
        MemoryCluster()
          ..signature = 'flashback:$year:${today.month}'
          ..title = label
          ..kind = MemoryKind.onThisDay
          ..startTime = files.first.creationTime
          ..endTime = files.last.creationTime
          ..personIds = const []
          ..fileIds = _sampleFileIds(files)
          ..coverFileId = _pickCover(files)
          ..generatedAt = now,
      );
    }
    return memories;
  }

  // ---------------------------------------------------------------------------
  // Recent time-window memories ("Last week", "2 weeks ago", "Last month")
  // ---------------------------------------------------------------------------

  List<MemoryCluster> _buildRecentMemories(List<EnteFile> allFiles, int now) {
    final today = DateTime.now();
    // Each entry: (signature suffix, display label, days-ago start, days-ago end)
    final windows = [
      ('lastweek',   'Last week',    1,  7),
      ('2weeksago',  '2 weeks ago',  8,  14),
      ('lastmonth',  'Last month',   21, 45),
    ];

    final memories = <MemoryCluster>[];
    for (final (sig, label, dFrom, dTo) in windows) {
      final wEnd   = today.subtract(Duration(days: dFrom)).microsecondsSinceEpoch;
      final wStart = today.subtract(Duration(days: dTo)).microsecondsSinceEpoch;

      final files = allFiles
          .where((f) => f.creationTime >= wStart && f.creationTime <= wEnd)
          .toList()
        ..sort((a, b) => a.creationTime.compareTo(b.creationTime));

      if (files.length < 2) continue;

      memories.add(
        MemoryCluster()
          ..signature = 'recent:$sig'
          ..title = label
          ..kind = MemoryKind.onThisDay
          ..startTime = files.first.creationTime
          ..endTime = files.last.creationTime
          ..personIds = const []
          ..fileIds = _sampleFileIds(files)
          ..coverFileId = _pickCover(files)
          ..generatedAt = now,
      );
    }
    return memories;
  }

  // ---------------------------------------------------------------------------
  // Location-based trips (GPS metadata, no ML model required)
  //
  // Modeled on the official app's trip calculator in spirit: establish a "home"
  // location (the densest place you shoot), split located photos into temporal
  // blocks, and treat a block spent far from home over a span of days as a
  // trip. Entegram has per-file lat/long from decrypted metadata, so this needs
  // no embeddings — it's pure geo-temporal clustering.
  // ---------------------------------------------------------------------------

  static const double _homeCellDegrees = 0.25; // ~25 km grid for home detection
  static const double _tripAwayKm = 60; // min distance from home to count
  static const int _tripBlockGapUs = 4 * 24 * 60 * 60 * 1000 * 1000; // 4 days
  static const int _minTripPhotos = 6;

  List<MemoryCluster> _buildTripMemories(List<EnteFile> all, int now) {
    bool hasGeo(EnteFile f) =>
        f.creationTime > 0 &&
        f.latitude != null &&
        f.longitude != null &&
        !(f.latitude == 0 && f.longitude == 0);

    final located = all.where(hasGeo).toList()
      ..sort((a, b) => a.creationTime.compareTo(b.creationTime));
    if (located.length < 20) return []; // too little geo data to be useful

    // Home = centroid of the densest ~25 km grid cell.
    final bins = <String, List<EnteFile>>{};
    for (final f in located) {
      final key = '${(f.latitude! / _homeCellDegrees).round()}:'
          '${(f.longitude! / _homeCellDegrees).round()}';
      bins.putIfAbsent(key, () => []).add(f);
    }
    final homeBin = bins.values.reduce((a, b) => a.length >= b.length ? a : b);
    final homeLat =
        homeBin.map((f) => f.latitude!).reduce((a, b) => a + b) / homeBin.length;
    final homeLng = homeBin.map((f) => f.longitude!).reduce((a, b) => a + b) /
        homeBin.length;

    const oneDayUs = 24 * 60 * 60 * 1000 * 1000;
    final memories = <MemoryCluster>[];

    var block = <EnteFile>[];
    int? last;

    void flush() {
      final current = block;
      block = [];
      if (current.isEmpty) return;
      // Keep only the photos actually away from home — home shots that bookend
      // a trip (airport, etc.) shouldn't drag the cluster back.
      final away = current
          .where((f) =>
              _haversineKm(homeLat, homeLng, f.latitude!, f.longitude!) >
              _tripAwayKm)
          .toList()
        ..sort((a, b) => a.creationTime.compareTo(b.creationTime));
      if (away.length < _minTripPhotos) return;
      final span = away.last.creationTime - away.first.creationTime;
      if (span < oneDayUs ~/ 2 || span > 30 * oneDayUs) return; // ½–30 days
      final start = away.first.creationTime;
      memories.add(
        MemoryCluster()
          ..signature = 'trip:$start'
          ..title = _tripTitle(start, away.last.creationTime)
          ..kind = MemoryKind.trip
          ..startTime = start
          ..endTime = away.last.creationTime
          ..personIds = const []
          ..fileIds = _sampleFileIds(away)
          ..coverFileId = _pickCover(away)
          ..generatedAt = now,
      );
    }

    for (final f in located) {
      if (last != null && f.creationTime - last > _tripBlockGapUs) flush();
      block.add(f);
      last = f.creationTime;
    }
    flush();

    debugPrint('[mapper] trips: ${memories.length}');
    return memories;
  }

  String _tripTitle(int startUs, int endUs) {
    final s = DateTime.fromMicrosecondsSinceEpoch(startUs);
    final e = DateTime.fromMicrosecondsSinceEpoch(endUs);
    // A clean day-level date range (no "Trip"/"Getaway" label) — distinguishes
    // a multi-day event from the whole-month flashbacks.
    if (s.year == e.year && s.month == e.month) {
      if (s.day == e.day) return '${s.day} ${_monthName(s.month)} ${s.year}';
      return '${s.day}–${e.day} ${_monthName(s.month)} ${s.year}';
    }
    if (s.year == e.year) {
      return '${s.day} ${_monthName(s.month)} – '
          '${e.day} ${_monthName(e.month)} ${e.year}';
    }
    return '${s.day} ${_monthName(s.month)} ${s.year} – '
        '${e.day} ${_monthName(e.month)} ${e.year}';
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const earthKm = 6371.0;
    double rad(double d) => d * pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLon = rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(rad(lat1)) * cos(rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return earthKm * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  // ---------------------------------------------------------------------------
  // Year / Season summaries
  // ---------------------------------------------------------------------------

  List<MemoryCluster> _buildTimeMemories(List<EnteFile> allFiles, int now) {
    final thisYear = DateTime.now().year;
    final byYear = <int, List<EnteFile>>{};

    for (final f in allFiles) {
      if (f.creationTime <= 0) continue;
      final d = DateTime.fromMicrosecondsSinceEpoch(f.creationTime);
      byYear.putIfAbsent(d.year, () => []).add(f);
    }

    final memories = <MemoryCluster>[];

    for (final entry in byYear.entries) {
      final year = entry.key;
      final files = entry.value
        ..sort((a, b) => a.creationTime.compareTo(b.creationTime));

      if (files.length < _minYearFiles) continue;

      if (year != thisYear) {
        memories.add(
          MemoryCluster()
            ..signature = 'year:$year'
            ..title = 'Photos from $year'
            ..kind = MemoryKind.trip
            ..startTime = files.first.creationTime
            ..endTime = files.last.creationTime
            ..personIds = const []
            ..fileIds = _sampleFileIds(files)
            ..coverFileId = _pickCover(files)
            ..generatedAt = now,
        );
      }

      final minSeason = year == thisYear ? 3 : _minSeasonFiles;
      memories.addAll(_buildSeasonCards(year, files, now, minFiles: minSeason));
    }

    return memories;
  }

  List<MemoryCluster> _buildSeasonCards(
    int year,
    List<EnteFile> files,
    int now, {
    int? minFiles,
  }) {
    final bySeason = <String, List<EnteFile>>{};
    for (final f in files) {
      final d = DateTime.fromMicrosecondsSinceEpoch(f.creationTime);
      final key = '${_season(d.month)} $year';
      bySeason.putIfAbsent(key, () => []).add(f);
    }

    final threshold = minFiles ?? _minSeasonFiles;
    final memories = <MemoryCluster>[];
    for (final entry in bySeason.entries) {
      final group = entry.value
        ..sort((a, b) => a.creationTime.compareTo(b.creationTime));
      if (group.length < threshold) continue;

      memories.add(
        MemoryCluster()
          ..signature = 'season:${entry.key}'
          ..title = entry.key
          ..kind = MemoryKind.trip
          ..startTime = group.first.creationTime
          ..endTime = group.last.creationTime
          ..personIds = const []
          ..fileIds = _sampleFileIds(group)
          ..coverFileId = _pickCover(group)
          ..generatedAt = now,
      );
    }
    return memories;
  }

  // ---------------------------------------------------------------------------
  // Monthly fallback
  // ---------------------------------------------------------------------------

  List<MemoryCluster> _buildMonthlyFallback(List<EnteFile> allFiles, int now) {
    final byMonth = <String, List<EnteFile>>{};
    for (final f in allFiles) {
      if (f.creationTime <= 0) continue;
      final d = DateTime.fromMicrosecondsSinceEpoch(f.creationTime);
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      byMonth.putIfAbsent(key, () => []).add(f);
    }

    final memories = <MemoryCluster>[];
    for (final entry in byMonth.entries) {
      final group = entry.value
        ..sort((a, b) => a.creationTime.compareTo(b.creationTime));
      if (group.length < 2) continue;
      final d = DateTime.fromMicrosecondsSinceEpoch(group.first.creationTime);
      memories.add(
        MemoryCluster()
          ..signature = 'month:${entry.key}'
          ..title = '${_monthName(d.month)} ${d.year}'
          ..kind = MemoryKind.trip
          ..startTime = group.first.creationTime
          ..endTime = group.last.creationTime
          ..personIds = const []
          ..fileIds = _sampleFileIds(group)
          ..coverFileId = _pickCover(group)
          ..generatedAt = now,
      );
    }
    return memories;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String? _agoLabel(int timeMicros, int now) {
    final days = (now - timeMicros) ~/ (24 * 60 * 60 * 1000 * 1000);
    if (days < 30) return null;
    final months = days ~/ 30;
    if (months < 12) return months == 1 ? '1 month ago' : '$months months ago';
    final years = months ~/ 12;
    return years == 1 ? '1 year ago' : '$years years ago';
  }

  static const _maxFilesPerMemory = 20;

  List<int> _sampleFileIds(List<EnteFile> files) {
    if (files.length <= _maxFilesPerMemory) {
      return files.map((f) => f.id).toList();
    }
    final result = <int>[];
    final step = (files.length - 1) / (_maxFilesPerMemory - 1);
    for (var i = 0; i < _maxFilesPerMemory; i++) {
      result.add(files[(i * step).round()].id);
    }
    return result;
  }

  int _pickCover(List<EnteFile> session) {
    EnteFile? best;
    for (final f in session) {
      if (best == null || f.personIds.length > best.personIds.length) best = f;
    }
    return (best ?? session[session.length ~/ 2]).id;
  }

  List<List<EnteFile>> _splitIntoSessions(List<EnteFile> sorted) {
    final sessions = <List<EnteFile>>[];
    var current = <EnteFile>[];
    int? last;
    for (final f in sorted) {
      if (last != null && f.creationTime - last > _sessionGap) {
        sessions.add(current);
        current = [];
      }
      current.add(f);
      last = f.creationTime;
    }
    if (current.isNotEmpty) sessions.add(current);
    return sessions;
  }

  String _season(int month) {
    if (month >= 3 && month <= 5) return 'Spring';
    if (month >= 6 && month <= 8) return 'Summer';
    if (month >= 9 && month <= 11) return 'Fall';
    return 'Winter';
  }

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  String _monthName(int month) => _monthNames[month - 1];

  int _clampDay(int day, int month, int year) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return day.clamp(1, lastDay);
  }

  Future<void> _backfillPersonTags(List<Person> persons) async {
    final tags = <int, Set<String>>{};
    for (final person in persons) {
      for (final fileId in person.fileIds) {
        tags.putIfAbsent(fileId, () => {}).add(person.remoteID);
      }
    }
    if (tags.isEmpty) return;

    final files = await _isar.enteFiles.getAll(tags.keys.toList());
    final updated = <EnteFile>[];
    for (final file in files) {
      if (file == null) continue;
      final newIds = tags[file.id]!.toList();
      if (file.personIds.length == newIds.length &&
          file.personIds.toSet().containsAll(newIds)) {
        continue;
      }
      file.personIds = newIds;
      updated.add(file);
    }
    if (updated.isNotEmpty) {
      await _isar.writeTxn(() => _isar.enteFiles.putAll(updated));
    }
  }
}
