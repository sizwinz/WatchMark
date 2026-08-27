import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchmark/app/theme.dart';
import 'package:watchmark/core/services/stats_service.dart';
import 'package:watchmark/features/statistics/widgets/monthly_breakdown_card.dart';
import 'package:watchmark/features/statistics/widgets/platform_distribution_card.dart';
import 'package:watchmark/features/statistics/widgets/top_genres_card.dart';
import 'package:watchmark/features/statistics/widgets/watch_time_card.dart';

class StatisticsView extends ConsumerWidget {
  const StatisticsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(viewingStatsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Viewing Analytics'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: statsAsync.when(
        data: (stats) {
          if (stats.totalSessions == 0) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.insights_outlined,
                      size: 64,
                      color: AppTheme.primary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Viewing Activity Yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'As you update watch progress and log sessions across movies and episodes, your viewing analytics, streaming distribution, and monthly charts will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted(context)),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              WatchTimeCard(stats: stats),
              const SizedBox(height: 16),
              MonthlyBreakdownCard(monthlyStats: stats.monthlyBreakdown),
              const SizedBox(height: 16),
              PlatformDistributionCard(platforms: stats.platformBreakdown),
              const SizedBox(height: 16),
              TopGenresCard(genres: stats.topGenres),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Failed to compute statistics: $err'),
        ),
      ),
    );
  }
}
