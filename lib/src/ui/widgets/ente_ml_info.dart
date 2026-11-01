import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ml/semantic_sync.dart';
import '../../providers.dart';

class EnteMlInfo extends ConsumerWidget {
  const EnteMlInfo({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coverage = ref.watch(semanticCoverageProvider).value;
    final state = ref.watch(semanticSyncStateProvider);
    final message = switch (state) {
      SemanticSyncState.unavailable =>
        'This server does not provide compatible Ente ML data. Your other memories are still available.',
      SemanticSyncState.error =>
        'Ente ML could not be updated. Pull down to retry.',
      _ when coverage != null && coverage.indexed > 0 =>
        'Ente ML is ready for ${coverage.indexed} of ${coverage.total} photos. Visual themes can be approximate.',
      _ when state == SemanticSyncState.syncing =>
        'Syncing Ente’s visual search results. Photo themes will appear as they are ready.',
      _ =>
        'No compatible Ente ML results have synced yet. Enable machine learning in Ente Photos and let it index and sync your library.',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_outlined, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
