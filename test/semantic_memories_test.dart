import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:entegram/src/crypto/ente_crypto.dart';
import 'package:entegram/src/memories/memory_catalog.dart';
import 'package:entegram/src/memories/memory_engine.dart';
import 'package:entegram/src/ml/ml_decoder.dart';
import 'package:entegram/src/ml/semantic_catalog.dart';
import 'package:entegram/src/ml/semantic_prompts.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  List<double> scores({
    int theme = 0,
    double score = .4,
    double neutral = .1,
  }) => List.generate(
    semanticThemes.length + 1,
    (i) => i == theme
        ? score
        : i == semanticThemes.length
        ? neutral
        : .05,
  );

  test(
    'bundled prompts are complete, normalized and compatible with Ente ML v1',
    () async {
      final prompts = await SemanticPrompts.load();
      expect(
        prompts.vectors.length,
        semanticThemes.length * promptsPerTheme + 1,
      );
      for (final vector in prompts.vectors) {
        expect(vector.length, clipDimensions);
        expect(
          vector.fold<double>(0, (sum, v) => sum + v * v),
          closeTo(1, 1e-6),
        );
      }
      expect(
        scoreClipVector(prompts.vectors.first, prompts.vectors).first,
        closeTo(1, 1e-6),
      );
      final neutral = scoreClipVector(prompts.vectors.last, prompts.vectors);
      expect(matchingThemes(neutral), isEmpty);
    },
  );

  test(
    'public photo reference scores retain useful scene matches without calling every scene a mood',
    () {
      final data =
          jsonDecode(
                File(
                  'test/fixtures/semantic_reference_scores.json',
                ).readAsStringSync(),
              )
              as Map;
      final expected = {
        'office': 'work-mode',
        'cafe': 'cozy-cafes',
        'mountains': 'outdoor-adventures',
        'beach': 'by-the-water',
      };
      for (final item in data['references'] as List) {
        final matches = matchingThemes(
          (item['scores'] as List)
              .cast<num>()
              .map((n) => n.toDouble())
              .toList(),
        ).map((i) => semanticThemes[i].id).toList();
        if (expected.containsKey(item['label'])) {
          expect(
            matches,
            contains(expected[item['label']]),
            reason: item['label'] as String,
          );
        } else {
          expect(matches, isEmpty);
        }
      }
    },
  );

  test(
    'weak, neutral, non-finite and malformed results never become mood labels',
    () {
      expect(matchingThemes(scores(score: .2)), isEmpty);
      expect(matchingThemes(scores(score: .4, neutral: .395)), isEmpty);
      expect(matchingThemes([double.nan]), isEmpty);
      expect(
        matchingThemes(List.filled(semanticThemes.length + 1, double.infinity)),
        isEmpty,
      );
      final ties = scores(theme: 0)
        ..[1] = .58
        ..[2] = .6;
      expect(matchingThemes(ties), [2, 1]);
      expect(
        () => normalizeClipVector(List.filled(512, 0)),
        throwsFormatException,
      );
      expect(() => normalizeClipVector([1, 2]), throwsFormatException);
    },
  );

  test(
    'scene memories require indexed visual evidence, never matching filenames',
    () {
      final photos = List.generate(
        4,
        (i) => photo(
          i + 1,
          DateTime(2025, 1, i + 1),
          title: 'happy hour office party.jpg',
        ),
      );
      final engine = MemoryEngine(now: DateTime(2026, 11, 1));
      expect(
        engine
            .build(photos, [])
            .where((m) => m.category == MemoryCategory.scene),
        isEmpty,
      );
      final results = engine.build(
        photos,
        [],
        sceneScores: {for (final f in photos) f.id: scores()},
      );
      final memory = results.singleWhere(
        (m) => m.category == MemoryCategory.scene,
      );
      expect(memory.title, 'Happy hour · 2025');
      expect(memory.fileIds, [1, 2, 3, 4]);
      expect(memory.categoryLabel, 'Moods & settings');
      expect(memory.signature, 'v2:scene:happy-hour:2025');
    },
  );

  test(
    'hidden people, duplicate hashes and deleted files cannot enter a scene collage',
    () {
      final photos =
          List.generate(8, (i) => photo(i + 1, DateTime(2025, 1, i + 1)))
            ..[1].hash = 'same'
            ..[2].hash = 'same'
            ..[6].isDeleted = true;
      final results = MemoryEngine(now: DateTime(2026, 11, 1)).build(
        photos,
        [
          person('hidden', 'Hidden', [2, 8], hidden: true),
        ],
        sceneScores: {for (final f in photos) f.id: scores()},
      );
      final ids = results
          .where((m) => m.category == MemoryCategory.scene)
          .expand((m) => m.fileIds)
          .toSet();
      expect(ids, {1, 4, 5, 6});
    },
  );

  test(
    'burst photos alone cannot manufacture a scene memory and covers prefer relevance',
    () {
      final photos = List.generate(
        4,
        (i) => photo(i + 1, DateTime(2025, 1, 1, 10, 0, i)),
      );
      final engine = MemoryEngine(now: DateTime(2026, 11, 1));
      expect(
        engine
            .build(
              photos,
              [],
              sceneScores: {for (final f in photos) f.id: scores()},
            )
            .where((m) => m.category == MemoryCategory.scene),
        isEmpty,
      );
      for (var i = 0; i < photos.length; i++) {
        photos[i].creationTime = DateTime(
          2025,
          1,
          i + 1,
        ).microsecondsSinceEpoch;
      }
      final scene = engine
          .build(
            photos,
            [],
            sceneScores: {
              for (final f in photos)
                f.id: scores(score: f.id == 4 ? .55 : .35),
            },
          )
          .singleWhere((m) => m.category == MemoryCategory.scene);
      expect(scene.coverFileId, 4);
    },
  );

  test('ML gzip decoding has a strict expanded-size limit', () {
    final valid = Uint8List.fromList(gzip.encode(utf8.encode('{"clip":null}')));
    expect(decodeMlJson(valid), {'clip': null});
    final bomb = Uint8List.fromList(
      gzip.encode(List.filled(5 * 1024 * 1024, 65)),
    );
    expect(() => decodeMlJson(bomb), throwsFormatException);
  });

  test(
    'real encrypted Ente file-data decrypts and incompatible versions are rejected',
    () async {
      EnteCrypto.init();
      final prompts = await SemanticPrompts.load();
      final key = Uint8List.fromList(List.generate(32, (i) => i));
      final collectionKey = Uint8List.fromList(List.generate(32, (i) => i + 5));
      final nonce = Uint8List(24);
      final file = photo(7, DateTime(2025))
        ..encryptedKey = EnteCrypto.toB64(
          Sodium.cryptoSecretboxEasy(key, nonce, collectionKey),
        )
        ..keyDecryptionNonce = EnteCrypto.toB64(nonce);
      Map<String, dynamic> envelope(int version) {
        final clear = Uint8List.fromList(
          gzip.encode(
            utf8.encode(
              jsonEncode({
                'clip': {
                  'version': version,
                  'embedding': prompts.vectors.first,
                },
              }),
            ),
          ),
        );
        final push = Sodium.cryptoSecretstreamXchacha20poly1305InitPush(key);
        final encrypted = Sodium.cryptoSecretstreamXchacha20poly1305Push(
          push.state,
          clear,
          null,
          Sodium.cryptoSecretstreamXchacha20poly1305TagFinal,
        );
        return {
          'fileID': file.id,
          'encryptedData': EnteCrypto.toB64(encrypted),
          'decryptionHeader': EnteCrypto.toB64(push.header),
        };
      }

      final result = decryptMlData(
        EnteCrypto(),
        file,
        envelope(1),
        collectionKey,
        prompts.vectors,
      );
      expect(result.issue, isNull);
      expect(result.scores.first, closeTo(1, 1e-6));
      expect(
        decryptMlData(
          EnteCrypto(),
          file,
          envelope(999),
          collectionKey,
          prompts.vectors,
        ).issue,
        'incompatible',
      );
      final bad = envelope(1)..['encryptedData'] = 'not base64!';
      expect(
        decryptMlData(
          EnteCrypto(),
          file,
          bad,
          collectionKey,
          prompts.vectors,
        ).scores,
        isEmpty,
      );
    },
    skip: !Platform.isLinux,
  );
}
