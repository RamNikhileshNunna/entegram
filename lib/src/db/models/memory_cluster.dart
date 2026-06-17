import 'package:isar_community/isar.dart';

part 'memory_cluster.g.dart';

/// How a memory was assembled, so the UI can pick a header style/icon.
enum MemoryKind {
  /// Built around one or more people ("You and Sam together").
  people,

  /// A burst of photos within a tight date/location window ("Last summer …").
  trip,

  /// A calendar look-back ("On this day").
  onThisDay,
}

/// A derived, denormalized "Memory" — the unit the Entegram feed renders as
/// one Instagram-style card. Produced by the [MemoryMapper] from [Person] +
/// [EnteFile] data; it is a read-model the UI watches via Riverpod.
@collection
class MemoryCluster {
  MemoryCluster();

  Id id = Isar.autoIncrement;

  /// Stable, deterministic key derived from the cluster's inputs so re-runs of
  /// the mapper upsert instead of duplicating.
  @Index(unique: true, replace: true)
  late String signature;

  /// Display header, e.g. "You and Sam".
  late String title;

  @enumerated
  MemoryKind kind = MemoryKind.people;

  /// Inclusive capture-time window (microseconds).
  @Index()
  late int startTime;
  late int endTime;

  /// People featured in this memory (remote ids).
  List<String> personIds = const [];

  /// Files that make up the memory, capture-time ascending.
  List<int> fileIds = const [];

  /// File id used as the cover/first photo.
  int? coverFileId;

  /// When this read-model was last rebuilt.
  late int generatedAt;
}
