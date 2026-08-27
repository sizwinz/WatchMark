import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:watchmark/app/theme.dart';
import 'package:watchmark/features/watch_history/controllers/history_controller.dart';
import 'package:watchmark/features/watch_history/widgets/history_session_tile.dart';

class HistoryView extends ConsumerWidget {
  const HistoryView({super.key});

  String _formatTotalMinutes(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyGroupsAsync = ref.watch(groupedHistoryStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch History'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: historyGroupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Failed to load history: $err', style: const TextStyle(color: Colors.red)),
        ),
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_outlined,
                      size: 64,
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No watch history yet',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'As you update watch progress on movies and episodes, your viewing history will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textMuted(context)),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: groups.length,
            itemBuilder: (context, gIndex) {
              final group = groups[gIndex];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          group.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                        Text(
                          _formatTotalMinutes(group.totalMinutes),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...group.items.map((item) {
                    return HistorySessionTile(
                      item: item,
                      onTap: () {
                        final tmdbId = int.tryParse(item.media.tmdbId) ?? 0;
                        context.push('/title/$tmdbId?type=${item.media.mediaType}');
                      },
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
