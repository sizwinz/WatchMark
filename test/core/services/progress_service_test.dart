import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watchmark/core/database/app_database.dart';
import 'package:watchmark/core/services/progress_service.dart';

void main() {
  late AppDatabase db;
  late ProgressService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = ProgressService(
      libraryDao: db.libraryDao,
      mediaDao: db.mediaDao,
      sessionsDao: db.sessionsDao,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('ProgressService Unit Tests', () {
    test('updateProgress updates library entry and logs watch session', () async {
      const mediaId = 'media-1';
      await db.mediaDao.upsertTitle(
        MediaTitlesCompanion.insert(
          id: const drift.Value(mediaId),
          tmdbId: '100',
          mediaType: 'movie',
          title: 'Inception',
          runtimeMinutes: const drift.Value(148),
        ),
      );

      await service.updateProgress(
        mediaId: mediaId,
        newProgressSeconds: 1800, // 30 mins
        platform: 'netflix',
      );

      final entry = await db.libraryDao.getLibraryEntryByMediaId(mediaId);
      expect(entry, isNotNull);
      expect(entry!.progressSeconds, 1800);
      expect(entry.status, 'watching');

      final sessions = await db.sessionsDao.getAllSessions();
      expect(sessions.length, 1);
      final duration = sessions.first.positionAfterSeconds - sessions.first.positionBeforeSeconds;
      expect(duration, 1800);
      expect(sessions.first.provider, 'netflix');
    });

    test('incrementProgress adds delta duration to existing progress', () async {
      const mediaId = 'media-2';
      await db.mediaDao.upsertTitle(
        MediaTitlesCompanion.insert(
          id: const drift.Value(mediaId),
          tmdbId: '101',
          mediaType: 'movie',
          title: 'Interstellar',
          runtimeMinutes: const drift.Value(169),
        ),
      );

      await service.updateProgress(mediaId: mediaId, newProgressSeconds: 600);
      await service.incrementProgress(mediaId: mediaId, deltaSeconds: 900);

      final entry = await db.libraryDao.getLibraryEntryByMediaId(mediaId);
      expect(entry!.progressSeconds, 1500);

      final sessions = await db.sessionsDao.getAllSessions();
      expect(sessions.length, 2);
    });

    test('markEpisodeWatched advances within season and across season boundaries', () async {
      const mediaId = 'tv-show-1';
      await db.mediaDao.upsertTitle(
        MediaTitlesCompanion.insert(
          id: const drift.Value(mediaId),
          tmdbId: '200',
          mediaType: 'tv',
          title: 'Breaking Bad',
        ),
      );

      // Season 1 with 2 episodes
      const s1Id = 'season-1';
      await db.mediaDao.upsertSeason(
        SeasonsCompanion.insert(
          id: const drift.Value(s1Id),
          mediaId: mediaId,
          seasonNumber: 1,
          name: 'Season 1',
        ),
      );
      await db.mediaDao.upsertEpisode(
        EpisodesCompanion.insert(
          id: const drift.Value('s1-e1'),
          seasonId: s1Id,
          mediaId: mediaId,
          episodeNumber: 1,
          title: 'Pilot',
          runtimeMinutes: const drift.Value(58),
        ),
      );
      await db.mediaDao.upsertEpisode(
        EpisodesCompanion.insert(
          id: const drift.Value('s1-e2'),
          seasonId: s1Id,
          mediaId: mediaId,
          episodeNumber: 2,
          title: 'Cat\'s in the Bag...',
          runtimeMinutes: const drift.Value(48),
        ),
      );

      // Season 2 with 1 episode
      const s2Id = 'season-2';
      await db.mediaDao.upsertSeason(
        SeasonsCompanion.insert(
          id: const drift.Value(s2Id),
          mediaId: mediaId,
          seasonNumber: 2,
          name: 'Season 2',
        ),
      );
      await db.mediaDao.upsertEpisode(
        EpisodesCompanion.insert(
          id: const drift.Value('s2-e1'),
          seasonId: s2Id,
          mediaId: mediaId,
          episodeNumber: 1,
          title: 'Seven Thirty-Seven',
          runtimeMinutes: const drift.Value(47),
        ),
      );

      // 1. Mark S1 E1 watched -> should advance to S1 E2
      await service.markEpisodeWatched(
        mediaId: mediaId,
        seasonNumber: 1,
        episodeNumber: 1,
      );

      var entry = await db.libraryDao.getLibraryEntryByMediaId(mediaId);
      expect(entry!.currentSeason, 1);
      expect(entry.currentEpisode, 2);
      expect(entry.progressSeconds, 0);
      expect(entry.status, 'watching');

      // 2. Mark S1 E2 watched -> should advance across season to S2 E1
      await service.markEpisodeWatched(
        mediaId: mediaId,
        seasonNumber: 1,
        episodeNumber: 2,
      );

      entry = await db.libraryDao.getLibraryEntryByMediaId(mediaId);
      expect(entry!.currentSeason, 2);
      expect(entry.currentEpisode, 1);
      expect(entry.progressSeconds, 0);
      expect(entry.status, 'watching');

      // 3. Mark S2 E1 watched -> series finale -> status becomes 'completed'
      await service.markEpisodeWatched(
        mediaId: mediaId,
        seasonNumber: 2,
        episodeNumber: 1,
      );

      entry = await db.libraryDao.getLibraryEntryByMediaId(mediaId);
      expect(entry!.status, 'completed');
    });

    test('updateProgress backward correction updates progressSeconds without inserting new watch session', () async {
      const mediaId = 'correction-media-1';
      await db.mediaDao.upsertTitle(
        MediaTitlesCompanion.insert(
          id: const drift.Value(mediaId),
          tmdbId: '500',
          mediaType: 'movie',
          title: 'Correction Test',
          runtimeMinutes: const drift.Value(120),
        ),
      );

      // Initial progress 3600s (1h) with status 'paused'
      await db.libraryDao.upsertLibraryEntry(
        LibraryEntriesCompanion.insert(
          id: const drift.Value('entry-corr'),
          mediaId: mediaId,
          status: 'paused',
          progressSeconds: const drift.Value(3600),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );

      // Correct progress backward to 300s (5m)
      await service.updateProgress(
        mediaId: mediaId,
        newProgressSeconds: 300,
      );

      // No new sessions should be inserted
      final sessions = await db.sessionsDao.getAllSessions();
      expect(sessions.length, 0);

      // Library entry bookmark should be updated to 300s and status should stay 'paused'
      final entry = await db.libraryDao.getLibraryEntryByMediaId(mediaId);
      expect(entry!.progressSeconds, 300);
      expect(entry.status, 'paused');
    });

    test('updateProgress logs session when platform is specified even with 0 delta', () async {
      const mediaId = 'tagging-media-1';
      await db.mediaDao.upsertTitle(
        MediaTitlesCompanion.insert(
          id: const drift.Value(mediaId),
          tmdbId: '600',
          mediaType: 'tv',
          title: 'Platform Tag Test',
        ),
      );

      // User selects Apple TV+ on an unstarted series (progress 0)
      await service.updateProgress(
        mediaId: mediaId,
        newProgressSeconds: 0,
        platform: 'apple_tv',
      );

      final sessions = await db.sessionsDao.getAllSessions();
      expect(sessions.length, 1);
      expect(sessions.first.provider, 'apple_tv');

      final latest = await db.sessionsDao.getLatestSessionForMedia(mediaId);
      expect(latest?.provider, 'apple_tv');

      // Subsequent quick increment inherits apple_tv
      await service.incrementProgress(
        mediaId: mediaId,
        deltaSeconds: 900,
      );

      final updatedSessions = await db.sessionsDao.getAllSessions();
      expect(updatedSessions.length, 2);
      expect(updatedSessions.first.provider, 'apple_tv');
    });
  });
}
