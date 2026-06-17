import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_sodium/flutter_sodium.dart';

import '../crypto/ente_crypto.dart';
import '../db/models/ente_collection.dart';
import '../db/models/ente_file.dart';
import '../db/models/person.dart';
import 'decrypt_ops.dart';

/// Long-lived background isolate that owns all key material and performs every
/// libsodium decryption off the main thread. The main isolate talks to it with
/// a simple id-correlated request/response protocol; only decrypted Isar models
/// ever cross back.
class CryptoIsolate {
  CryptoIsolate._(this._isolate, this._toWorker, this._fromWorker);

  final Isolate _isolate;
  final SendPort _toWorker;
  final ReceivePort _fromWorker;

  final _pending = <int, Completer<Object?>>{};
  var _nextId = 0;

  /// Spawns the worker, ships it the session keys, and completes once it has
  /// initialised libsodium and is ready to serve requests.
  static Future<CryptoIsolate> spawn({
    required Uint8List masterKey,
    required Uint8List secretKey,
    required Uint8List publicKey,
    required int currentUserID,
  }) async {
    final fromWorker = ReceivePort();
    final ready = Completer<SendPort>();

    final isolate = await Isolate.spawn(
      _workerMain,
      _Boot(
        replyTo: fromWorker.sendPort,
        masterKey: masterKey,
        secretKey: secretKey,
        publicKey: publicKey,
        currentUserID: currentUserID,
      ),
    );

    final instanceCompleter = Completer<CryptoIsolate>();
    late final CryptoIsolate instance;

    fromWorker.listen((dynamic message) {
      if (message is SendPort) {
        ready.complete(message);
        instance = CryptoIsolate._(isolate, message, fromWorker);
        instanceCompleter.complete(instance);
        return;
      }
      // Response: [id, result] or [id, _IsolateError]
      final response = message as List<Object?>;
      final id = response[0] as int;
      final completer = instance._pending.remove(id);
      if (completer == null) return;
      final payload = response[1];
      if (payload is _IsolateError) {
        completer.completeError(payload.error, payload.stack);
      } else {
        completer.complete(payload);
      }
    });

    return instanceCompleter.future;
  }

  Future<Object?> _send(_Request request) {
    final id = _nextId++;
    final completer = Completer<Object?>();
    _pending[id] = completer;
    _toWorker.send([id, request]);
    return completer.future;
  }

  /// Decrypts a page of collections, caching their keys inside the worker.
  Future<List<EnteCollection>> decryptCollections(
    List<Map<String, dynamic>> raw,
  ) async => (await _send(_DecryptCollections(raw)) as List).cast();

  /// Decrypts a page of files for a previously-decrypted collection.
  Future<List<EnteFile>> decryptFiles(
    int collectionID,
    List<Map<String, dynamic>> raw,
  ) async => (await _send(_DecryptFiles(collectionID, raw)) as List).cast();

  /// Caches the user-entity key so subsequent persons can be decrypted.
  Future<void> loadEntityKey(Map<String, dynamic> rawKey) =>
      _send(_LoadEntityKey(rawKey));

  /// Decrypts a page of `person` entities.
  Future<List<Person>> decryptPersons(List<Map<String, dynamic>> raw) async =>
      (await _send(_DecryptPersons(raw)) as List).cast();

  /// Re-primes the worker's collection-key cache from stored ciphertext so
  /// thumbnails can be decrypted after a cold start without a full re-sync.
  /// Each entry: {id, isOwned, encryptedKey, keyDecryptionNonce}.
  Future<void> primeCollectionKeys(List<Map<String, dynamic>> entries) =>
      _send(_PrimeCollectionKeys(entries));

  /// Decrypts full-file bytes using the cached collection key for [collectionID].
  /// Same XChaCha20 secretstream as thumbnails; use [fileDecryptionHeader].
  Future<Uint8List> decryptFileContent({
    required int collectionID,
    required String encryptedFileKeyB64,
    required String keyNonceB64,
    required String fileHeaderB64,
    required Uint8List encryptedBytes,
  }) async =>
      await _send(
            _DecryptFile(
              collectionID,
              encryptedFileKeyB64,
              keyNonceB64,
              fileHeaderB64,
              encryptedBytes,
            ),
          )
          as Uint8List;

  /// Decrypts an encrypted file at [inputPath] to [outputPath] entirely inside
  /// the isolate, chunk-by-chunk. No large byte arrays cross the isolate
  /// boundary — safe for videos of any size.
  Future<void> decryptFileToDisk({
    required int collectionID,
    required String encryptedFileKeyB64,
    required String keyNonceB64,
    required String fileHeaderB64,
    required String inputPath,
    required String outputPath,
  }) async =>
      _send(
        _DecryptFileToDisk(
          collectionID,
          encryptedFileKeyB64,
          keyNonceB64,
          fileHeaderB64,
          inputPath,
          outputPath,
        ),
      );

  /// Downloads-then-decrypts happens caller-side; this decrypts the bytes using
  /// the cached collection key for [collectionID].
  Future<Uint8List> decryptThumbnail({
    required int collectionID,
    required String encryptedFileKeyB64,
    required String keyNonceB64,
    required String thumbnailHeaderB64,
    required Uint8List encryptedBytes,
  }) async =>
      await _send(
            _DecryptThumbnail(
              collectionID,
              encryptedFileKeyB64,
              keyNonceB64,
              thumbnailHeaderB64,
              encryptedBytes,
            ),
          )
          as Uint8List;

  void dispose() {
    _isolate.kill(priority: Isolate.immediate);
    _fromWorker.close();
  }

  // ---------------------------------------------------------------------------
  // Worker isolate
  // ---------------------------------------------------------------------------

  static Future<void> _workerMain(_Boot boot) async {
    final commands = ReceivePort();
    boot.replyTo.send(commands.sendPort);

    Sodium.init();
    final crypto = EnteCrypto();
    final collectionKeys = <int, Uint8List>{};
    Uint8List? entityKey;

    await for (final dynamic message in commands) {
      final list = message as List<Object?>;
      final id = list[0] as int;
      final request = list[1] as _Request;
      try {
        final Object? result;
        switch (request) {
          case _DecryptCollections(:final raw):
            final out = <EnteCollection>[];
            for (final c in raw) {
              final dec = decryptCollection(
                crypto,
                masterKey: boot.masterKey,
                secretKey: boot.secretKey,
                publicKey: boot.publicKey,
                currentUserID: boot.currentUserID,
                raw: c,
              );
              collectionKeys[dec.collection.collectionID] = dec.collectionKey;
              out.add(dec.collection);
            }
            result = out;
          case _DecryptFiles(:final collectionID, :final raw):
            final key = collectionKeys[collectionID];
            if (key == null) {
              throw StateError(
                'No cached key for collection $collectionID; '
                'decrypt its collection first.',
              );
            }
            final out = <EnteFile>[];
            for (final f in raw) {
              out.add(await decryptFile(crypto, collectionKey: key, raw: f));
            }
            result = out;
          case _LoadEntityKey(:final rawKey):
            entityKey = decryptEntityKey(
              crypto,
              masterKey: boot.masterKey,
              rawKey: rawKey,
            );
            result = null;
          case _DecryptPersons(:final raw):
            if (entityKey == null) {
              throw StateError('Entity key not loaded; call loadEntityKey.');
            }
            final out = <Person>[];
            for (final p in raw) {
              try {
                out.add(
                  await decryptPerson(crypto, entityKey: entityKey, raw: p),
                );
              } catch (e) {
                debugPrint('[crypto] skip person ${p['id']}: $e');
              }
            }
            result = out;
          case _PrimeCollectionKeys(:final entries):
            for (final e in entries) {
              final encryptedKey = e['encryptedKey'] as String?;
              if (encryptedKey == null) continue;
              collectionKeys[e['id'] as int] = decryptCollectionKey(
                crypto,
                masterKey: boot.masterKey,
                secretKey: boot.secretKey,
                publicKey: boot.publicKey,
                isOwned: e['isOwned'] == true,
                encryptedKeyB64: encryptedKey,
                keyNonceB64: e['keyDecryptionNonce'] as String?,
              );
            }
            result = null;
          case _DecryptThumbnail(
            :final collectionID,
            :final encryptedFileKeyB64,
            :final keyNonceB64,
            :final thumbnailHeaderB64,
            :final encryptedBytes,
          ):
            final key = collectionKeys[collectionID];
            if (key == null) {
              throw StateError(
                'No cached key for collection $collectionID; '
                'prime collection keys first.',
              );
            }
            result = await decryptThumbnailBytes(
              crypto,
              collectionKey: key,
              encryptedFileKeyB64: encryptedFileKeyB64,
              keyNonceB64: keyNonceB64,
              thumbnailHeaderB64: thumbnailHeaderB64,
              encryptedBytes: encryptedBytes,
            );
          case _DecryptFile(
            :final collectionID,
            :final encryptedFileKeyB64,
            :final keyNonceB64,
            :final fileHeaderB64,
            :final encryptedBytes,
          ):
            final key = collectionKeys[collectionID];
            if (key == null) {
              throw StateError(
                'No cached key for collection $collectionID; '
                'prime collection keys first.',
              );
            }
            result = await decryptThumbnailBytes(
              crypto,
              collectionKey: key,
              encryptedFileKeyB64: encryptedFileKeyB64,
              keyNonceB64: keyNonceB64,
              thumbnailHeaderB64: fileHeaderB64,
              encryptedBytes: encryptedBytes,
            );
          case _DecryptFileToDisk(
            :final collectionID,
            :final encryptedFileKeyB64,
            :final keyNonceB64,
            :final fileHeaderB64,
            :final inputPath,
            :final outputPath,
          ):
            final key = collectionKeys[collectionID];
            if (key == null) {
              throw StateError(
                'No cached key for collection $collectionID; '
                'prime collection keys first.',
              );
            }
            final fileKey = crypto.decryptSecretBox(
              cipher: EnteCrypto.b64(encryptedFileKeyB64),
              key: key,
              nonce: EnteCrypto.b64(keyNonceB64),
            );
            await crypto.decryptChaChaToFile(
              inputPath: inputPath,
              outputPath: outputPath,
              key: fileKey,
              header: EnteCrypto.b64(fileHeaderB64),
            );
            result = null;
        }
        boot.replyTo.send([id, result]);
      } catch (error, stack) {
        boot.replyTo.send([id, _IsolateError(error.toString(), stack)]);
      }
    }
  }
}

class _Boot {
  _Boot({
    required this.replyTo,
    required this.masterKey,
    required this.secretKey,
    required this.publicKey,
    required this.currentUserID,
  });
  final SendPort replyTo;
  final Uint8List masterKey;
  final Uint8List secretKey;
  final Uint8List publicKey;
  final int currentUserID;
}

sealed class _Request {
  const _Request();
}

class _DecryptCollections extends _Request {
  const _DecryptCollections(this.raw);
  final List<Map<String, dynamic>> raw;
}

class _DecryptFiles extends _Request {
  const _DecryptFiles(this.collectionID, this.raw);
  final int collectionID;
  final List<Map<String, dynamic>> raw;
}

class _LoadEntityKey extends _Request {
  const _LoadEntityKey(this.rawKey);
  final Map<String, dynamic> rawKey;
}

class _DecryptPersons extends _Request {
  const _DecryptPersons(this.raw);
  final List<Map<String, dynamic>> raw;
}

class _PrimeCollectionKeys extends _Request {
  const _PrimeCollectionKeys(this.entries);
  final List<Map<String, dynamic>> entries;
}

class _DecryptThumbnail extends _Request {
  const _DecryptThumbnail(
    this.collectionID,
    this.encryptedFileKeyB64,
    this.keyNonceB64,
    this.thumbnailHeaderB64,
    this.encryptedBytes,
  );
  final int collectionID;
  final String encryptedFileKeyB64;
  final String keyNonceB64;
  final String thumbnailHeaderB64;
  final Uint8List encryptedBytes;
}

class _DecryptFile extends _Request {
  const _DecryptFile(
    this.collectionID,
    this.encryptedFileKeyB64,
    this.keyNonceB64,
    this.fileHeaderB64,
    this.encryptedBytes,
  );
  final int collectionID;
  final String encryptedFileKeyB64;
  final String keyNonceB64;
  final String fileHeaderB64;
  final Uint8List encryptedBytes;
}

class _DecryptFileToDisk extends _Request {
  const _DecryptFileToDisk(
    this.collectionID,
    this.encryptedFileKeyB64,
    this.keyNonceB64,
    this.fileHeaderB64,
    this.inputPath,
    this.outputPath,
  );
  final int collectionID;
  final String encryptedFileKeyB64;
  final String keyNonceB64;
  final String fileHeaderB64;
  final String inputPath;
  final String outputPath;
}

class _IsolateError {
  _IsolateError(this.error, this.stack);
  final String error;
  final StackTrace stack;
}
