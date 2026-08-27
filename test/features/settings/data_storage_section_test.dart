import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watchmark/core/services/backup_service.dart';
import 'package:watchmark/features/settings/widgets/data_storage_card.dart';
import 'package:watchmark/features/settings/widgets/import_preview_dialog.dart';

void main() {
  group('Data Storage & Import Preview Widget Tests', () {
    testWidgets('DataStorageCard renders all 4 action tiles', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: DataStorageCard(),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Data & Storage'), findsOneWidget);
      expect(find.text('Export JSON Backup'), findsOneWidget);
      expect(find.text('Import JSON Backup'), findsOneWidget);
      expect(find.text('Clear Cached Metadata'), findsOneWidget);
      expect(find.text('Reset All Data'), findsOneWidget);
    });

    testWidgets('ImportPreviewDialog renders backup counts and strategy toggle', (tester) async {
      final validation = BackupValidationResult(
        isValid: true,
        version: 1,
        titleCount: 15,
        episodeCount: 42,
        libraryCount: 12,
        sessionCount: 110,
        exportedAt: DateTime(2026, 8, 26, 12, 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImportPreviewDialog(
              validation: validation,
              onConfirm: (overwrite) async {},
            ),
          ),
        ),
      );

      expect(find.text('Import Backup'), findsOneWidget);
      expect(find.text('12'), findsOneWidget); // library count
      expect(find.text('15 titles, 42 episodes'), findsOneWidget);
      expect(find.text('110'), findsOneWidget); // session count
      expect(find.text('Overwrite Entire Database'), findsOneWidget);
      expect(find.text('Apply Merge'), findsOneWidget);

      // Toggle switch to overwrite
      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(find.text('Confirm Overwrite'), findsOneWidget);
    });
  });
}
