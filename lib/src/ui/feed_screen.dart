import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/models/memory_cluster.dart';
import '../memories/memory_catalog.dart';
import '../providers.dart';
import 'widgets/memory_card.dart';
import 'widgets/stories_bar.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});
  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scroll = ScrollController();
  bool _fetching = false;
  bool _signingOut = false;
  bool _hasMore = true;
  String? _pageError;
  String _filter = 'For you';
  int _fillAttempts = 0;
  static const _filters = [
    'For you',
    'On this day',
    'People',
    'Places',
    'Yearbooks',
  ];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.hasClients && _scroll.position.extentAfter < 900) _loadMore();
  }

  Future<void> _loadMore() async {
    if (_fetching || !_hasMore || _pageError != null) return;
    setState(() => _fetching = true);
    try {
      final more = await ref.read(loadMoreProvider)();
      if (mounted) setState(() => _hasMore = more);
    } catch (_) {
      if (mounted) setState(() => _pageError = 'Could not load more memories');
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _hasMore = true;
      _pageError = null;
      _fillAttempts = 0;
    });
    try {
      ref.invalidate(bootstrapProvider);
      await ref.read(bootstrapProvider.future);
      if (mounted) ref.read(memoryFeedProvider.notifier).reorder();
    } catch (_) {
      /* bootstrap's AsyncError is shown inline; retain cached cards. */
    }
  }

  bool _matches(MemoryCluster m) => switch (_filter) {
    'On this day' =>
      m.category == MemoryCategory.onThisDay ||
          m.category == MemoryCategory.flashback,
    'People' => m.category == MemoryCategory.people,
    'Places' => m.category == MemoryCategory.trip,
    'Yearbooks' =>
      m.category == MemoryCategory.year || m.category == MemoryCategory.season,
    _ => true,
  };

  @override
  Widget build(BuildContext context) {
    final source = ref.watch(memoriesProvider);
    final memories = ref.watch(memoryFeedProvider).where(_matches).toList();
    final bootstrap = ref.watch(bootstrapProvider);
    final width = MediaQuery.sizeOf(context).width;
    final padding = width < 600 ? 12.0 : 28.0;
    final inset = (width - 1120).clamp(0, double.infinity) / 2 + padding;
    final columns = width - inset * 2 >= 780 ? 2 : 1;
    // A few pages can fill a sparse first viewport; never busy-loop on a
    // library that has no suitable memories. Manual load/retry stays available.
    if (memories.isNotEmpty &&
        _fillAttempts < 3 &&
        _hasMore &&
        !_fetching &&
        _pageError == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            !_scroll.hasClients ||
            _scroll.position.maxScrollExtent > 500) {
          return;
        }
        _fillAttempts++;
        _loadMore();
      });
    }
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),

            slivers: [
              SliverAppBar(
                pinned: true,
                title: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_vintage_outlined,
                      color: Color(0xFFA5D9BC),
                    ),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Entegram',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    tooltip: 'Refresh memories',
                    onPressed: bootstrap.isLoading ? null : _refresh,
                    icon: const Icon(Icons.sync_rounded),
                  ),
                  IconButton(
                    tooltip: 'Sign out',
                    onPressed: _signingOut ? null : _signOut,
                    icon: const Icon(Icons.logout_rounded),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(inset + 4, 24, inset + 4, 20),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A little closer to yesterday.',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.8,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The people, places and moments worth another look.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: inset),
                sliver: const SliverToBoxAdapter(child: StoriesBar()),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(inset + 4, 24, inset + 4, 12),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Your memories',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 54,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: inset + 4),
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ChoiceChip(
                      label: Text(_filters[i]),
                      selected: _filter == _filters[i],
                      onSelected: (_) => setState(() {
                        _filter = _filters[i];
                        _fillAttempts = 0;
                      }),
                    ),
                  ),
                ),
              ),
              if (bootstrap.hasError && memories.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: inset),
                    child: _Message(
                      'You’re viewing saved memories. Sync is unavailable.',
                      action: _refresh,
                      actionLabel: 'Retry sync',
                    ),
                  ),
                ),
              if (memories.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: source.isLoading || bootstrap.isLoading
                          ? const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Finding your memories…'),
                              ],
                            )
                          : _Message(
                              source.hasError || bootstrap.hasError
                                  ? 'Your library could not be synced.'
                                  : _filter == 'For you'
                                  ? 'Your memories start here. Sync your library to rediscover your photos.'
                                  : 'No memories in this collection yet.',
                              action: _refresh,
                              actionLabel: 'Sync library',
                            ),
                    ),
                  ),
                )
              else ...[
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(inset, 8, inset, 0),
                  sliver: SliverList.builder(
                    itemCount: (memories.length / columns).ceil(),
                    itemBuilder: (_, row) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var col = 0; col < columns; col++) ...[
                            if (col > 0) const SizedBox(width: 20),
                            Expanded(
                              child: row * columns + col < memories.length
                                  ? MemoryCard(
                                      key: ValueKey(
                                        memories[row * columns + col].signature,
                                      ),
                                      memory: memories[row * columns + col],
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(inset, 8, inset, 40),
                    child: _fetching
                        ? const Center(child: CircularProgressIndicator())
                        : _pageError != null
                        ? _Message(
                            _pageError!,
                            actionLabel: 'Try again',
                            action: () {
                              setState(() => _pageError = null);
                              return _loadMore();
                            },
                          )
                        : _hasMore
                        ? Center(
                            child: TextButton.icon(
                              onPressed: _loadMore,
                              icon: const Icon(Icons.add),
                              label: const Text('Discover more memories'),
                            ),
                          )
                        : const _Message(
                            'You’re all caught up. There’s more to remember tomorrow.',
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Your locally synced library will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _signingOut = true);
      try {
        await ref.read(sessionProvider.notifier).logout();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Local cleanup could not be completed.'),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _signingOut = false);
      }
    }
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.action, this.actionLabel});
  final String text;
  final Future<void> Function()? action;
  final String? actionLabel;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      if (action != null)
        TextButton(onPressed: action, child: Text(actionLabel!)),
    ],
  );
}
