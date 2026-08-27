import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:watchmark/app/shortcuts.dart';

void main() {
  group('AppKeyboardShortcuts Tests', () {
    testWidgets('Ctrl+K dispatches SearchIntent and triggers search route', (tester) async {
      String navigatedLocation = '';

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const AppKeyboardShortcuts(
              child: Scaffold(body: Text('Home Content')),
            ),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) {
              navigatedLocation = '/search';
              return const Scaffold(body: Text('Search Content'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Home Content'), findsOneWidget);

      // Simulate pressing Ctrl+K
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(navigatedLocation, '/search');
      expect(find.text('Search Content'), findsOneWidget);
    });
  });
}
