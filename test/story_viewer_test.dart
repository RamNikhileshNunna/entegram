import 'package:entegram/src/providers.dart';
import 'package:entegram/src/ui/widgets/story_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fixtures.dart';
import 'test_image.dart';

void main() {
  late SharedPreferences preferences;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });
  Widget app({double textScale = 1, bool accessible = false}) => ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      fullResServiceProvider.overrideWithValue(null),
      thumbnailServiceProvider.overrideWithValue(null),
      storyThumbnailLoaderProvider.overrideWithValue((_) async => testImage),
      memoryFilesProvider.overrideWith(
        (_, id) => Stream.value([
          photo(id * 10, DateTime(2020, 1, 1)),
          photo(id * 10 + 1, DateTime(2020, 1, 2)),
        ]),
      ),
    ],
    child: MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          accessibleNavigation: accessible,
        ),
        child: child!,
      ),
      home: StoryViewer(memories: [memory(1), memory(2)]),
    ),
  );
  Future<void> ready(WidgetTester tester) async {
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  }

  testWidgets('a navigation button advances exactly once', (tester) async {
    await ready(tester);
    await tester.tap(find.byTooltip('Next moment'));
    await tester.pump();
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('holding pauses without advancing on release; a tap advances', (
    tester,
  ) async {
    await ready(tester);
    final center = tester.getCenter(find.byType(StoryMedia));
    final gesture = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 700));
    await gesture.up(timeStamp: const Duration(milliseconds: 700));
    await tester.pump();
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.tapAt(center);
    await tester.pump();
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('explicit pause freezes the clock and play resumes it', (
    tester,
  ) async {
    await ready(tester);
    await tester.tap(find.byTooltip('Pause story'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.tap(find.byTooltip('Play story'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    await tester.pump();
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('backgrounding freezes playback until the app resumes', (
    tester,
  ) async {
    await ready(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('1 / 2'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    await tester.pump();
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final size in [const Size(320, 480), const Size(640, 320)]) {
    testWidgets('story controls remain usable at $size with large text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(app(textScale: 1.8));
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Close story'), findsOneWidget);
      expect(find.byTooltip('View original'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets(
    'screen-reader navigation starts paused and requires explicit play',
    (tester) async {
      await tester.pumpWidget(app(accessible: true));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 40)),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 6));
      expect(find.text('1 / 2'), findsOneWidget);
      expect(find.byTooltip('Play story'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
