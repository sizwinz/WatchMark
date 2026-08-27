import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watchmark/features/search/controllers/search_controller.dart';
import 'package:watchmark/features/search/views/search_view.dart';

void main() {
  group('SearchView Widget Tests', () {
    testWidgets('Renders search input field and empty state placeholder', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchView(),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search movies, TV shows...'), findsOneWidget);
      expect(
        find.text('Search for your favorite movies and series to start tracking'),
        findsOneWidget,
      );
    });

    testWidgets('Typing triggers debounced query in SearchController', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchView(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Inception');
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Inception'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
    });
  });

  group('SearchStateNotifier Unit Tests', () {
    test('Debounces short query and clears results if < 2 chars', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(searchControllerProvider.notifier);
      notifier.onQueryChanged('a');

      expect(container.read(searchControllerProvider).query, 'a');
      expect(container.read(searchControllerProvider).results.isEmpty, true);
    });
  });
}
