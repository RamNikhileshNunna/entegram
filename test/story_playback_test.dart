import 'dart:async';
import 'package:entegram/src/memories/story_playback.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fixtures.dart';

void main() {
  final now = DateTime(2020, 1, 1);
  test(
    'navigation crosses boundaries and previous lands on the last slide',
    () async {
      final playback = StoryPlayback(
        memories: [memory(1), memory(2)],
        loadFiles: (m) async => m.fileIds.map((id) => photo(id, now)).toList(),
      );
      addTearDown(playback.dispose);
      await playback.start();
      expect(playback.file!.id, 10);
      await playback.next();
      expect(playback.file!.id, 11);
      await playback.next();
      expect(playback.file!.id, 20);
      await playback.previous();
      expect(playback.file!.id, 11);
    },
  );
  test('late loads cannot replace a more recently navigated memory', () async {
    final first = Completer<List<dynamic>>();
    final playback = StoryPlayback(
      memories: [memory(1), memory(2)],
      loadFiles: (m) async {
        if (m.id == 1) return (await first.future).cast();
        return [photo(20, now)];
      },
    );
    addTearDown(playback.dispose);
    final opening = playback.start();
    await playback.nextMemory();
    first.complete([photo(10, now)]);
    await opening;
    expect(playback.memory!.id, 2);
    expect(playback.file!.id, 20);
  });
  test('empty and deleted memories are skipped without recursion', () async {
    final playback = StoryPlayback(
      memories: List.generate(150, (i) => memory(i + 1)),
      loadFiles: (m) async => m.id == 150 ? [photo(1, now)] : [],
    );
    addTearDown(playback.dispose);
    await playback.start();
    expect(playback.memory!.id, 150);
    await playback.next();
    expect(playback.finished, isTrue);
  });
  test(
    'load failures are retryable and dispose invalidates in-flight results',
    () async {
      var fail = true;
      final pending = Completer<List<dynamic>>();
      final playback = StoryPlayback(
        memories: [memory(1)],
        loadFiles: (_) async {
          if (fail) throw StateError('offline');
          return (await pending.future).cast();
        },
      );
      await playback.start();
      expect(playback.error, isNotNull);
      expect(playback.loading, isFalse);
      fail = false;
      final retry = playback.retry();
      playback.dispose();
      pending.complete([photo(10, now)]);
      await retry; // no notify after disposal
    },
  );
  test(
    'completion marks seen only after the full memory, not a bundle swipe',
    () async {
      final completed = <int>[];
      final playback = StoryPlayback(
        memories: [memory(1), memory(2)],
        loadFiles: (m) async => m.fileIds.map((id) => photo(id, now)).toList(),
        onCompleted: (m) => completed.add(m.id),
      );
      addTearDown(playback.dispose);
      await playback.start();
      await playback.nextMemory();
      expect(completed, isEmpty);
      await playback.next();
      await playback.next();
      expect(completed, [2]);
      expect(playback.finished, isTrue);
    },
  );
}
