import 'package:isar_community/isar.dart';

part 'ente_file.g.dart';

/// A decrypted Ente file's metadata. The Isar `id` is the server's
/// `uploadedFileID`. Holds only what the feed needs: file ids,
/// timestamps, and face-clustering ids — plus the minimum needed to render the
/// Entegram feed. No encryption keys, no raw bytes.
@collection
class EnteFile {
  EnteFile();

  /// Server `uploadedFileID` (== [id]).
  Id id = Isar.autoIncrement;

  @Index()
  late int collectionID;

  late int ownerID;

  String? title;

  /// libsodium content hash from the decrypted metadata (dedupe key).
  String? hash;

  /// 0 = image, 1 = video, 2 = live photo (mirrors Ente's `fileType`).
  late int fileType;

  /// Capture time in microseconds (decrypted metadata `creationTime`).
  @Index()
  late int creationTime;

  late int modificationTime;

  int? width;
  int? height;

  double? latitude;
  double? longitude;

  /// Face cluster ids this file belongs to, mapped from the person/cluster
  /// entities. Drives [MemoryCluster] grouping.
  List<String> faceClusterIds = const [];

  /// Stable remote ids of the people detected in this file.
  List<String> personIds = const [];

  /// Microsecond cursor for the files/collection diff.
  late int updationTime;

  bool isDeleted = false;

  // --- Re-decryption material (all ciphertext; the *secret* keys never leave
  // the crypto isolate). Persisted so thumbnails can be decrypted on demand
  // without re-running a full sync. ---

  /// File key encrypted under the collection key (base64).
  String? encryptedKey;

  /// Nonce for [encryptedKey] (base64).
  String? keyDecryptionNonce;

  /// XChaCha20 secretstream header for the encrypted thumbnail (base64).
  String? thumbnailDecryptionHeader;

  /// XChaCha20 secretstream header for the encrypted full file (base64).
  String? fileDecryptionHeader;
}
