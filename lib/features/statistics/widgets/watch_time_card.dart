import 'package:flutter/material.dart';
import 'package:watchmark/app/theme.dart';
import 'package:watchmark/core/services/stats_service.dart';

class WatchTimeCard extends StatelessWidget {
  final ViewingStats stats;

  const WatchTimeCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.timer_outlined, color: AppTheme.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Total Watch Time',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              stats.formattedTotalTime,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.movie_outlined, size: 14, color: AppTheme.primary),
                            const SizedBox(width: 6),
                            Text('Movies', style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stats.formattedMoviesTime,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.tv_outlined, size: 14, color: AppTheme.primaryDark),
                            const SizedBox(width: 6),
                            Text('Series', style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stats.formattedEpisodesTime,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
