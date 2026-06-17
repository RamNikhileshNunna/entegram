import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_sodium/flutter_sodium.dart';

import '../crypto/ente_crypto.dart';
import 'auth_models.dart';

/// Heavy, libsodium-backed login crypto. Each function calls [Sodium.init]
/// so it is safe to invoke via `Isolate.run` without any prior setup.

/// Derives the KEK (Argon2id) and the SRP login key from the password.
Future<LoginKeys> deriveLoginKeys({
  required String password,
  required String kekSaltB64,
  required int memLimit,
  required int opsLimit,
}) async {
  Sodium.init();

  final kek = Sodium.cryptoPwhash(
    Sodium.cryptoSecretboxKeybytes,
    Uint8List.fromList(utf8.encode(password)),
    EnteCrypto.b64(kekSaltB64),
    opsLimit,
    memLimit,
    Sodium.cryptoPwhashAlgArgon2id13,
  );

  // KDF subkey 1 with context "loginctx"; take the first 16 bytes.
  final derived = Sodium.cryptoKdfDeriveFromKey(
    32,
    1,
    utf8.encode('loginctx'),
    kek,
  );
  final loginKey = derived.sublist(0, 16);

  return LoginKeys(keyEncryptionKey: kek, loginKey: loginKey);
}

/// Unwraps master/secret keys and the session token from the verify response.
Future<Session> unlockSession({
  required Uint8List kek,
  required KeyAttributes attrs,
  String? encryptedTokenB64,
}) async {
  Sodium.init();

  final masterKey = Sodium.cryptoSecretboxOpenEasy(
    EnteCrypto.b64(attrs.encryptedKey),
    EnteCrypto.b64(attrs.keyDecryptionNonce),
    kek,
  );

  final secretKey = Sodium.cryptoSecretboxOpenEasy(
    EnteCrypto.b64(attrs.encryptedSecretKey),
    EnteCrypto.b64(attrs.secretKeyDecryptionNonce),
    masterKey,
  );

  final publicKey = EnteCrypto.b64(attrs.publicKey);

  var token = '';
  if (encryptedTokenB64 != null) {
    final tokenBytes = Sodium.cryptoBoxSealOpen(
      EnteCrypto.b64(encryptedTokenB64),
      publicKey,
      secretKey,
    );
    token = base64Url.encode(tokenBytes);
  }

  return Session(
    token: token,
    masterKey: masterKey,
    secretKey: secretKey,
    publicKey: publicKey,
  );
}
