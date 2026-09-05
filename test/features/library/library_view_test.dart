import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watchmark/core/database/app_database.dart';
import 'package:watchmark/core/database/daos/library_dao.dart';
import 'package:watchmark/features/library/controllers/library_controller.dart';
import 'package:watchmark/features/library/views/library_view.dart';
import 'package:watchmark/features/library/widgets/library_card.dart';
import 'package:watchmark/features/library/widgets/status_filter_bar.dart';

void main() {
  group('LibraryView Widget Tests', () {
    testWidgets('StatusFilterBar renders status chips with counts', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            rawLibraryItemsStreamProvider.overrideWith(
              (ref) => Stream.value(<LibraryItemWithMedia>[]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: StatusFilterBar(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('All (0)'), findsOneWidget);
      expect(find.text('Watching (0)'), findsOneWidget);
      expect(find.text('Watchlist (0)'), findsOneWidget);
      expect(find.text('Completed (0)'), findsOneWidget);
    });

    testWidgets('LibraryView renders empty state with search button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            rawLibraryItemsStreamProvider.overrideWith(
              (ref) => Stream.value(<LibraryItemWithMedia>[]),
            ),
          ],
          child: const MaterialApp(
            home: LibraryView(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Your library is empty'), findsOneWidget);
      expect(find.text('Search Titles'), findsOneWidget);
    });

    testWidgets('LibraryCard renders progress bar and elapsed time when progress exists', (tester) async {
      final item = LibraryItemWithMedia(
        entry: LibraryEntry(
          id: 'e1',
          mediaId: 'm1',
          status: 'paused',
          progressSeconds: 3600,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        media: MediaTitle(
          id: 'm1',
          tmdbId: '500',
          mediaType: 'movie',
          title: 'Avengers: Doomsday',
          runtimeMinutes: 120,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 180,
                height: 280,
                child: LibraryCard(
                  item: item,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Avengers: Doomsday'), findsOneWidget);
      expect(find.text('PAUSED'), findsOneWidget);
      expect(find.text('1h / 2h (50%)'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('LibraryCard renders season and episode position for TV series in watching state even with 0 progress', (tester) async {
      final item = LibraryItemWithMedia(
        entry: LibraryEntry(
          id: 'e2',
          mediaId: 'm2',
          status: 'watching',
          progressSeconds: 0,
          currentSeason: 2,
          currentEpisode: 4,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        media: MediaTitle(
          id: 'm2',
          tmdbId: '600',
          mediaType: 'tv',
          title: 'Severance',
          runtimeMinutes: 50,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 180,
                height: 280,
                child: LibraryCard(
                  item: item,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Severance'), findsOneWidget);
      expect(find.text('WATCHING'), findsOneWidget);
      expect(find.text('S2:E4 • Next Up'), findsOneWidget);
    });
  });

  group('LibraryFilterNotifier Unit Tests', () {
    test('Updates status and sort order correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(libraryFilterProvider.notifier);
      expect(container.read(libraryFilterProvider).status, 'all');

      notifier.setStatus('watching');
      expect(container.read(libraryFilterProvider).status, 'watching');

      notifier.setSortOrder(LibrarySortOrder.titleAsc);
      expect(container.read(libraryFilterProvider).sortOrder, LibrarySortOrder.titleAsc);

      notifier.setMediaType('movie');
      expect(container.read(libraryFilterProvider).mediaType, 'movie');
    });
  });
}
