import 'dart:async';
import 'dart:typed_data';
import 'package:entegram/src/db/models/ente_file.dart';
import 'package:entegram/src/media/thumbnail_service.dart';
import 'package:entegram/src/providers.dart';
import 'package:entegram/src/ui/widgets/media_image.dart';
import 'package:entegram/src/ui/widgets/thumbnail_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fixtures.dart';
import 'test_image.dart';

class _Thumbnails implements ThumbnailService {
  final pending = <int, Completer<Uint8List?>>{};
  @override
  Future<Uint8List?> get(EnteFile file) =>
      pending.putIfAbsent(file.id, Completer<Uint8List?>.new).future;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'a late thumbnail cannot paint into a reused tile for another file',
    (tester) async {
      final service = _Thumbnails();
      Widget app(int id) => ProviderScope(
        overrides: [thumbnailServiceProvider.overrideWithValue(service)],
        child: MaterialApp(
          home: SizedBox(
            width: 100,
            height: 100,
            child: ThumbnailImage(
              file: photo(id, DateTime(2020)),
              decodeWidth: null,
            ),
          ),
        ),
      );
      await tester.pumpWidget(app(1));
      await tester.pumpWidget(app(2));
      final expected = Uint8List.fromList(testImage);
      service.pending[2]!.complete(expected);
      await tester.pump();
      service.pending[1]!.complete(Uint8List.fromList(testImage));
      await tester.pump();
      final provider = tester.widget<Image>(find.byType(Image)).image;
      final image = provider as MemoryImage;
      expect(identical(image.bytes, expected), isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'codec validation accepts a valid image and rejects unsupported data',
    (tester) async {
      await tester.runAsync(() async {
        expect(await canDisplayImage(testImage), isTrue);
        expect(
          await canDisplayImage(Uint8List.fromList([1, 2, 3, 4])),
          isFalse,
        );
      });
    },
  );
}
