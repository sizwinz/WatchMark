import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watchmark/core/database/app_database.dart';
import 'package:watchmark/core/services/backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late BackupService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = BackupService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('BackupService Unit Tests', () {
    test('exportBackupJson produces valid JSON payload with schema version 1', () async {
      await db.mediaDao.upsertTitle(
        MediaTitlesCompanion.insert(
          id: const drift.Value('m-1'),
          tmdbId: '550',
          mediaType: 'movie',
          title: 'Fight Club',
          runtimeMinutes: const drift.Value(139),
        ),
      );

      await db.libraryDao.upsertLibraryEntry(
        LibraryEntriesCompanion.insert(
          id: const drift.Value('lib-1'),
          mediaId: 'm-1',
          status: 'completed',
          progressSeconds: const drift.Value(8340),
        ),
      );

      final jsonStr = await service.exportBackupJson();
      final validation = service.validateBackupJson(jsonStr);

      expect(validation.isValid, isTrue);
      expect(validation.version, 1);
      expect(validation.titleCount, 1);
      expect(validation.libraryCount, 1);
      expect(validation.exportedAt, isNotNull);
    });

    test('validateBackupJson rejects corrupt and unsupported schema versions', () {
      final invalidJson = service.validateBackupJson('{invalid_json}');
      expect(invalidJson.isValid, isFalse);
      expect(invalidJson.errorMessage, contains('JSON parse error'));

      final missingVersion = service.validateBackupJson('{"exported_at": "2026-08-26"}');
      expect(missingVersion.isValid, isFalse);
      expect(missingVersion.errorMessage, contains('Missing or invalid schema version'));

      final unsupportedVersion = service.validateBackupJson('{"version": 99}');
      expect(unsupportedVersion.isValid, isFalse);
      expect(unsupportedVersion.errorMessage, contains('Unsupported schema version: 99'));
    });

    test('importBackup smart merge updates existing and inserts new entries', () async {
      // Existing title in local database
      await db.mediaDao.upsertTitle(
        MediaTitlesCompanion.insert(
          id: const drift.Value('m-1'),
          tmdbId: '100',
          mediaType: 'movie',
          title: 'Inception',
        ),
      );

      const backupJson = '''
      {
        "version": 1,
        "exported_at": "2026-08-26T12:00:00.000Z",
        "media_titles": [
          {
            "id": "m-1",
            "tmdbId": "100",
            "mediaType": "movie",
            "title": "Inception (Updated)",
            "createdAt": 1724673600000,
            "updatedAt": 1724673600000
          },
          {
            "id": "m-2",
            "tmdbId": "200",
            "mediaType": "movie",
            "title": "Interstellar",
            "createdAt": 1724673600000,
            "updatedAt": 1724673600000
          }
        ],
        "seasons": [],
        "episodes": [],
        "library_entries": [
          {
            "id": "lib-2",
            "mediaId": "m-2",
            "status": "watchlist",
            "progressSeconds": 0,
            "createdAt": 1724673600000,
            "updatedAt": 1724673600000
          }
        ],
        "watch_sessions": [],
        "user_ratings": [],
        "custom_lists": [],
        "custom_list_items": []
      }
      ''';

      await service.importBackup(jsonStr: backupJson, overwrite: false);

      final titles = await db.mediaDao.getAllTitles();
      expect(titles.length, 2);
      expect(titles.firstWhere((t) => t.id == 'm-1').title, 'Inception (Updated)');

      final library = await db.libraryDao.getAllLibraryEntries();
      expect(library.length, 1);
      expect(library.first.mediaId, 'm-2');
    });

    test('importBackup with overwrite true wipes old database and restores snapshot', () async {
      // Add existing local title
      await db.mediaDao.upsertTitle(
        MediaTitlesCompanion.insert(
          id: const drift.Value('old-media'),
          tmdbId: '999',
          mediaType: 'movie',
          title: 'Old Movie',
        ),
      );

      const backupJson = '''
      {
        "version": 1,
        "exported_at": "2026-08-26T12:00:00.000Z",
        "media_titles": [
          {
            "id": "new-media",
            "tmdbId": "888",
            "mediaType": "movie",
            "title": "New Movie",
            "createdAt": 1724673600000,
            "updatedAt": 1724673600000
          }
        ],
        "seasons": [],
        "episodes": [],
        "library_entries": [],
        "watch_sessions": [],
        "user_ratings": [],
        "custom_lists": [],
        "custom_list_items": []
      }
      ''';

      await service.importBackup(jsonStr: backupJson, overwrite: true);

      final titles = await db.mediaDao.getAllTitles();
      expect(titles.length, 1);
      expect(titles.first.id, 'new-media');
    });

    test('clearMetadataCache purges unreferenced media while retaining library media', () async {
      // 1. Referenced media
      await db.mediaDao.upsertTitle(
        MediaTitlesCompanion.insert(
          id: const drift.Value('keep-media'),
          tmdbId: '101',
          mediaType: 'movie',
          title: 'Keep Me',
        ),
      );
      await db.libraryDao.upsertLibraryEntry(
        LibraryEntriesCompanion.insert(
          id: const drift.Value('lib-keep'),
          mediaId: 'keep-media',
          status: 'watchlist',
        ),
      );

      // 2. Unreferenced search cache media
      await db.mediaDao.upsertTitle(
        MediaTitlesCompanion.insert(
          id: const drift.Value('purge-media'),
          tmdbId: '102',
          mediaType: 'movie',
          title: 'Purge Me',
        ),
      );

      final deleted = await service.clearMetadataCache();
      expect(deleted, 1);

      final titles = await db.mediaDao.getAllTitles();
      expect(titles.length, 1);
      expect(titles.first.id, 'keep-media');
    });

    test('resetDatabase wipes all tables completely', () async {
      await db.mediaDao.upsertTitle(
        MediaTitlesCompanion.insert(
          id: const drift.Value('m-1'),
          tmdbId: '101',
          mediaType: 'movie',
          title: 'Test Title',
        ),
      );
      await db.libraryDao.upsertLibraryEntry(
        LibraryEntriesCompanion.insert(
          id: const drift.Value('lib-1'),
          mediaId: 'm-1',
          status: 'watching',
        ),
      );

      await service.resetDatabase();

      final titles = await db.mediaDao.getAllTitles();
      final library = await db.libraryDao.getAllLibraryEntries();

      expect(titles, isEmpty);
      expect(library, isEmpty);
    });
  });
}
