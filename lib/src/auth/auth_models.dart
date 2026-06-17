import 'dart:typed_data';

import '../crypto/ente_crypto.dart';

/// SRP login attributes from `GET /users/srp/attributes`.
class SrpAttributes {
  SrpAttributes({
    required this.srpUserID,
    required this.srpSalt,
    required this.kekSalt,
    required this.memLimit,
    required this.opsLimit,
    required this.isEmailMfaEnabled,
  });

  final String srpUserID;
  final String srpSalt; // base64
  final String kekSalt; // base64
  final int memLimit;
  final int opsLimit;
  final bool isEmailMfaEnabled;

  factory SrpAttributes.fromJson(Map<String, dynamic> j) => SrpAttributes(
    srpUserID: j['srpUserID'] as String,
    srpSalt: j['srpSalt'] as String,
    kekSalt: j['kekSalt'] as String,
    memLimit: j['memLimit'] as int,
    opsLimit: j['opsLimit'] as int,
    isEmailMfaEnabled: j['isEmailMFAEnabled'] == true,
  );
}

/// The user's encrypted key bundle, returned inside the SRP verify response.
class KeyAttributes {
  KeyAttributes({
    required this.kekSalt,
    required this.encryptedKey,
    required this.keyDecryptionNonce,
    required this.publicKey,
    required this.encryptedSecretKey,
    required this.secretKeyDecryptionNonce,
    required this.memLimit,
    required this.opsLimit,
  });

  final String kekSalt;
  final String encryptedKey;
  final String keyDecryptionNonce;
  final String publicKey;
  final String encryptedSecretKey;
  final String secretKeyDecryptionNonce;
  final int memLimit;
  final int opsLimit;

  factory KeyAttributes.fromJson(Map<String, dynamic> j) => KeyAttributes(
    kekSalt: j['kekSalt'] as String,
    encryptedKey: j['encryptedKey'] as String,
    keyDecryptionNonce: j['keyDecryptionNonce'] as String,
    publicKey: j['publicKey'] as String,
    encryptedSecretKey: j['encryptedSecretKey'] as String,
    secretKeyDecryptionNonce: j['secretKeyDecryptionNonce'] as String,
    memLimit: j['memLimit'] as int,
    opsLimit: j['opsLimit'] as int,
  );
}

/// Argon2-derived keys needed to drive SRP. [keyEncryptionKey] (KEK) decrypts
/// the master key; [loginKey] is the SRP "password".
class LoginKeys {
  LoginKeys({required this.keyEncryptionKey, required this.loginKey});

  final Uint8List keyEncryptionKey;
  final Uint8List loginKey;
}

/// The fully unlocked session: the secrets the rest of the app needs. The
/// [masterKey] unwraps collection keys; [secretKey]/[publicKey] unwrap shared
/// collections and the session token.
class Session {
  Session({
    required this.token,
    required this.masterKey,
    required this.secretKey,
    required this.publicKey,
    this.userID = 0,
  });

  final String token;
  final Uint8List masterKey;
  final Uint8List secretKey;
  final Uint8List publicKey;

  /// Server user id (from the SRP verify response); used for collection
  /// ownership checks during sync.
  final int userID;

  String get masterKeyB64 => EnteCrypto.toB64(masterKey);
}

/// Thrown when the account requires email-based MFA (OTT), which this build
/// doesn't implement.
class EmailMfaUnsupportedException implements Exception {
  @override
  String toString() => 'Email-based MFA is not supported in this build.';
}

/// Outcome of the first login step (SRP). Either we're fully logged in, or the
/// account has a second factor and we need a code before we can finish.
sealed class LoginResult {
  const LoginResult();
}

class LoginSuccess extends LoginResult {
  const LoginSuccess(this.session);
  final Session session;
}

/// A second factor is required. The derived [kek] is carried forward so the
/// master key can be unwrapped from the key attributes returned by the
/// second-factor verification.
class LoginTwoFactorRequired extends LoginResult {
  const LoginTwoFactorRequired({
    required this.sessionID,
    required this.kek,
    required this.isPasskey,
  });
  final String sessionID;
  final Uint8List kek;

  /// Passkey (WebAuthn) factor — not supported in this build; surface a hint
  /// rather than a TOTP prompt.
  final bool isPasskey;
}
