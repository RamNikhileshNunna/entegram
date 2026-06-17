import 'package:entegram/src/db/models/ente_file.dart';
import 'package:entegram/src/db/models/memory_cluster.dart';
import 'package:entegram/src/providers.dart';
import 'package:entegram/src/ui/feed_screen.dart';
import 'package:entegram/src/ui/widgets/memory_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

MemoryCluster _memory(int i) => MemoryCluster()
  ..id = i
  ..signature = 'sig-$i'
  ..title = i == 0 ? 'You and Sam' : 'Memory $i'
  ..kind = MemoryKind.people
  ..startTime = 1690000000000000 + i * 1000000
  ..endTime = 1690000500000000 + i * 1000000
  ..personIds = const ['p1']
  ..fileIds = [i * 10, i * 10 + 1, i * 10 + 2]
  ..coverFileId = i * 10
  ..generatedAt = 0;

EnteFile _file(int id) => EnteFile()
  ..id = id
  ..collectionID = 1
  ..ownerID = 1
  ..fileType = 0
  ..creationTime = 1690000000000000 + id
  ..modificationTime = 0
  ..updationTime = 0;

void main() {
  testWidgets('feed renders memory cards from the stream', (tester) async {
    final memories = List.generate(8, _memory);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          thumbnailServiceProvider.overrideWithValue(null),
          memoriesProvider.overrideWith((ref) => Stream.value(memories)),
          memoryFilesProvider.overrideWith(
            (ref, id) async => [_file(id), _file(id + 1)],
          ),
          loadMoreProvider.overrideWithValue(() async => true),
        ],
        child: const MaterialApp(home: FeedScreen()),
      ),
    );
    // Can't pumpAndSettle: the footer spinner animates forever.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Entegram'), findsOneWidget);
    // The feed shuffles memories with a random seed, so any specific title
    // (e.g. memory 0's "You and Sam") lands at a non-deterministic scroll
    // position and may be off-screen. Asserting card presence is the reliable,
    // meaningful check that the stream rendered into the feed.
    expect(find.byType(MemoryCard), findsWidgets);
  });

  testWidgets('scrolling near the bottom triggers loadMore', (tester) async {
    final memories = List.generate(12, _memory);
    var loadMoreCalls = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          thumbnailServiceProvider.overrideWithValue(null),
          memoriesProvider.overrideWith((ref) => Stream.value(memories)),
          memoryFilesProvider.overrideWith(
            (ref, id) async => [_file(id), _file(id + 1)],
          ),
          loadMoreProvider.overrideWithValue(() async {
            loadMoreCalls++;
            return loadMoreCalls < 2; // report "no more" after the 2nd page
          }),
        ],
        child: const MaterialApp(home: FeedScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Drag (non-ballistic) past the bottom; clamps at maxScrollExtent, putting
    // us within 1000px of the end, which must trigger a fetch.
    await tester.drag(
      find.byType(CustomScrollView),
      const Offset(0, -20000),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(loadMoreCalls, greaterThan(0));
  });
}
