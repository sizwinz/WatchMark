import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watchmark/core/database/app_database.dart';
import 'package:watchmark/core/database/daos/sessions_dao.dart';
import 'package:watchmark/features/watch_history/controllers/history_controller.dart';
import 'package:watchmark/features/watch_history/views/history_view.dart';
import 'package:watchmark/features/watch_history/widgets/history_session_tile.dart';

void main() {
  group('HistoryView Widget Tests', () {
    testWidgets('HistoryView renders empty state when no history', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupedHistoryStreamProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: HistoryView(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Watch History'), findsOneWidget);
      expect(find.text('No watch history yet'), findsOneWidget);
    });

    testWidgets('HistorySessionTile renders media, platform badge, and duration', (tester) async {
      final item = WatchSessionWithMedia(
        session: WatchSession(
          id: 'sess-1',
          mediaId: 'm-1',
          startedAt: DateTime.now(),
          endedAt: DateTime.now().add(const Duration(minutes: 45)),
          positionBeforeSeconds: 0,
          positionAfterSeconds: 2700, // 45m
          provider: 'netflix',
          entryMethod: 'manual',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        media: MediaTitle(
          id: 'm-1',
          tmdbId: '100',
          mediaType: 'movie',
          title: 'Inception',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HistorySessionTile(
                item: item,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Inception'), findsOneWidget);
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('+45m'), findsOneWidget);
    });
  });
}
