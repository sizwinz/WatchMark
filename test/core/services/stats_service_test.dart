import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watchmark/core/database/app_database.dart';
import 'package:watchmark/core/services/stats_service.dart';

void main() {
  late AppDatabase db;
  late StatsService statsService;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    statsService = StatsService(db.sessionsDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('StatsService Unit Tests', () {
    test('Calculates zero stats when no sessions exist', () async {
      final stats = await statsService.watchStats().first;
      expect(stats.totalMinutes, 0);
      expect(stats.moviesMinutes, 0);
      expect(stats.episodesMinutes, 0);
      expect(stats.totalSessions, 0);
      expect(stats.formattedTotalTime, '0 mins');
    });

    test('Calculates aggregated watch time, platform breakdown, and monthly breakdown', () async {
      // 1. Insert media titles
      await db.mediaDao.upsertTitle(
        MediaTitlesCompanion.insert(
          id: const drift.Value('m-movie-1'),
          tmdbId: '101',
          mediaType: 'movie',
          title: 'Dune: Part Two',
          overview: const drift.Value('[GENRE: Sci-Fi, Adventure] Epic continuation.'),
        ),
      );

      await db.mediaDao.upsertTitle(
        MediaTitlesCompanion.insert(
          id: const drift.Value('m-tv-1'),
          tmdbId: '202',
          mediaType: 'tv',
          title: 'Severance',
          overview: const drift.Value('[GENRE: Sci-Fi, Thriller] Mind-bending mystery.'),
        ),
      );

      // 2. Insert watch sessions
      // Movie session: 120 mins on Netflix
      await db.sessionsDao.insertSession(
        WatchSessionsCompanion.insert(
          id: const drift.Value('sess-1'),
          mediaId: 'm-movie-1',
          startedAt: DateTime.now().subtract(const Duration(hours: 3)),
          endedAt: DateTime.now().subtract(const Duration(hours: 1)),
          positionBeforeSeconds: const drift.Value(0),
          positionAfterSeconds: 7200, // 120 mins
          provider: const drift.Value('netflix'),
          entryMethod: const drift.Value('manual'),
        ),
      );

      // TV session: 45 mins on Apple TV+
      await db.sessionsDao.insertSession(
        WatchSessionsCompanion.insert(
          id: const drift.Value('sess-2'),
          mediaId: 'm-tv-1',
          startedAt: DateTime.now().subtract(const Duration(minutes: 50)),
          endedAt: DateTime.now().subtract(const Duration(minutes: 5)),
          positionBeforeSeconds: const drift.Value(0),
          positionAfterSeconds: 2700, // 45 mins
          provider: const drift.Value('apple'),
          entryMethod: const drift.Value('manual'),
        ),
      );

      final stats = await statsService.watchStats().first;

      expect(stats.totalMinutes, 165); // 120 + 45
      expect(stats.moviesMinutes, 120);
      expect(stats.episodesMinutes, 45);
      expect(stats.totalSessions, 2);
      expect(stats.formattedTotalTime, '2 h 45 m');
      expect(stats.formattedMoviesTime, '2 h 0 m');
      expect(stats.formattedEpisodesTime, '45 m');

      // Platform distribution
      expect(stats.platformBreakdown.length, 2);
      expect(stats.platformBreakdown.first.displayName, 'Netflix');
      expect(stats.platformBreakdown.first.minutes, 120);
      expect(stats.platformBreakdown.last.displayName, 'Apple TV+');
      expect(stats.platformBreakdown.last.minutes, 45);

      // Top genres
      expect(stats.topGenres.any((g) => g.genreName == 'Sci-Fi'), isTrue);
      expect(stats.topGenres.firstWhere((g) => g.genreName == 'Sci-Fi').minutes, 165);
    });
  });
}
