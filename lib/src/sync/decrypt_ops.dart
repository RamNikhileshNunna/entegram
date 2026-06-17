import 'package:flutter/foundation.dart';

import '../crypto/ente_crypto.dart';
import '../db/models/ente_collection.dart';
import '../db/models/ente_file.dart';
import '../db/models/person.dart';

/// Pure decryption operations that turn Ente's encrypted diff JSON into the
/// plain Isar models. These run inside the background crypto isolate but are
/// written as free functions so they can also be unit-tested directly.
///
/// All key material (master key, collection keys, entity key) stays inside the
/// isolate; only decrypted, displayable models cross back to the main isolate.

/// Decrypts one collection's key + name. Returns the model and the raw
/// collection key (kept in the isolate to decrypt that collection's files).
class DecryptedCollection {
  DecryptedCollection(this.collection, this.collectionKey);
  final EnteCollection collection;
  final Uint8List collectionKey;
}

DecryptedCollection decryptCollection(
  EnteCrypto crypto, {
  required Uint8List masterKey,
  required Uint8List secretKey,
  required Uint8List publicKey,
  required int currentUserID,
  required Map<String, dynamic> raw,
}) {
  final ownerID = (raw['owner'] as Map?)?['id'] as int? ?? currentUserID;
  final nonce = raw['keyDecryptionNonce'] as String?;

  // Owned collections: key sealed under the master key (secretbox + nonce).
  // Shared collections: key sealed under our public key (no nonce needed).
  // Use nonce presence as the primary indicator — more reliable than comparing
  // userIDs which can be 0 when the verify response omits the 'id' field.
  final isOwned = (nonce != null && nonce.isNotEmpty)
      ? true
      : (currentUserID != 0 && ownerID == currentUserID);

  final collectionID = raw['id'];
  debugPrint('[crypto] collection $collectionID ownerID=$ownerID '
      'currentUserID=$currentUserID isOwned=$isOwned hasNonce=${nonce != null}');

  final encryptedKey = EnteCrypto.b64(raw['encryptedKey'] as String);
  final Uint8List collectionKey;
  if (isOwned) {
    collectionKey = crypto.decryptSecretBox(
      cipher: encryptedKey,
      key: masterKey,
      nonce: EnteCrypto.b64(nonce!),
    );
  } else {
    collectionKey = crypto.sealOpen(
      cipher: encryptedKey,
      publicKey: publicKey,
      secretKey: secretKey,
    );
  }

  final collection = EnteCollection()
    ..id = raw['id'] as int
    ..collectionID = raw['id'] as int
    ..ownerID = ownerID
    ..isOwned = isOwned
    ..type = raw['type'] as String?
    ..updationTime = raw['updationTime'] as int? ?? 0
    ..isDeleted = raw['isDeleted'] == true
    ..encryptedKey = raw['encryptedKey'] as String?
    ..keyDecryptionNonce = raw['keyDecryptionNonce'] as String?;

  // Collection name is itself secretbox-encrypted under the collection key.
  final encryptedName = raw['encryptedName'] as String?;
  final nameNonce = raw['nameDecryptionNonce'] as String?;
  if (encryptedName != null && nameNonce != null) {
    final nameBytes = crypto.decryptSecretBox(
      cipher: EnteCrypto.b64(encryptedName),
      key: collectionKey,
      nonce: EnteCrypto.b64(nameNonce),
    );
    collection.name = String.fromCharCodes(nameBytes);
  }

  return DecryptedCollection(collection, collectionKey);
}

/// Decrypts one file diff entry: file key (secretbox under the collection key)
/// then the metadata blobs (XChaCha20 secretstream under the file key).
Future<EnteFile> decryptFile(
  EnteCrypto crypto, {
  required Uint8List collectionKey,
  required Map<String, dynamic> raw,
}) async {
  final file = EnteFile()
    ..id = raw['id'] as int
    ..collectionID = raw['collectionID'] as int
    ..ownerID = raw['ownerID'] as int? ?? 0
    ..updationTime = raw['updationTime'] as int? ?? 0
    ..isDeleted = raw['isDeleted'] == true
    ..fileType = 0
    ..creationTime = 0
    ..modificationTime = 0
    ..encryptedKey = raw['encryptedKey'] as String?
    ..keyDecryptionNonce = raw['keyDecryptionNonce'] as String?
    ..thumbnailDecryptionHeader =
        (raw['thumbnail'] as Map?)?['decryptionHeader'] as String?
    ..fileDecryptionHeader =
        (raw['file'] as Map?)?['decryptionHeader'] as String?;

  if (file.isDeleted) return file;

  final fileKey = crypto.decryptSecretBox(
    cipher: EnteCrypto.b64(raw['encryptedKey'] as String),
    key: collectionKey,
    nonce: EnteCrypto.b64(raw['keyDecryptionNonce'] as String),
  );

  final metaNode = raw['metadata'] as Map?;
  if (metaNode != null) {
    final metadata = await crypto.decryptMetadataJson(
      cipher: EnteCrypto.b64(metaNode['encryptedData'] as String),
      key: fileKey,
      header: EnteCrypto.b64(metaNode['decryptionHeader'] as String),
    );
    _applyMetadata(file, metadata);
  }

  // Public magic metadata can override dimensions / edited values.
  final pubNode = raw['pubMagicMetadata'] as Map?;
  if (pubNode != null) {
    final pub = await crypto.decryptMetadataJson(
      cipher: EnteCrypto.b64(pubNode['data'] as String),
      key: fileKey,
      header: EnteCrypto.b64(pubNode['header'] as String),
    );
    file.width = pub['w'] as int? ?? file.width;
    file.height = pub['h'] as int? ?? file.height;
    if (pub['editedTime'] is int) {
      file.creationTime = pub['editedTime'] as int;
    }
  }

  return file;
}

void _applyMetadata(EnteFile file, Map<String, dynamic> m) {
  file
    ..title = m['title'] as String?
    ..hash = (m['hash'] ?? m['imageHash'] ?? m['videoHash']) as String?
    ..fileType = m['fileType'] as int? ?? 0
    ..creationTime = m['creationTime'] as int? ?? 0
    ..modificationTime = m['modificationTime'] as int? ?? 0
    ..width = m['w'] as int?
    ..height = m['h'] as int?
    ..latitude = (m['latitude'] as num?)?.toDouble()
    ..longitude = (m['longitude'] as num?)?.toDouble();
}

/// Decrypts an encrypted thumbnail: unwrap the file key (secretbox under the
/// collection key) then decrypt the thumbnail bytes (XChaCha20 secretstream
/// under the file key, using the stored thumbnail header).
Future<Uint8List> decryptThumbnailBytes(
  EnteCrypto crypto, {
  required Uint8List collectionKey,
  required String encryptedFileKeyB64,
  required String keyNonceB64,
  required String thumbnailHeaderB64,
  required Uint8List encryptedBytes,
}) async {
  final fileKey = crypto.decryptSecretBox(
    cipher: EnteCrypto.b64(encryptedFileKeyB64),
    key: collectionKey,
    nonce: EnteCrypto.b64(keyNonceB64),
  );
  return crypto.decryptChaCha(
    cipher: encryptedBytes,
    key: fileKey,
    header: EnteCrypto.b64(thumbnailHeaderB64),
  );
}

/// Decrypts a collection key from its stored ciphertext, used to re-prime the
/// isolate's key cache after a restart without a full re-sync.
Uint8List decryptCollectionKey(
  EnteCrypto crypto, {
  required Uint8List masterKey,
  required Uint8List secretKey,
  required Uint8List publicKey,
  required bool isOwned,
  required String encryptedKeyB64,
  String? keyNonceB64,
}) {
  final cipher = EnteCrypto.b64(encryptedKeyB64);
  // Re-apply nonce-presence check: if the stored isOwned flag is wrong
  // (e.g. was persisted when currentUserID was 0), nonce presence is a
  // reliable fallback — secretbox requires a nonce, sealOpen does not.
  final useSecretBox = isOwned || (keyNonceB64 != null && keyNonceB64.isNotEmpty);
  if (useSecretBox) {
    return crypto.decryptSecretBox(
      cipher: cipher,
      key: masterKey,
      nonce: EnteCrypto.b64(keyNonceB64!),
    );
  }
  return crypto.sealOpen(
    cipher: cipher,
    publicKey: publicKey,
    secretKey: secretKey,
  );
}

/// Decrypts the user-entity key (secretbox under the master key) used for all
/// person/cluster payloads.
Uint8List decryptEntityKey(
  EnteCrypto crypto, {
  required Uint8List masterKey,
  required Map<String, dynamic> rawKey,
}) {
  return crypto.decryptSecretBox(
    cipher: EnteCrypto.b64(rawKey['encryptedKey'] as String),
    key: masterKey,
    nonce: EnteCrypto.b64((rawKey['header'] ?? rawKey['nonce']) as String),
  );
}

/// Decrypts one `person` entity (XChaCha20 secretstream under the entity key).
Future<Person> decryptPerson(
  EnteCrypto crypto, {
  required Uint8List entityKey,
  required Map<String, dynamic> raw,
}) async {
  final person = Person()
    ..remoteID = raw['id'] as String
    ..updationTime = raw['updationTime'] as int? ?? 0
    ..isDeleted = raw['isDeleted'] == true;

  if (person.isDeleted) return person;

  // cgroup entities are gzip-compressed then XChaCha20-encrypted.
  // Fall back to non-gzipped in case the entity was written by an older client.
  final cipher = EnteCrypto.b64(raw['encryptedData'] as String);
  final header = EnteCrypto.b64(raw['header'] as String);
  Map<String, dynamic> data;
  try {
    data = await crypto.decryptMetadataJsonGzipped(
      cipher: cipher, key: entityKey, header: header,
    );
  } catch (_) {
    debugPrint('[sync] cgroup ${person.remoteID}: gzip failed, trying plain');
    data = await crypto.decryptMetadataJson(
      cipher: cipher, key: entityKey, header: header,
    );
  }
  debugPrint('[sync] person ${person.remoteID}: name="${data['name']}" '
      'clusters=${(data['assigned'] as List?)?.length ?? 0}');

  person
    ..name = data['name'] as String?
    ..isHidden = data['isHidden'] == true
    ..avatarFaceID = data['avatarFaceID'] as String?
    ..birthDate = data['birthDate'] as String?;

  final assigned = (data['assigned'] as List?) ?? const [];
  person.clusterIds = assigned
      .map((c) => (c as Map)['id'] as String?)
      .whereType<String>()
      .toList();

  // Derive the file ids this person appears in: each cluster lists face ids of
  // the form "<fileID>_<n>", plus any manually-assigned file ids.
  final fileIds = <int>{};
  for (final cluster in assigned) {
    final faces = ((cluster as Map)['faces'] as List?) ?? const [];
    for (final face in faces) {
      final fileId = int.tryParse(face.toString().split('_').first);
      if (fileId != null) fileIds.add(fileId);
    }
  }
  for (final id in (data['manuallyAssigned'] as List?) ?? const []) {
    if (id is num) fileIds.add(id.toInt());
  }
  person.fileIds = fileIds.toList();

  return person;
}
