import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watchmark/core/services/stats_service.dart';
import 'package:watchmark/features/statistics/views/statistics_view.dart';

void main() {
  group('StatisticsView Widget Tests', () {
    testWidgets('Renders empty state placeholder when totalSessions is 0', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            viewingStatsStreamProvider.overrideWith((ref) => Stream.value(const ViewingStats())),
          ],
          child: const MaterialApp(
            home: StatisticsView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Viewing Analytics'), findsOneWidget);
      expect(find.text('No Viewing Activity Yet'), findsOneWidget);
    });

    testWidgets('Renders watch time card, platform bars, and monthly chart when data exists', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const dummyStats = ViewingStats(
        totalMinutes: 185,
        moviesMinutes: 120,
        episodesMinutes: 65,
        totalSessions: 3,
        monthlyBreakdown: [
          MonthlyStats(monthKey: '2026-08', monthLabel: 'Aug', minutes: 185, relativePercentage: 1.0),
        ],
        platformBreakdown: [
          PlatformStats(platformId: 'netflix', displayName: 'Netflix', colorValue: 0xFFE50914, minutes: 120, percentage: 64.9),
          PlatformStats(platformId: 'prime', displayName: 'Prime Video', colorValue: 0xFF00A8E1, minutes: 65, percentage: 35.1),
        ],
        topGenres: [
          GenreStats(genreName: 'Sci-Fi', minutes: 185, count: 3),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            viewingStatsStreamProvider.overrideWith((ref) => Stream.value(dummyStats)),
          ],
          child: const MaterialApp(
            home: StatisticsView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Total Watch Time'), findsOneWidget);
      expect(find.text('3 h 5 m'), findsOneWidget);
      expect(find.text('2 h 0 m'), findsOneWidget); // Movies
      expect(find.text('1 h 5 m'), findsOneWidget); // Series
      expect(find.text('Streaming Platforms'), findsOneWidget);
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('Prime Video'), findsOneWidget);
      expect(find.text('Monthly Activity (Last 6 Months)'), findsOneWidget);
      expect(find.text('Top Genres'), findsOneWidget);
      expect(find.text('Sci-Fi'), findsOneWidget);
    });
  });
}
