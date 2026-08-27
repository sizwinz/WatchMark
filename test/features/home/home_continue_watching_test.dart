import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watchmark/core/database/app_database.dart';
import 'package:watchmark/features/home/controllers/home_controller.dart';
import 'package:watchmark/features/home/views/home_view.dart';
import 'package:watchmark/features/home/widgets/continue_watching_card.dart';

void main() {
  group('HomeView & ContinueWatchingCard Widget Tests', () {
    testWidgets('ContinueWatchingCard renders media title, progress percentage and +15m button', (tester) async {
      final item = ContinueWatchingItem(
        entry: LibraryEntry(
          id: 'entry-1',
          mediaId: 'm-1',
          status: 'watching',
          progressSeconds: 1800,
          currentSeason: 1,
          currentEpisode: 2,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        media: MediaTitle(
          id: 'm-1',
          tmdbId: '100',
          mediaType: 'tv',
          title: 'Stranger Things',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        currentEpisode: Episode(
          id: 'ep-2',
          seasonId: 's-1',
          mediaId: 'm-1',
          episodeNumber: 2,
          title: 'The Weirdo on Maple Street',
          runtimeMinutes: 55,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        totalRuntimeSeconds: 3300,
        progressPercentage: 54,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ContinueWatchingCard(
                item: item,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Stranger Things'), findsOneWidget);
      expect(find.text('S1:E2 • The Weirdo on Maple Street'), findsOneWidget);
      expect(find.text('30m / 55m (54%)'), findsOneWidget);
      expect(find.text('+15m'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('HomeView renders empty state when no items in progress', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            continueWatchingStreamProvider.overrideWith((ref) => Stream.value([])),
            homeStatsProvider.overrideWith((ref) => Stream.value(const HomeStats())),
            homeTrendingProvider.overrideWith((ref) => Future.value([])),
            homeRecentActivityProvider.overrideWith((ref) => Stream.value([])),
            homeWatchlistProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: HomeView(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('WatchMark'), findsOneWidget);
      expect(find.text('Continue Watching'), findsOneWidget);
      expect(find.text('No titles in progress'), findsOneWidget);
      expect(find.text('Discover Titles'), findsOneWidget);
    });

    testWidgets('HomeView renders summary with Paused count and in-progress items', (tester) async {
      final pausedItem = ContinueWatchingItem(
        entry: LibraryEntry(
          id: 'entry-p',
          mediaId: 'm-p',
          status: 'paused',
          progressSeconds: 3600,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        media: MediaTitle(
          id: 'm-p',
          tmdbId: '500',
          mediaType: 'movie',
          title: 'Avengers: Doomsday',
          runtimeMinutes: 165,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        totalRuntimeSeconds: 165 * 60,
        progressPercentage: 36,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            continueWatchingStreamProvider.overrideWith((ref) => Stream.value([pausedItem])),
            homeStatsProvider.overrideWith((ref) => Stream.value(const HomeStats(
              watchingCount: 0,
              pausedCount: 1,
              watchlistCount: 2,
              completedCount: 5,
              totalMinutesWatched: 120,
            ))),
            homeTrendingProvider.overrideWith((ref) => Future.value([])),
            homeRecentActivityProvider.overrideWith((ref) => Stream.value([])),
            homeWatchlistProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: HomeView(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Avengers: Doomsday'), findsOneWidget);
      expect(find.text('Paused'), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // paused count
    });
  });
}
