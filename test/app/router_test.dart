import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watchmark/app/app.dart';
import 'package:watchmark/features/home/controllers/home_controller.dart';

void main() {
  group('Responsive Navigation Shell Tests', () {
    testWidgets('Renders NavigationBar on mobile viewport (<720px)', (tester) async {
      tester.view.physicalSize = const Size(500, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            continueWatchingStreamProvider.overrideWith((ref) => Stream.value([])),
            homeStatsProvider.overrideWith((ref) => Stream.value(const HomeStats())),
          ],
          child: const WatchMarkApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Search'), findsWidgets);
      expect(find.text('Library'), findsWidgets);
      expect(find.text('History'), findsWidgets);
      expect(find.text('Settings'), findsWidgets);
    });

    testWidgets('Renders NavigationRail on desktop viewport (>=720px)', (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            continueWatchingStreamProvider.overrideWith((ref) => Stream.value([])),
            homeStatsProvider.overrideWith((ref) => Stream.value(const HomeStats())),
          ],
          child: const WatchMarkApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('WatchMark'), findsWidgets);
      expect(find.text('Watchlist'), findsWidgets);
      expect(find.text('Stats'), findsWidgets);
    });
  });
}
