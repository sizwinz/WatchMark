import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchmark/features/search/controllers/search_controller.dart';

class RecentSearchChips extends ConsumerWidget {
  const RecentSearchChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentQueries = ref.watch(
      searchControllerProvider.select((s) => s.recentQueries),
    );

    if (recentQueries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Searches',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                ref.read(searchControllerProvider.notifier).clearRecentQueries();
              },
              child: const Text('Clear all', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: recentQueries.map((query) {
            return InputChip(
              label: Text(query),
              onPressed: () {
                ref.read(searchControllerProvider.notifier).selectRecentQuery(query);
              },
              onDeleted: () {
                ref.read(searchControllerProvider.notifier).removeRecentQuery(query);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
