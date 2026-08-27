import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watchmark/core/database/app_database.dart';
import 'package:watchmark/core/database/daos/custom_lists_dao.dart';
import 'package:watchmark/features/custom_lists/controllers/custom_lists_controller.dart';
import 'package:watchmark/features/custom_lists/views/custom_lists_tab.dart';
import 'package:watchmark/features/custom_lists/widgets/create_list_dialog.dart';

void main() {
  group('CustomLists UI Widget Tests', () {
    testWidgets('CustomListsTab renders empty state and action button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customListsWithCountsStreamProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            home: Scaffold(body: CustomListsTab()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Custom Lists Yet'), findsOneWidget);
      expect(find.text('Create Your First List'), findsOneWidget);
    });

    testWidgets('CustomListsTab renders lists when data is present', (tester) async {
      final dummyList = CustomList(
        id: 'list-horror',
        name: 'Halloween Spooktacular',
        description: 'Best horror movies',
        isRanked: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customListsWithCountsStreamProvider.overrideWith(
              (ref) => Stream.value([
                CustomListWithCount(list: dummyList, itemCount: 5),
              ]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: CustomListsTab()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Halloween Spooktacular'), findsOneWidget);
      expect(find.text('Best horror movies'), findsOneWidget);
      expect(find.text('Ranked'), findsOneWidget);
      expect(find.text('5 titles'), findsOneWidget);
    });

    testWidgets('CreateListDialog renders form fields', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: CreateListDialog()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Create Custom List'), findsOneWidget);
      expect(find.text('List Name *'), findsOneWidget);
      expect(find.text('Ranked List'), findsOneWidget);
    });
  });
}
