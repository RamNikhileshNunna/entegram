import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../crypto/ente_crypto.dart';
import '../db/models/ente_file.dart';
import 'semantic_catalog.dart';

class MlClassification {
  const MlClassification(this.fileId, {this.scores = const [], this.issue});
  final int fileId;
  final List<double> scores;
  final String? issue;
}

/// Called exclusively in the key-owning crypto worker. Ente mldata is gzipped
/// JSON encrypted with the file key; only the compact query scores leave here.
MlClassification decryptMlData(
  EnteCrypto crypto,
  EnteFile file,
  Map<String, dynamic> envelope,
  Uint8List collectionKey,
  List<List<double>> queries,
) {
  try {
    final encoded = envelope['encryptedData'] as String;
    if (encoded.length > 8 * 1024 * 1024) {
      throw const FormatException('ML payload too large');
    }
    final key = crypto.decryptSecretBox(
      cipher: EnteCrypto.b64(file.encryptedKey!),
      key: collectionKey,
      nonce: EnteCrypto.b64(file.keyDecryptionNonce!),
    );
    final compressed = crypto.decryptChaCha(
      cipher: EnteCrypto.b64(encoded),
      key: key,
      header: EnteCrypto.b64(envelope['decryptionHeader'] as String),
    );
    final data = decodeMlJson(compressed);
    final clip = data['clip'];
    if (clip == null) return MlClassification(file.id, issue: 'not-indexed');
    if (clip is! Map || clip['version'] != 1) {
      return MlClassification(file.id, issue: 'incompatible');
    }
    return MlClassification(
      file.id,
      scores: scoreClipVector(clip['embedding'] as List, queries),
    );
  } on FormatException {
    return MlClassification(file.id, issue: 'invalid');
  } catch (_) {
    // Do not expose decrypted payloads, embeddings or key material in errors.
    return MlClassification(file.id, issue: 'decryption-failed');
  }
}

Map<String, dynamic> decodeMlJson(Uint8List compressed) {
  const maxBytes = 4 * 1024 * 1024;
  if (compressed.length > maxBytes) {
    throw const FormatException('ML payload too large');
  }
  final sink = _LimitedBytes(maxBytes);
  final decoder = gzip.decoder.startChunkedConversion(sink);
  decoder.add(compressed);
  decoder.close();
  final value = jsonDecode(utf8.decode(sink.bytes.takeBytes()));
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Invalid ML JSON');
  }
  return value;
}

class _LimitedBytes implements Sink<List<int>> {
  _LimitedBytes(this.limit);
  final int limit;
  final bytes = BytesBuilder(copy: false);
  @override
  void add(List<int> data) {
    if (bytes.length + data.length > limit) {
      throw const FormatException('ML payload too large');
    }
    bytes.add(data);
  }

  @override
  void close() {}
}
