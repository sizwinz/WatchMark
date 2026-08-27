import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watchmark/core/network/tmdb_api_service.dart';
import 'package:watchmark/features/search/controllers/search_controller.dart';
import 'package:watchmark/features/search/views/search_view.dart';

class FakeTmdbApiService extends TmdbApiService {
  FakeTmdbApiService() : super(Dio());

  @override
  Future<List<TmdbSearchResult>> getTrending({String timeWindow = 'day', int page = 1}) async => [];

  @override
  Future<List<TmdbSearchResult>> getPopularMovies({int page = 1}) async => [];

  @override
  Future<List<TmdbSearchResult>> getPopularTv({int page = 1}) async => [];

  @override
  Future<List<TmdbSearchResult>> multiSearch(String query, {int page = 1}) async => [];
}

void main() {
  late FakeTmdbApiService mockTmdb;

  setUp(() {
    mockTmdb = FakeTmdbApiService();
  });

  group('SearchView Widget Tests', () {
    testWidgets('Renders search input field and empty state placeholder', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tmdbApiServiceProvider.overrideWithValue(mockTmdb),
          ],
          child: const MaterialApp(
            home: SearchView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search movies, TV shows...'), findsOneWidget);
      expect(
        find.text('Search for your favorite movies and series to start tracking'),
        findsOneWidget,
      );
    });

    testWidgets('Typing triggers debounced query in SearchController', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tmdbApiServiceProvider.overrideWithValue(mockTmdb),
          ],
          child: const MaterialApp(
            home: SearchView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Inception');
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Inception'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
    });
  });

  group('SearchStateNotifier Unit Tests', () {
    test('Debounces short query and clears results if < 2 chars', () {
      final container = ProviderContainer(
        overrides: [
          tmdbApiServiceProvider.overrideWithValue(mockTmdb),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(searchControllerProvider.notifier);
      notifier.onQueryChanged('a');

      expect(container.read(searchControllerProvider).query, 'a');
      expect(container.read(searchControllerProvider).results.isEmpty, true);
    });
  });
}
