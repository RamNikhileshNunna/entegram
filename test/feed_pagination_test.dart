import 'dart:async';
import 'package:entegram/src/db/models/memory_cluster.dart';
import 'package:entegram/src/providers.dart';
import 'package:entegram/src/ui/feed_screen.dart';
import 'package:entegram/src/ui/widgets/memory_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fixtures.dart';

void main() {
  late SharedPreferences preferences;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });
  Widget app(
    Stream<List<MemoryCluster>> stream, {
    Future<bool> Function()? page,
    double textScale = 1,
  }) => ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      thumbnailServiceProvider.overrideWithValue(null),
      fullResServiceProvider.overrideWithValue(null),
      namedPeopleProvider.overrideWith((_) => Stream.value([])),
      memoriesProvider.overrideWith((_) => stream),
      bootstrapProvider.overrideWith((_) async {}),
      memoryFilesProvider.overrideWith(
        (_, id) => Stream.value([
          photo(id * 10, DateTime(2020, 1, 1)),
          photo(id * 10 + 1, DateTime(2020, 1, 2)),
        ]),
      ),
      loadMoreProvider.overrideWithValue(page ?? () async => false),
    ],
    child: MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const FeedScreen(),
    ),
  );

  testWidgets(
    'feed renders real cards and discovers another page near the end',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        app(
          Stream.value(List.generate(12, (i) => memory(i + 1))),
          page: () async {
            calls++;
            return false;
          },
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.text('Entegram'), findsOneWidget);
      expect(find.byType(MemoryCard), findsWidgets);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -20000));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(calls, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('the feed finishes without recycling duplicate cards', (
    tester,
  ) async {
    await tester.pumpWidget(app(Stream.value([memory(1)])));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -4000));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.byType(MemoryCard), findsOneWidget);
    expect(find.textContaining('all caught up'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('a failed page can be retried and does not become exhausted', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      app(
        Stream.value([memory(1)]),
        page: () async {
          if (++calls == 1) throw StateError('offline');
          return false;
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -4000));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.text('Could not load more memories'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();
    expect(calls, 2);
    expect(find.textContaining('all caught up'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'stream updates preserve the order and refresh matching content',
    (tester) async {
      final stream = StreamController<List<MemoryCluster>>();
      await tester.pumpWidget(app(stream.stream));
      stream.add([memory(1), memory(2)]);
      await tester.pump();
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FeedScreen)),
      );
      final initial = container
          .read(memoryFeedProvider)
          .map((m) => m.id)
          .toList();
      stream.add([
        memory(3),
        memory(2),
        memory(1, files: [50, 51]),
      ]);
      await tester.pump();
      await tester.pump();
      expect(container.read(memoryFeedProvider).map((m) => m.id), [
        ...initial,
        3,
      ]);
      expect(
        container.read(memoryFeedProvider).firstWhere((m) => m.id == 1).fileIds,
        [50, 51],
      );
      final closed = stream.close();
      await tester.pump();
      await closed;
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  for (final size in [const Size(320, 640), const Size(1200, 900)]) {
    testWidgets('responsive feed has no overflow at $size with enlarged text', (
      tester,
    ) async {
      tester.view.reset();
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: const TextScaler.linear(1.8),
          ),
          child: app(
            Stream.value(List.generate(6, (i) => memory(i + 1))),
            textScale: 1.8,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('v2:day:6')),
        400,
        scrollable: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(tester.takeException(), isNull);
      expect(find.byType(MemoryCard), findsWidgets);
      if (size.width > 1000) {
        final cards = tester
            .widgetList<MemoryCard>(find.byType(MemoryCard))
            .toList();
        expect(cards.length, greaterThanOrEqualTo(2));
        final first = tester.getTopLeft(
          find.byKey(ValueKey(cards[0].memory.signature)),
        );
        final second = tester.getTopLeft(
          find.byKey(ValueKey(cards[1].memory.signature)),
        );
        expect(first.dy, second.dy);
        expect(second.dx, greaterThan(first.dx));
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
