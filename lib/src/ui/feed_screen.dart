import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/models/memory_cluster.dart';
import '../providers.dart';
import 'widgets/memory_card.dart';
import 'widgets/stories_bar.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  static const double _prefetchExtent = 1200;

  final _scroll = ScrollController();

  /// Full pool from the DB — updated whenever memoriesProvider fires.
  List<MemoryCluster> _pool = [];

  /// Signatures currently represented in [_pool], to detect when the *set* of
  /// memories (not just their Isar IDs) actually changed.
  Set<String> _poolSigs = {};

  /// Growing display list (interleaved copies of the pool, appended on demand).
  final List<MemoryCluster> _display = [];

  /// Length of one interleaved copy of the pool, used to preserve the number of
  /// recycled copies (and thus scroll position) across pool updates.
  int _baseLen = 0;

  /// Fresh each app launch → the feed is shuffled differently every cold start.
  /// Stable within a session, so background-sync rebuilds don't reshuffle.
  final int _seed = Random().nextInt(1 << 30);

  /// True while a server fetch or recycle append is in flight.
  bool _fetching = false;

  /// False once the server confirms there are no more file pages to load.
  bool _serverHasMore = true;

  /// Prevents the scroll listener from firing another recycle immediately
  /// after an append (the layout metric change re-fires the listener before
  /// the user has actually scrolled further).
  bool _justAppended = false;

  /// Hard cap on accumulated feed items for memory safety. The feed recycles
  /// shuffled batches up to this — effectively infinite for any real session.
  static const int _maxDisplay = 5000;

  /// Scrollable height seen during the current eager-fill pass. Guards against
  /// a pathological pool (e.g. everything collapsed to zero height) appending
  /// forever: if a fill doesn't grow the scroll area, we stop.
  double _lastFillExtent = -1;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  // Called whenever memoriesProvider emits a new list.
  void _onPoolUpdate(List<MemoryCluster> memories) {
    final sigs = memories.map((m) => m.signature).toSet();
    final sameSet =
        sigs.length == _poolSigs.length && sigs.containsAll(_poolSigs);
    _pool = memories;

    if (memories.isEmpty) {
      setState(() => _display.clear());
      return;
    }

    if (sameSet && _display.isNotEmpty) {
      // The mapper rebuilt (new Isar IDs) but the *set* of memories is
      // unchanged. Swap each displayed card to its new cluster object in place
      // so IDs stay valid — no reorder, no scroll jump, no flicker.
      final bySig = {for (final m in memories) m.signature: m};
      for (var i = 0; i < _display.length; i++) {
        final updated = bySig[_display[i].signature];
        if (updated != null) _display[i] = updated;
      }
      setState(() {});
      return;
    }

    // The set of memories changed (e.g. background sync discovered older photos
    // and generated "Summer 2022" / "2 years ago this month"). Re-interleave
    // the whole pool so the new memories actually appear, preserving how many
    // recycled copies were on screen so scroll position is roughly kept.
    _poolSigs = sigs;
    final base = _interleave(memories);
    final copies = _baseLen > 0
        ? (_display.length / _baseLen).round().clamp(1, 50)
        : 1;
    _baseLen = base.length;
    setState(() {
      _display.clear();
      for (var i = 0; i < copies; i++) {
        _display.addAll(base);
      }
    });
    _lastFillExtent = -1;
    _ensureViewportFilled();
  }

  /// One interleaved copy of the pool: each kind shuffled, then round-robined
  /// across kinds so people, on-this-day and trip/season/year cards alternate
  /// instead of one type flooding.
  ///
  /// Ordering is a *stable hash* of (signature, [_seed]) rather than a plain
  /// shuffle: random per launch (since [_seed] changes), yet a given memory
  /// keeps its position when others are added mid-session — so background sync
  /// slots new memories in without reshuffling what's on screen.
  List<MemoryCluster> _interleave(List<MemoryCluster> pool) {
    final byKind = <MemoryKind, List<MemoryCluster>>{};
    for (final m in pool) {
      byKind.putIfAbsent(m.kind, () => []).add(m);
    }
    for (final list in byKind.values) {
      list.sort((a, b) =>
          Object.hash(a.signature, _seed).compareTo(Object.hash(b.signature, _seed)));
    }
    final kinds = byKind.keys.toList()
      ..sort((a, b) => Object.hash(a, _seed).compareTo(Object.hash(b, _seed)));
    final iters = [for (final k in kinds) byKind[k]!.iterator];
    final out = <MemoryCluster>[];
    var any = true;
    while (any) {
      any = false;
      for (final it in iters) {
        if (it.moveNext()) {
          out.add(it.current);
          any = true;
        }
      }
    }
    return out;
  }

  /// Keeps the feed scrollable. Growth comes from recycling the *current* pool
  /// (instant, always works) — never gated on the server — so the feed is never
  /// stuck "loading" with no new cards. Server paging happens separately, in
  /// the background, to discover more memories.
  void _ensureViewportFilled() {
    if (_pool.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final pos = _scroll.position;
      if (pos.maxScrollExtent >= pos.viewportDimension * 1.5) return;
      if (_display.length >= _maxDisplay) return;
      // Runaway guard: stop if the previous fill didn't grow the scroll area.
      if (pos.maxScrollExtent <= _lastFillExtent) return;
      _lastFillExtent = pos.maxScrollExtent;
      _appendBatch();
      _fetchServerMore();
      _ensureViewportFilled(); // chain until comfortably filled
    });
  }

  // Append one more interleaved copy of the pool to _display (recycle for the
  // never-ending feed).
  void _appendBatch() {
    if (_pool.isEmpty) return;
    final base = _interleave(_pool);
    _baseLen = base.length;
    setState(() => _display.addAll(base));
    _justAppended = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _justAppended = false);
  }

  void _onScroll() {
    if (!_scroll.hasClients || _justAppended) return;
    final remaining =
        _scroll.position.maxScrollExtent - _scroll.position.pixels;
    if (remaining <= _prefetchExtent) {
      if (_display.length < _maxDisplay) _appendBatch(); // grow now (recycle)
      _fetchServerMore(); // discover more in the background
    }
  }

  /// Pages the server for more files in the background to discover new
  /// memories. Independent of feed growth — the feed never waits on this.
  Future<void> _fetchServerMore() async {
    if (_fetching || !_serverHasMore) return;
    _fetching = true;
    try {
      final hasMore = await ref.read(loadMoreProvider)();
      if (mounted) setState(() => _serverHasMore = hasMore);
    } finally {
      _fetching = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final memoriesAsync = ref.watch(memoriesProvider);
    final bootstrap = ref.watch(bootstrapProvider);

    // Keep _pool in sync with the DB stream; seed _display on first data.
    ref.listen<AsyncValue<List<MemoryCluster>>>(memoriesProvider, (_, next) {
      next.whenData(_onPoolUpdate);
    });

    return Scaffold(
      body: RefreshIndicator(
        color: const Color.fromRGBO(29, 185, 84, 1),
        onRefresh: () => ref.refresh(bootstrapProvider.future),
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              title: GestureDetector(
                onTap: () {
                  if (_scroll.hasClients) {
                    _scroll.animateTo(
                      0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(29, 185, 84, 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color.fromRGBO(29, 185, 84, 0.5),
                        ),
                      ),
                      child: const Icon(
                        Icons.photo_library_outlined,
                        size: 16,
                        color: Color.fromRGBO(29, 185, 84, 1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Entegram',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Sign out',
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Sign out?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Sign out'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true && context.mounted) {
                      ref.read(sessionProvider.notifier).logout();
                    }
                  },
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
            const SliverToBoxAdapter(child: StoriesBar()),
            const SliverToBoxAdapter(child: Divider(height: 1)),
            ..._buildBody(memoriesAsync, bootstrap),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBody(
    AsyncValue<List<MemoryCluster>> memoriesAsync,
    AsyncValue<void> bootstrap,
  ) {
    // While the provider is loading and we have nothing to show yet, spinner.
    if (memoriesAsync.isLoading && _display.isEmpty) {
      return [const _FullSpinner()];
    }
    if (memoriesAsync.hasError && _display.isEmpty) {
      return [_FullMessage('Error: ${memoriesAsync.error}')];
    }

    if (_display.isEmpty) {
      return [
        bootstrap.isLoading
            ? const _FullSpinner(label: 'Syncing your memories…')
            : bootstrap.hasError
            ? _FullMessage('Sync failed: ${bootstrap.error}')
            : const _EmptyState(),
      ];
    }

    return [
      SliverList.separated(
        itemCount: _display.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) => MemoryCard(memory: _display[i]),
      ),
      // Show spinner only while the server still has pages to load.
      // Once exhausted the feed recycles silently — no spinner needed.
      if (_serverHasMore)
        const SliverToBoxAdapter(child: _BottomSpinner()),
    ];
  }
}

// ---------------------------------------------------------------------------
// Shared helper widgets
// ---------------------------------------------------------------------------

class _FullSpinner extends StatelessWidget {
  const _FullSpinner({this.label});
  final String? label;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Color.fromRGBO(29, 185, 84, 1),
            ),
            if (label != null) ...[
              const SizedBox(height: 16),
              Text(label!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _FullMessage extends StatelessWidget {
  const _FullMessage(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(29, 185, 84, 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.photo_library_outlined,
                size: 40,
                color: Color.fromRGBO(29, 185, 84, 0.6),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No memories yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pull down to sync your Ente library',
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomSpinner extends StatelessWidget {
  const _BottomSpinner();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color.fromRGBO(29, 185, 84, 1),
          ),
        ),
      ),
    );
  }
}
