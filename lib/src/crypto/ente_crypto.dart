import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_sodium/flutter_sodium.dart';

/// Pure libsodium wrappers using flutter_sodium (ente-io fork), mirroring
/// Ente's crypto protocol. All methods are synchronous FFI calls — safe to
/// call from any isolate after [Sodium.init()].
class EnteCrypto {
  EnteCrypto();

  static void init() => Sodium.init();

  int get keyBytes => Sodium.cryptoSecretboxKeybytes;

  // ---------------------------------------------------------------------------
  // Symmetric secretbox — XSalsa20-Poly1305
  // ---------------------------------------------------------------------------

  Uint8List decryptSecretBox({
    required Uint8List cipher,
    required Uint8List key,
    required Uint8List nonce,
  }) => Sodium.cryptoSecretboxOpenEasy(cipher, nonce, key);

  // ---------------------------------------------------------------------------
  // Sealed box — X25519 (shared collections + session token)
  // ---------------------------------------------------------------------------

  Uint8List sealOpen({
    required Uint8List cipher,
    required Uint8List publicKey,
    required Uint8List secretKey,
  }) => Sodium.cryptoBoxSealOpen(cipher, publicKey, secretKey);

  // ---------------------------------------------------------------------------
  // XChaCha20-Poly1305 secretstream — file metadata blobs
  // ---------------------------------------------------------------------------

  // Ente encrypts in 4 MB plaintext chunks; ciphertext adds 17 bytes per chunk.
  static const int _plainChunkSize = 4 * 1024 * 1024;
  static const int _cipherChunkSize = _plainChunkSize + 17;

  Uint8List decryptChaCha({
    required Uint8List cipher,
    required Uint8List key,
    required Uint8List header,
  }) {
    final state =
        Sodium.cryptoSecretstreamXchacha20poly1305InitPull(header, key);
    if (cipher.length <= _cipherChunkSize) {
      return Sodium.cryptoSecretstreamXchacha20poly1305Pull(state, cipher, null)
          .m;
    }
    // Multi-chunk: iterate 4 MB at a time.
    final out = BytesBuilder(copy: false);
    var offset = 0;
    while (offset < cipher.length) {
      final end = (offset + _cipherChunkSize).clamp(0, cipher.length);
      final chunk = cipher.sublist(offset, end);
      out.add(
        Sodium.cryptoSecretstreamXchacha20poly1305Pull(state, chunk, null).m,
      );
      offset = end;
    }
    return out.takeBytes();
  }

  /// Decrypts an Ente secretstream file chunk-by-chunk from [inputPath] to
  /// [outputPath] without loading the full content into memory. Safe for large
  /// video files.
  Future<void> decryptChaChaToFile({
    required String inputPath,
    required String outputPath,
    required Uint8List key,
    required Uint8List header,
  }) async {
    final inFile = await File(inputPath).open();
    final outFile = await File(outputPath).open(mode: FileMode.write);
    try {
      final state =
          Sodium.cryptoSecretstreamXchacha20poly1305InitPull(header, key);
      while (true) {
        final chunk = await inFile.read(_cipherChunkSize);
        if (chunk.isEmpty) break;
        final plain = Sodium.cryptoSecretstreamXchacha20poly1305Pull(
          state,
          Uint8List.fromList(chunk),
          null,
        );
        await outFile.writeFrom(plain.m);
      }
    } finally {
      await inFile.close();
      await outFile.close();
    }
  }

  Future<Map<String, dynamic>> decryptMetadataJson({
    required Uint8List cipher,
    required Uint8List key,
    required Uint8List header,
  }) async {
    final bytes = decryptChaCha(cipher: cipher, key: key, header: header);
    return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  }

  /// Same as [decryptMetadataJson] but gunzips the plaintext first.
  /// Used for entity types that store gzip-compressed JSON (e.g. cgroup/person).
  Future<Map<String, dynamic>> decryptMetadataJsonGzipped({
    required Uint8List cipher,
    required Uint8List key,
    required Uint8List header,
  }) async {
    final bytes = decryptChaCha(cipher: cipher, key: key, header: header);
    final decompressed = GZipCodec().decode(bytes);
    return jsonDecode(utf8.decode(decompressed)) as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // Base64 helpers
  // ---------------------------------------------------------------------------

  static Uint8List b64(String value) => base64.decode(value);
  static String toB64(Uint8List value) => base64.encode(value);
}
