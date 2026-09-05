import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watchmark/core/database/app_database.dart';
import 'package:watchmark/core/network/tmdb_api_service.dart';
import 'package:watchmark/features/title_details/widgets/cast_list.dart';
import 'package:watchmark/features/title_details/widgets/hero_backdrop.dart';
import 'package:watchmark/features/title_details/widgets/season_tab_view.dart';
import 'package:watchmark/features/title_details/widgets/status_selector_button.dart';

void main() {
  group('TitleDetails Widget Tests', () {
    testWidgets('HeroBackdrop displays movie title, year and runtime', (tester) async {
      const detail = TmdbMediaDetail(
        id: 550,
        mediaType: 'movie',
        title: 'Fight Club',
        releaseDate: '1999-10-15',
        runtimeMinutes: 139,
        voteAverage: 8.4,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HeroBackdrop(detail: detail),
            ),
          ),
        ),
      );

      expect(find.text('Fight Club'), findsOneWidget);
      expect(find.text('MOVIE'), findsOneWidget);
      expect(find.text('1999'), findsOneWidget);
      expect(find.text('• 2h 19m'), findsOneWidget);
      expect(find.text('8.4 / 10'), findsOneWidget);
    });

    testWidgets('CastList renders cast avatars', (tester) async {
      const cast = [
        TmdbCastMember(id: 1, name: 'Brad Pitt', character: 'Tyler Durden'),
        TmdbCastMember(id: 2, name: 'Edward Norton', character: 'The Narrator'),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CastList(cast: cast),
          ),
        ),
      );

      expect(find.text('Cast & Crew'), findsOneWidget);
      expect(find.text('Brad Pitt'), findsOneWidget);
      expect(find.text('Tyler Durden'), findsOneWidget);
      expect(find.text('Edward Norton'), findsOneWidget);
    });

    testWidgets('SeasonTabView renders season chips', (tester) async {
      const seasons = [
        TmdbSeasonSummary(id: 10, seasonNumber: 1, name: 'Season 1', episodeCount: 10),
        TmdbSeasonSummary(id: 11, seasonNumber: 2, name: 'Season 2', episodeCount: 10),
      ];

      int selectedSeason = 1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SeasonTabView(
                mediaId: 'tv-1',
                seasons: seasons,
                selectedSeasonNumber: selectedSeason,
                episodes: const [],
                isLoadingSeason: false,
                onSeasonSelected: (seasonNum) => selectedSeason = seasonNum,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Seasons & Episodes'), findsOneWidget);
      expect(find.text('Season 1'), findsOneWidget);
      expect(find.text('Season 2'), findsOneWidget);
    });

    testWidgets('StatusSelectorButton shows Add to Library and opens bottom sheet', (tester) async {
      String? selectedStatus;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusSelectorButton(
              libraryEntry: null,
              onStatusSelected: (status) => selectedStatus = status,
              onRemove: () {},
            ),
          ),
        ),
      );

      expect(find.text('Add to Library'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Update Watch Status'), findsOneWidget);
      expect(find.text('Watchlist'), findsOneWidget);
      expect(find.text('Watching'), findsOneWidget);

      await tester.tap(find.text('Watching'));
      await tester.pumpAndSettle();

      expect(selectedStatus, 'watching');
    });

    testWidgets('SeasonTabView displays watched checkmarks and active WATCHING badge on episodes', (tester) async {
      const seasons = [
        TmdbSeasonSummary(id: 10, seasonNumber: 1, name: 'Season 1', episodeCount: 3),
      ];

      final episodes = [
        Episode(
          id: 'ep-1',
          seasonId: 's-1',
          mediaId: 'tv-1',
          episodeNumber: 1,
          title: 'Winter Is Coming',
          runtimeMinutes: 60,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Episode(
          id: 'ep-2',
          seasonId: 's-1',
          mediaId: 'tv-1',
          episodeNumber: 2,
          title: 'The Kingsroad',
          runtimeMinutes: 55,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Episode(
          id: 'ep-3',
          seasonId: 's-1',
          mediaId: 'tv-1',
          episodeNumber: 3,
          title: 'Lord Snow',
          runtimeMinutes: 58,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      int? markedSeason;
      int? markedEpisode;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SeasonTabView(
                mediaId: 'tv-1',
                seasons: seasons,
                selectedSeasonNumber: 1,
                episodes: episodes,
                isLoadingSeason: false,
                currentSeason: 1,
                currentEpisode: 2,
                currentProgressSeconds: 1200,
                onSeasonSelected: (_) {},
                onMarkEpisodeWatched: (seasonNum, epNum) {
                  markedSeason = seasonNum;
                  markedEpisode = epNum;
                },
              ),
            ),
          ),
        ),
      );

      // Episode 1 should be watched (< currentEpisode 2)
      expect(find.text('1. Winter Is Coming'), findsOneWidget);
      // Episode 2 should be active with WATCHING badge
      expect(find.text('2. The Kingsroad'), findsOneWidget);
      expect(find.text('WATCHING'), findsOneWidget);
      expect(find.text('• 20m watched (36%)'), findsOneWidget);
      // Episode 3 should be unwatched
      expect(find.text('3. Lord Snow'), findsOneWidget);

      // Tap checkmark on Episode 2 to mark watched
      await tester.tap(find.byIcon(Icons.play_circle_fill_rounded));
      await tester.pump();

      expect(markedSeason, 1);
      expect(markedEpisode, 2);
    });
  });
}
