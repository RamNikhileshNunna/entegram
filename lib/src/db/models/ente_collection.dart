import 'package:isar_community/isar.dart';

part 'ente_collection.g.dart';

/// A decrypted Ente album/collection. Keys are **never** persisted here — only
/// the decrypted, displayable metadata. The Isar `id` is the server's
/// `collectionID` so diffs upsert naturally.
@collection
class EnteCollection {
  EnteCollection();

  Id id = Isar.autoIncrement;

  /// Server collection id (== [id]).
  late int collectionID;

  late int ownerID;

  /// Decrypted album name. Null while still pending decryption.
  String? name;

  /// Album type as reported by the server (album, folder, favorites, …).
  String? type;

  /// Microsecond timestamp of the last server-side change; used as the
  /// `sinceTime` cursor for the next collections diff.
  late int updationTime;

  bool isDeleted = false;

  @Index()
  bool isOwned = true;

  // Collection key material (ciphertext) persisted so the crypto isolate's
  // key cache can be re-primed after a restart without a full re-sync.

  /// Collection key encrypted under the master key (owned) or sealed to our
  /// public key (shared), base64.
  String? encryptedKey;

  /// Nonce for [encryptedKey] when owned (base64); null for shared collections.
  String? keyDecryptionNonce;
}
