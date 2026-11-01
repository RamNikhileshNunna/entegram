import 'package:isar_community/isar.dart';
part 'file_ml.g.dart';

/// Only compact scene scores are retained, never face/image embedding vectors.
/// A persistent queue keeps remote status progress separate from successful
/// file decryption, including metadata that arrives later in archive backfill.
@collection
class FileMl {
  Id id = Isar.autoIncrement;
  int updatedAt = 0;
  int promptRevision = 0;
  @Index()
  int creationTime = 0;
  @Index()
  bool hasFile = false;
  @Index()
  bool pending = true;
  @Index()
  int retryAt = 0;
  String? issue;
  List<double> scores = [];
}
