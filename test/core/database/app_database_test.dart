import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watchmark/core/database/app_database.dart';
import 'package:watchmark/core/utilities/uuid_helper.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Drift Database & UUIDv7 Entity Schema Tests', () {
    test('UUIDv7 generator creates valid non-empty string IDs', () {
      final id1 = generateUuidV7();
      final id2 = generateUuidV7();

      expect(id1.isNotEmpty, true);
      expect(id2.isNotEmpty, true);
      expect(id1, isNot(equals(id2)));
    });

    test('Inserts MediaTitle and retrieves via MediaDao', () async {
      final titleId = generateUuidV7();
      await db.mediaDao.upsertTitle(
        MediaTitlesCompanion.insert(
          id: Value(titleId),
          tmdbId: '550',
          mediaType: 'movie',
          title: 'Fight Club',
          overview: const Value('An insomniac office worker...'),
          runtimeMinutes: const Value(139),
        ),
      );

      final titles = await db.mediaDao.getAllTitles();
      expect(titles.length, 1);
      expect(titles.first.id, titleId);
      expect(titles.first.title, 'Fight Club');
      expect(titles.first.deletedAt, isNull);
    });

    test('Soft delete marks deletedAt and excludes from default queries', () async {
      final titleId = generateUuidV7();
      await db.mediaDao.upsertTitle(
        MediaTitlesCompanion.insert(
          id: Value(titleId),
          tmdbId: '603',
          mediaType: 'movie',
          title: 'The Matrix',
        ),
      );

      // Verify exists before deletion
      var titles = await db.mediaDao.getAllTitles();
      expect(titles.length, 1);

      // Perform soft delete
      await db.mediaDao.softDeleteTitle(titleId);

      // Verify filtered out by default
      titles = await db.mediaDao.getAllTitles();
      expect(titles.isEmpty, true);

      // Verify record still exists in raw database with tombstone
      final rawTitles = await db.mediaDao.getAllTitles(includeDeleted: true);
      expect(rawTitles.length, 1);
      expect(rawTitles.first.deletedAt, isNotNull);
    });

    test('Inserts Seasons and Episodes linked to MediaTitle', () async {
      final mediaId = generateUuidV7();
      await db.mediaDao.upsertTitle(
        MediaTitlesCompanion.insert(
          id: Value(mediaId),
          tmdbId: '1399',
          mediaType: 'tv',
          title: 'Game of Thrones',
        ),
      );

      final seasonId = generateUuidV7();
      await db.mediaDao.upsertSeason(
        SeasonsCompanion.insert(
          id: Value(seasonId),
          mediaId: mediaId,
          seasonNumber: 1,
          name: 'Season 1',
          episodeCount: const Value(10),
        ),
      );

      final episodeId = generateUuidV7();
      await db.mediaDao.upsertEpisode(
        EpisodesCompanion.insert(
          id: Value(episodeId),
          seasonId: seasonId,
          mediaId: mediaId,
          episodeNumber: 1,
          title: 'Winter Is Coming',
          runtimeMinutes: const Value(62),
        ),
      );

      final seasons = await db.mediaDao.getSeasonsForMedia(mediaId);
      expect(seasons.length, 1);
      expect(seasons.first.name, 'Season 1');

      final episodes = await db.mediaDao.getEpisodesForSeason(seasonId);
      expect(episodes.length, 1);
      expect(episodes.first.title, 'Winter Is Coming');
    });

    test('Inserts and queries LibraryEntry and WatchSessions', () async {
      final mediaId = generateUuidV7();
      await db.mediaDao.upsertTitle(
        MediaTitlesCompanion.insert(
          id: Value(mediaId),
          tmdbId: '157336',
          mediaType: 'movie',
          title: 'Interstellar',
        ),
      );

      final entryId = generateUuidV7();
      await db.libraryDao.upsertLibraryEntry(
        LibraryEntriesCompanion.insert(
          id: Value(entryId),
          mediaId: mediaId,
          status: 'watching',
          progressSeconds: const Value(3600),
        ),
      );

      final entries = await db.libraryDao.getAllLibraryEntries();
      expect(entries.length, 1);
      expect(entries.first.status, 'watching');
      expect(entries.first.progressSeconds, 3600);

      final sessionId = generateUuidV7();
      final startTime = DateTime.now().subtract(const Duration(hours: 1));
      final endTime = DateTime.now();

      await db.sessionsDao.insertSession(
        WatchSessionsCompanion.insert(
          id: Value(sessionId),
          mediaId: mediaId,
          startedAt: startTime,
          endedAt: endTime,
          positionBeforeSeconds: const Value(0),
          positionAfterSeconds: 3600,
          provider: const Value('Netflix'),
        ),
      );

      final sessions = await db.sessionsDao.getAllSessions();
      expect(sessions.length, 1);
      expect(sessions.first.provider, 'Netflix');
      expect(sessions.first.positionAfterSeconds, 3600);
    });
  });
}
