import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:watchmark/app/theme.dart';
import 'package:watchmark/features/home/controllers/home_controller.dart';
import 'package:watchmark/features/home/widgets/continue_watching_card.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final continueWatchingAsync = ref.watch(continueWatchingStreamProvider);
    final statsAsync = ref.watch(homeStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'WatchMark',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Statistics',
            onPressed: () => context.push('/statistics'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Summary Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: statsAsync.maybeWhen(
                data: (stats) {
                  final hours = (stats.totalMinutesWatched / 60).toStringAsFixed(1);
                  return InkWell(
                    onTap: () => context.push('/statistics'),
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface(context),
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        border: Border.all(color: AppTheme.border(context)),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _StatItem(label: 'Watching', value: '${stats.watchingCount}')),
                          _Divider(),
                          Expanded(child: _StatItem(label: 'Paused', value: '${stats.pausedCount}')),
                          _Divider(),
                          Expanded(child: _StatItem(label: 'Watchlist', value: '${stats.watchlistCount}')),
                          _Divider(),
                          Expanded(child: _StatItem(label: 'Completed', value: '${stats.completedCount}')),
                          _Divider(),
                          Expanded(child: _StatItem(label: 'Tracked', value: '${hours}h')),
                        ],
                      ),
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 24),

            // Continue Watching Section Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Continue Watching',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            // Continue Watching Carousel or Empty state
            continueWatchingAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error loading in-progress media: $err', style: const TextStyle(color: Colors.red)),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                      decoration: BoxDecoration(
                        color: AppTheme.surface(context),
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        border: Border.all(color: AppTheme.border(context)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.movie_filter_rounded,
                              size: 32,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No titles in progress',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Search for movies or series to begin tracking your watch progress.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted(context),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => context.go('/search'),
                            icon: const Icon(Icons.search, size: 16),
                            label: const Text('Discover Titles'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: 235,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ContinueWatchingCard(
                        item: item,
                        onTap: () {
                          context.push(
                            '/title/${item.media.tmdbId}?type=${item.media.mediaType}',
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted(context)),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: 1,
      color: AppTheme.border(context),
    );
  }
}
