import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/srp/srp6_client.dart';
import 'package:pointycastle/srp/srp6_standard_groups.dart';
import 'package:pointycastle/srp/srp6_util.dart';

import '../crypto/ente_crypto.dart';
import '../network/ente_api.dart';
import 'auth_models.dart';
import 'key_derivation.dart';

/// Drives the Ente SRP-6a login and produces an unlocked [Session].
///
/// The two libsodium-heavy phases — Argon2 KEK derivation and key/token
/// unwrapping — are dispatched to short-lived isolates via `Isolate.run`. The
/// SRP bignum handshake itself is cheap and stays inline.
class AuthService {
  AuthService(this._api);

  final EnteApi _api;

  /// Ente uses the RFC 5054 **4096-bit** group → `srpA` is padded to 512 bytes
  /// for transport (matching the official client). `srpM1` is padded to the
  /// SHA-256 digest size (32).
  static const int _srpAPadBytes = 512;

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final attrsRaw = await _api.srpAttributes(email);
    debugPrint('[auth] srp/attributes keys=${attrsRaw.keys.toList()}');
    final attrs = SrpAttributes.fromJson(attrsRaw);
    debugPrint(
      '[auth] srp ok: userID=${attrs.srpUserID} mem=${attrs.memLimit} '
      'ops=${attrs.opsLimit} emailMfa=${attrs.isEmailMfaEnabled}',
    );
    if (attrs.isEmailMfaEnabled) {
      throw EmailMfaUnsupportedException();
    }

    // 1. Argon2 (off-thread) → KEK + SRP login key.
    final keys = await Isolate.run(
      () => deriveLoginKeys(
        password: password,
        kekSaltB64: attrs.kekSalt,
        memLimit: attrs.memLimit,
        opsLimit: attrs.opsLimit,
      ),
    );

    // 2. SRP-6a handshake (inline; pure bignum).
    final client = SRP6Client(
      group: SRP6StandardGroups.rfc5054_4096,
      digest: SHA256Digest(),
      random: _seededRandom(),
    );
    final identity = Uint8List.fromList(utf8.encode(attrs.srpUserID));
    final salt = EnteCrypto.b64(attrs.srpSalt);

    final a = client.generateClientCredentials(salt, identity, keys.loginKey)!;
    final srpA = EnteCrypto.toB64(SRP6Util.getPadded(a, _srpAPadBytes));

    final created = await _api.srpCreateSession(
      srpUserID: attrs.srpUserID,
      srpA: srpA,
    );
    final sessionID = created['sessionID'] as String;
    final serverB = SRP6Util.decodeBigInt(
      EnteCrypto.b64(created['srpB'] as String),
    );

    client.calculateSecret(serverB);
    final m1 = client.calculateClientEvidenceMessage()!;
    final srpM1 = EnteCrypto.toB64(
      SRP6Util.getPadded(m1, SHA256Digest().digestSize),
    );

    final verify = await _api.srpVerifySession(
      srpUserID: attrs.srpUserID,
      sessionID: sessionID,
      srpM1: srpM1,
    );
    // 3a. Second factor required? Carry the KEK forward to finish after the
    // code is verified.
    final passkeySessionID = verify['passkeySessionID'] as String?;
    if (passkeySessionID != null && passkeySessionID.isNotEmpty) {
      return LoginTwoFactorRequired(
        sessionID: passkeySessionID,
        kek: keys.keyEncryptionKey,
        isPasskey: true,
      );
    }
    // The server may return twoFactorSessionID (v1) or twoFactorSessionIDV2 as
    // empty strings rather than null when the other variant carries the value.
    // Use whichever is non-empty; ?? does not help here since "" is not null.
    final totpV1 = (verify['twoFactorSessionID'] as String?) ?? '';
    final totpV2 = (verify['twoFactorSessionIDV2'] as String?) ?? '';
    final totpSessionID = totpV2.isNotEmpty ? totpV2 : (totpV1.isNotEmpty ? totpV1 : null);
    if (totpSessionID != null) {
      return LoginTwoFactorRequired(
        sessionID: totpSessionID,
        kek: keys.keyEncryptionKey,
        isPasskey: false,
      );
    }

    // 3b. No second factor — unwrap keys + token now.
    return LoginSuccess(
      await _finalizeSession(verify: verify, kek: keys.keyEncryptionKey),
    );
  }

  /// Completes a 2FA login: verifies the TOTP [code] for [sessionID] and unwraps
  /// the session using the [kek] derived during [login].
  Future<Session> verifyTotp({
    required String sessionID,
    required String code,
    required Uint8List kek,
  }) async {
    final verify = await _api.verifyTwoFactor(sessionID: sessionID, code: code);
    return _finalizeSession(verify: verify, kek: kek);
  }

  /// Unwraps master/secret keys + token (off-thread) from a verify response.
  Future<Session> _finalizeSession({
    required Map<String, dynamic> verify,
    required Uint8List kek,
  }) async {
    final keyAttrs = KeyAttributes.fromJson(
      (verify['keyAttributes'] as Map).cast<String, dynamic>(),
    );
    final encryptedToken = verify['encryptedToken'] as String?;
    final unlocked = await Isolate.run(
      () => unlockSession(
        kek: kek,
        attrs: keyAttrs,
        encryptedTokenB64: encryptedToken,
      ),
    );

    // Most accounts return an encryptedToken (decrypted above). Some return a
    // plaintext token directly — use it when the sealed path was skipped.
    final token = unlocked.token.isNotEmpty
        ? unlocked.token
        : verify['token'] as String;
    final session = Session(
      token: token,
      masterKey: unlocked.masterKey,
      secretKey: unlocked.secretKey,
      publicKey: unlocked.publicKey,
      userID: (verify['id'] as num?)?.toInt() ?? 0,
    );

    _api.authToken = session.token;
    return session;
  }

  /// A 32-byte secure-seeded Fortuna PRNG for SRP private value generation.
  static SecureRandom _seededRandom() {
    final fortuna = FortunaRandom();
    final rnd = Random.secure();
    final seed = Uint8List.fromList(
      List<int>.generate(32, (_) => rnd.nextInt(256)),
    );
    fortuna.seed(KeyParameter(seed));
    return fortuna;
  }
}
