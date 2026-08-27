import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  });
}
