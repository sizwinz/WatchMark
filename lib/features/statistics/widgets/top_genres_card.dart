import 'package:flutter/material.dart';
import 'package:watchmark/app/theme.dart';
import 'package:watchmark/core/services/stats_service.dart';

class TopGenresCard extends StatelessWidget {
  final List<GenreStats> genres;

  const TopGenresCard({super.key, required this.genres});

  @override
  Widget build(BuildContext context) {
    if (genres.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.category_outlined, color: AppTheme.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Top Genres',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: genres.map((g) {
                final hours = g.minutes ~/ 60;
                final mins = g.minutes % 60;
                final timeLabel = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border(context)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        g.genreName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          timeLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
