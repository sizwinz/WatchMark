import 'package:flutter/material.dart';
import 'package:watchmark/app/theme.dart';
import 'package:watchmark/core/services/stats_service.dart';

class MonthlyBreakdownCard extends StatelessWidget {
  final List<MonthlyStats> monthlyStats;

  const MonthlyBreakdownCard({super.key, required this.monthlyStats});

  @override
  Widget build(BuildContext context) {
    if (monthlyStats.isEmpty) {
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
                Icon(Icons.bar_chart, color: AppTheme.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Monthly Activity (Last 6 Months)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: monthlyStats.map((m) {
                  final hours = (m.minutes / 60).toStringAsFixed(1);
                  final barHeight = (m.relativePercentage * 90).clamp(6.0, 90.0);

                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          m.minutes > 0 ? '${hours}h' : '0',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textMuted(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: barHeight,
                          width: 18,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: m.relativePercentage > 0.8
                                  ? [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.6)]
                                  : [AppTheme.primaryDark, AppTheme.primaryDark.withValues(alpha: 0.4)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          m.monthLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
