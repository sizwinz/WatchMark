import 'package:flutter/material.dart';
import 'package:watchmark/app/theme.dart';
import 'package:watchmark/core/services/stats_service.dart';

class PlatformDistributionCard extends StatelessWidget {
  final List<PlatformStats> platforms;

  const PlatformDistributionCard({super.key, required this.platforms});

  @override
  Widget build(BuildContext context) {
    if (platforms.isEmpty) {
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
                Icon(Icons.pie_chart_outline, color: AppTheme.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Streaming Platforms',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Multi-segment progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: platforms.map((p) {
                    final flex = (p.percentage * 10).round().clamp(1, 1000);
                    return Expanded(
                      flex: flex,
                      child: Container(
                        color: Color(p.colorValue),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Platform legend list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: platforms.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final p = platforms[index];
                final hours = p.minutes ~/ 60;
                final mins = p.minutes % 60;
                final timeStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

                return Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Color(p.colorValue),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.displayName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      timeStr,
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context)),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated(context),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${p.percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
