import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watchmark/features/progress/widgets/progress_modal_sheet.dart';

void main() {
  group('ProgressModalSheet Widget Tests', () {
    testWidgets('Renders duration labels, slider, chips, and actions', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProgressModalSheet(
                mediaId: 'm-1',
                title: 'Inception',
                totalDurationSeconds: 7200, // 2 hours
                initialProgressSeconds: 1800, // 30 mins (25%)
                isMovie: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Inception'), findsOneWidget);
      expect(find.text('30:00'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('2:00:00'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('+5 min'), findsOneWidget);
      expect(find.text('+15 min'), findsOneWidget);
      expect(find.text('+30 min'), findsOneWidget);
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('Mark Complete'), findsOneWidget);
      expect(find.text('Save Progress'), findsOneWidget);
    });

    testWidgets('Tapping +15 min chip increments progress duration', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProgressModalSheet(
                mediaId: 'm-1',
                title: 'Inception',
                totalDurationSeconds: 7200,
                initialProgressSeconds: 1800,
                isMovie: true,
              ),
            ),
          ),
        ),
      );

      // Tap +15 min -> 30 + 15 = 45 mins (37%)
      await tester.tap(find.text('+15 min'));
      await tester.pump();

      expect(find.text('45:00'), findsOneWidget);
      expect(find.text('37%'), findsOneWidget);
    });

    testWidgets('Tapping timestamp opens exact time input dialog', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProgressModalSheet(
                mediaId: 'm-1',
                title: 'Inception',
                totalDurationSeconds: 7200,
                initialProgressSeconds: 1800,
                isMovie: true,
              ),
            ),
          ),
        ),
      );

      // Tap time text to open dialog
      await tester.tap(find.text('30:00'));
      await tester.pumpAndSettle();

      expect(find.text('Enter Exact Timestamp'), findsOneWidget);
      expect(find.text('Set'), findsOneWidget);

      // Tap cancel to close
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Enter Exact Timestamp'), findsNothing);
    });
  });
}
