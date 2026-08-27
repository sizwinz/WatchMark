import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchmark/core/database/app_database.dart';
import 'package:watchmark/core/database/daos/library_dao.dart';
import 'package:watchmark/core/database/daos/media_dao.dart';
import 'package:watchmark/core/database/daos/sessions_dao.dart';
import 'package:watchmark/core/sync/services/sync_queue_service.dart';
import 'package:watchmark/core/utilities/uuid_helper.dart';
import 'package:watchmark/shared/providers/database_provider.dart';

class ProgressService {
  final LibraryDao libraryDao;
  final MediaDao mediaDao;
  final SessionsDao sessionsDao;
  final SyncQueueService? syncQueueService;

  ProgressService({
    required this.libraryDao,
    required this.mediaDao,
    required this.sessionsDao,
    this.syncQueueService,
  });

  Future<void> updateProgress({
    required String mediaId,
    required int newProgressSeconds,
    int? seasonNumber,
    int? episodeNumber,
    String? platform,
    String? episodeId,
    String entryMethod = 'manual',
  }) async {
    final existing = await libraryDao.getLibraryEntryByMediaId(mediaId);
    final entryId = existing?.id ?? generateUuidV7();
    final oldProgress = existing?.progressSeconds ?? 0;
    final deltaSeconds = newProgressSeconds - oldProgress;

    // Log a session if progress advanced
    if (deltaSeconds > 0) {
      final sessionId = generateUuidV7();
      final sessionCompanion = WatchSessionsCompanion.insert(
        id: drift.Value(sessionId),
        mediaId: mediaId,
        episodeId: drift.Value(episodeId),
        startedAt: DateTime.now().subtract(Duration(seconds: deltaSeconds)),
        endedAt: DateTime.now(),
        positionBeforeSeconds: drift.Value(oldProgress),
        positionAfterSeconds: newProgressSeconds,
        provider: drift.Value(platform ?? 'other'),
        entryMethod: drift.Value(entryMethod),
        updatedAt: drift.Value(DateTime.now()),
        deletedAt: const drift.Value(null),
      );
      await sessionsDao.insertSession(sessionCompanion);

      syncQueueService?.enqueueEvent(
        entityType: 'watch_session',
        entityId: sessionId,
        operation: 'upsert',
        payload: {
          'id': sessionId,
          'mediaId': mediaId,
          'episodeId': episodeId,
          'startedAt': DateTime.now().subtract(Duration(seconds: deltaSeconds)).toIso8601String(),
          'endedAt': DateTime.now().toIso8601String(),
          'positionBeforeSeconds': oldProgress,
          'positionAfterSeconds': newProgressSeconds,
          'provider': platform ?? 'other',
          'entryMethod': entryMethod,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    }

    final entryCompanion = LibraryEntriesCompanion.insert(
      id: drift.Value(entryId),
      mediaId: mediaId,
      status: existing?.status ?? 'watching',
      progressSeconds: drift.Value(newProgressSeconds),
      currentSeason: seasonNumber != null ? drift.Value(seasonNumber) : drift.Value(existing?.currentSeason),
      currentEpisode: episodeNumber != null ? drift.Value(episodeNumber) : drift.Value(existing?.currentEpisode),
      lastWatchedAt: drift.Value(DateTime.now()),
      updatedAt: drift.Value(DateTime.now()),
      deletedAt: const drift.Value(null),
    );

    await libraryDao.upsertLibraryEntry(entryCompanion);

    syncQueueService?.enqueueEvent(
      entityType: 'library_entry',
      entityId: entryId,
      operation: 'upsert',
      payload: {
        'id': entryId,
        'mediaId': mediaId,
        'status': existing?.status ?? 'watching',
        'progressSeconds': newProgressSeconds,
        'currentSeason': seasonNumber ?? existing?.currentSeason,
        'currentEpisode': episodeNumber ?? existing?.currentEpisode,
        'lastWatchedAt': DateTime.now().toIso8601String(),
        'createdAt': (existing?.createdAt ?? DateTime.now()).toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> incrementProgress({
    required String mediaId,
    required int deltaSeconds,
    int? seasonNumber,
    int? episodeNumber,
    String? platform,
    String? episodeId,
  }) async {
    final existing = await libraryDao.getLibraryEntryByMediaId(mediaId);
    final currentProgress = existing?.progressSeconds ?? 0;
    final newProgress = (currentProgress + deltaSeconds).clamp(0, 86400);

    await updateProgress(
      mediaId: mediaId,
      newProgressSeconds: newProgress,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      platform: platform,
      episodeId: episodeId,
      entryMethod: 'quick_increment',
    );
  }

  Future<void> markMovieWatched({
    required String mediaId,
    String? platform,
  }) async {
    final movie = await mediaDao.getTitleById(mediaId);
    final runtimeSeconds = (movie?.runtimeMinutes ?? 120) * 60;

    final existing = await libraryDao.getLibraryEntryByMediaId(mediaId);
    final entryId = existing?.id ?? generateUuidV7();
    final oldProgress = existing?.progressSeconds ?? 0;
    final deltaSeconds = (runtimeSeconds - oldProgress).clamp(0, runtimeSeconds);

    if (deltaSeconds > 0) {
      final sessionId = generateUuidV7();
      await sessionsDao.insertSession(
        WatchSessionsCompanion.insert(
          id: drift.Value(sessionId),
          mediaId: mediaId,
          startedAt: DateTime.now().subtract(Duration(seconds: deltaSeconds)),
          endedAt: DateTime.now(),
          positionBeforeSeconds: drift.Value(oldProgress),
          positionAfterSeconds: runtimeSeconds,
          provider: drift.Value(platform ?? 'other'),
          entryMethod: const drift.Value('manual'),
          updatedAt: drift.Value(DateTime.now()),
          deletedAt: const drift.Value(null),
        ),
      );

      syncQueueService?.enqueueEvent(
        entityType: 'watch_session',
        entityId: sessionId,
        operation: 'upsert',
        payload: {
          'id': sessionId,
          'mediaId': mediaId,
          'startedAt': DateTime.now().subtract(Duration(seconds: deltaSeconds)).toIso8601String(),
          'endedAt': DateTime.now().toIso8601String(),
          'positionBeforeSeconds': oldProgress,
          'positionAfterSeconds': runtimeSeconds,
          'provider': platform ?? 'other',
          'entryMethod': 'manual',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    }

    await libraryDao.upsertLibraryEntry(
      LibraryEntriesCompanion.insert(
        id: drift.Value(entryId),
        mediaId: mediaId,
        status: 'completed',
        progressSeconds: drift.Value(runtimeSeconds),
        lastWatchedAt: drift.Value(DateTime.now()),
        updatedAt: drift.Value(DateTime.now()),
        deletedAt: const drift.Value(null),
      ),
    );

    syncQueueService?.enqueueEvent(
      entityType: 'library_entry',
      entityId: entryId,
      operation: 'upsert',
      payload: {
        'id': entryId,
        'mediaId': mediaId,
        'status': 'completed',
        'progressSeconds': runtimeSeconds,
        'lastWatchedAt': DateTime.now().toIso8601String(),
        'createdAt': (existing?.createdAt ?? DateTime.now()).toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> markEpisodeWatched({
    required String mediaId,
    required int seasonNumber,
    required int episodeNumber,
    String? platform,
  }) async {
    final existing = await libraryDao.getLibraryEntryByMediaId(mediaId);
    final entryId = existing?.id ?? generateUuidV7();

    // Log session for this episode
    final seasons = await mediaDao.getSeasonsForMedia(mediaId);
    final currentSeason = seasons.where((s) => s.seasonNumber == seasonNumber).firstOrNull;

    Episode? currentEp;
    if (currentSeason != null) {
      final eps = await mediaDao.getEpisodesForSeason(currentSeason.id);
      currentEp = eps.where((e) => e.episodeNumber == episodeNumber).firstOrNull;
    }

    final epDuration = (currentEp?.runtimeMinutes ?? 45) * 60;
    final oldProgress = (existing?.currentSeason == seasonNumber && existing?.currentEpisode == episodeNumber)
        ? (existing?.progressSeconds ?? 0)
        : 0;
    final deltaSeconds = (epDuration - oldProgress).clamp(0, epDuration);

    if (deltaSeconds > 0) {
      final sessionId = generateUuidV7();
      await sessionsDao.insertSession(
        WatchSessionsCompanion.insert(
          id: drift.Value(sessionId),
          mediaId: mediaId,
          episodeId: drift.Value(currentEp?.id),
          startedAt: DateTime.now().subtract(Duration(seconds: deltaSeconds)),
          endedAt: DateTime.now(),
          positionBeforeSeconds: drift.Value(oldProgress),
          positionAfterSeconds: epDuration,
          provider: drift.Value(platform ?? 'other'),
          entryMethod: const drift.Value('manual'),
          updatedAt: drift.Value(DateTime.now()),
          deletedAt: const drift.Value(null),
        ),
      );

      syncQueueService?.enqueueEvent(
        entityType: 'watch_session',
        entityId: sessionId,
        operation: 'upsert',
        payload: {
          'id': sessionId,
          'mediaId': mediaId,
          'episodeId': currentEp?.id,
          'startedAt': DateTime.now().subtract(Duration(seconds: deltaSeconds)).toIso8601String(),
          'endedAt': DateTime.now().toIso8601String(),
          'positionBeforeSeconds': oldProgress,
          'positionAfterSeconds': epDuration,
          'provider': platform ?? 'other',
          'entryMethod': 'manual',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    }

    // Determine Next Episode Progression
    var nextSeasonNum = seasonNumber;
    int? nextEpisodeNum;

    if (currentSeason != null) {
      final eps = await mediaDao.getEpisodesForSeason(currentSeason.id);
      final nextInSeason = eps.where((e) => e.episodeNumber == episodeNumber + 1).firstOrNull;
      if (nextInSeason != null) {
        nextEpisodeNum = nextInSeason.episodeNumber;
      }
    }

    // If no next episode in current season, look for next season
    if (nextEpisodeNum == null) {
      final regularSeasons = seasons.where((s) => s.seasonNumber > seasonNumber).toList()
        ..sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));

      if (regularSeasons.isNotEmpty) {
        final nextSeason = regularSeasons.first;
        final nextSeasonEps = await mediaDao.getEpisodesForSeason(nextSeason.id);
        if (nextSeasonEps.isNotEmpty) {
          nextSeasonNum = nextSeason.seasonNumber;
          nextEpisodeNum = nextSeasonEps.first.episodeNumber;
        }
      }
    }

    if (nextEpisodeNum != null) {
      // Advance to next episode
      await libraryDao.upsertLibraryEntry(
        LibraryEntriesCompanion.insert(
          id: drift.Value(entryId),
          mediaId: mediaId,
          status: 'watching',
          progressSeconds: const drift.Value(0),
          currentSeason: drift.Value(nextSeasonNum),
          currentEpisode: drift.Value(nextEpisodeNum),
          lastWatchedAt: drift.Value(DateTime.now()),
          updatedAt: drift.Value(DateTime.now()),
          deletedAt: const drift.Value(null),
        ),
      );
    } else {
      // Series Finale Completed
      await libraryDao.upsertLibraryEntry(
        LibraryEntriesCompanion.insert(
          id: drift.Value(entryId),
          mediaId: mediaId,
          status: 'completed',
          progressSeconds: drift.Value(epDuration),
          currentSeason: drift.Value(seasonNumber),
          currentEpisode: drift.Value(episodeNumber),
          lastWatchedAt: drift.Value(DateTime.now()),
          updatedAt: drift.Value(DateTime.now()),
          deletedAt: const drift.Value(null),
        ),
      );
    }

    syncQueueService?.enqueueEvent(
      entityType: 'library_entry',
      entityId: entryId,
      operation: 'upsert',
      payload: {
        'id': entryId,
        'mediaId': mediaId,
        'status': nextEpisodeNum != null ? 'watching' : 'completed',
        'progressSeconds': nextEpisodeNum != null ? 0 : epDuration,
        'currentSeason': nextEpisodeNum != null ? nextSeasonNum : seasonNumber,
        'currentEpisode': nextEpisodeNum ?? episodeNumber,
        'lastWatchedAt': DateTime.now().toIso8601String(),
        'createdAt': (existing?.createdAt ?? DateTime.now()).toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );
  }
}

final progressServiceProvider = Provider<ProgressService>((ref) {
  final libraryDao = ref.watch(libraryDaoProvider);
  final mediaDao = ref.watch(mediaDaoProvider);
  final sessionsDao = ref.watch(sessionsDaoProvider);
  final syncQueueService = ref.watch(syncQueueServiceProvider);

  return ProgressService(
    libraryDao: libraryDao,
    mediaDao: mediaDao,
    sessionsDao: sessionsDao,
    syncQueueService: syncQueueService,
  );
});
