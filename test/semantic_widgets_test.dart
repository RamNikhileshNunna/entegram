import 'dart:typed_data';
import 'package:entegram/src/db/models/ente_file.dart';
import 'package:entegram/src/media/thumbnail_service.dart';
import 'package:entegram/src/ml/semantic_sync.dart';
import 'package:entegram/src/providers.dart';
import 'package:entegram/src/ui/widgets/ente_ml_info.dart';
import 'package:entegram/src/ui/widgets/memory_card.dart';
import 'package:entegram/src/ui/widgets/memory_collage.dart';
import 'package:entegram/src/ui/widgets/thumbnail_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fixtures.dart';
import 'test_image.dart';

class _Images implements ThumbnailService {
  @override
  Future<Uint8List?> get(EnteFile file) async => testImage;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _State extends SemanticStateNotifier {
  _State(this.value);
  final SemanticSyncState value;
  @override
  SemanticSyncState build() => value;
}

void main() {
  final files = List.generate(6, (i) => photo(i + 1, DateTime(2025, 1, i + 1)));
  testWidgets(
    'collage loads only four thumbnails and opens the correct original index',
    (tester) async {
      final opened = <int>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [thumbnailServiceProvider.overrideWithValue(_Images())],
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 320,
                  height: 240,
                  child: MemoryCollage(
                    files: files,
                    coverFileId: 4,
                    onOpen: opened.add,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ThumbnailImage), findsNWidgets(4));
      expect(find.text('+2'), findsOneWidget);
      await tester.tap(find.byType(InkWell).first);
      await tester.tap(find.byType(InkWell).last);
      expect(opened, [3, 2]);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final width in [320.0, 600.0]) {
    testWidgets('scene card remains usable at width $width and enlarged text', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final scene = memory(
        1,
        signature: 'v2:scene:happy-hour:2025',
        files: files.map((f) => f.id).toList(),
      )..title = 'Happy hour · 2025';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            thumbnailServiceProvider.overrideWithValue(_Images()),
            memoryFilesProvider.overrideWith((_, _) => Stream.value(files)),
          ],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.8)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(child: MemoryCard(memory: scene)),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(MemoryCollage), findsOneWidget);
      expect(find.text('Moods & settings'), findsOneWidget);
      expect(find.byTooltip('Play memory'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final state in [
    SemanticSyncState.ready,
    SemanticSyncState.unavailable,
    SemanticSyncState.error,
  ]) {
    testWidgets('ML availability message reflects ${state.name}', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            semanticSyncStateProvider.overrideWith(() => _State(state)),
            semanticCoverageProvider.overrideWith(
              (_) => Stream.value(const SemanticCoverage(8, 12)),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: EnteMlInfo())),
        ),
      );
      await tester.pump();
      expect(
        find.textContaining(switch (state) {
          SemanticSyncState.ready => '8 of 12',
          SemanticSyncState.unavailable => 'does not provide',
          _ => 'could not be updated',
        }),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
