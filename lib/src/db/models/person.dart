import 'package:isar_community/isar.dart';

part 'person.g.dart';

/// A decrypted Ente `person` user-entity: a named face group produced by the
/// official client's ML clustering. We sync these read-only and use them to
/// title memories ("You and Sam").
@collection
class Person {
  Person();

  Id id = Isar.autoIncrement;

  /// Server entity UUID.
  @Index(unique: true, replace: true)
  late String remoteID;

  String? name;

  bool isHidden = false;

  /// Face id used as the person's avatar, if any.
  String? avatarFaceID;

  /// Cluster UUIDs assigned to this person. Each cluster groups face ids that
  /// in turn map to [EnteFile.faceClusterIds].
  List<String> clusterIds = const [];

  /// Uploaded file ids this person appears in, derived from the cluster face
  /// ids (Ente encodes the file id as the `<fileID>_<n>` prefix of a face id)
  /// plus any manually-assigned files. Drives memory grouping.
  List<int> fileIds = const [];

  String? birthDate;

  late int updationTime;

  bool isDeleted = false;
}
