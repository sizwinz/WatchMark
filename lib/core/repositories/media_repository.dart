import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchmark/core/database/app_database.dart';
import 'package:watchmark/core/database/daos/media_dao.dart';
import 'package:watchmark/core/network/tmdb_api_service.dart';
import 'package:watchmark/core/utilities/uuid_helper.dart';
import 'package:watchmark/shared/providers/database_provider.dart';

class MediaRepository {
  final TmdbApiService tmdbService;
  final MediaDao mediaDao;

  MediaRepository({
    required this.tmdbService,
    required this.mediaDao,
  });

  Future<MediaTitle> cacheMediaDetail(TmdbMediaDetail detail) async {
    final existing = await mediaDao.getTitleByTmdbId(
      detail.id.toString(),
      detail.mediaType,
      includeDeleted: true,
    );

    final titleId = existing?.id ?? generateUuidV7();
    DateTime? releaseDate;
    if (detail.releaseDate != null && detail.releaseDate!.isNotEmpty) {
      releaseDate = DateTime.tryParse(detail.releaseDate!);
    }

    await mediaDao.upsertTitle(
      MediaTitlesCompanion.insert(
        id: Value(titleId),
        tmdbId: detail.id.toString(),
        mediaType: detail.mediaType,
        title: detail.title,
        originalTitle: Value(detail.originalTitle),
        overview: Value(detail.overview),
        posterPath: Value(detail.posterPath),
        backdropPath: Value(detail.backdropPath),
        releaseDate: Value(releaseDate),
        runtimeMinutes: Value(detail.runtimeMinutes),
        updatedAt: Value(DateTime.now()),
        deletedAt: const Value(null),
      ),
    );

    if (detail.mediaType == 'tv') {
      for (final s in detail.seasons) {
        final existingSeasons = await mediaDao.getSeasonsForMedia(titleId, includeDeleted: true);
        final existingSeason = existingSeasons.where((item) => item.seasonNumber == s.seasonNumber).firstOrNull;
        final seasonId = existingSeason?.id ?? generateUuidV7();

        DateTime? seasonAirDate;
        if (s.airDate != null && s.airDate!.isNotEmpty) {
          seasonAirDate = DateTime.tryParse(s.airDate!);
        }

        await mediaDao.upsertSeason(
          SeasonsCompanion.insert(
            id: Value(seasonId),
            mediaId: titleId,
            seasonNumber: s.seasonNumber,
            name: s.name,
            overview: Value(s.overview),
            posterPath: Value(s.posterPath),
            episodeCount: Value(s.episodeCount),
            airDate: Value(seasonAirDate),
            updatedAt: Value(DateTime.now()),
            deletedAt: const Value(null),
          ),
        );
      }
    }

    return (await mediaDao.getTitleById(titleId))!;
  }

  Future<List<Episode>> getOrFetchEpisodes({
    required String mediaId,
    required String seasonId,
    required int tvTmdbId,
    required int seasonNumber,
  }) async {
    final cached = await mediaDao.getEpisodesForSeason(seasonId);
    if (cached.isNotEmpty) {
      return cached;
    }

    final episodes = await tmdbService.getSeasonDetails(tvTmdbId, seasonNumber);
    for (final ep in episodes) {
      final epId = generateUuidV7();
      DateTime? epAirDate;
      if (ep.airDate != null && ep.airDate!.isNotEmpty) {
        epAirDate = DateTime.tryParse(ep.airDate!);
      }

      await mediaDao.upsertEpisode(
        EpisodesCompanion.insert(
          id: Value(epId),
          seasonId: seasonId,
          mediaId: mediaId,
          episodeNumber: ep.episodeNumber,
          title: ep.name,
          overview: Value(ep.overview),
          stillPath: Value(ep.stillPath),
          runtimeMinutes: Value(ep.runtimeMinutes),
          airDate: Value(epAirDate),
          updatedAt: Value(DateTime.now()),
          deletedAt: const Value(null),
        ),
      );
    }

    return mediaDao.getEpisodesForSeason(seasonId);
  }

  Future<MediaTitle?> getLocalTitleByTmdb(String tmdbId, String mediaType) {
    return mediaDao.getTitleByTmdbId(tmdbId, mediaType);
  }

  Future<MediaTitle?> getLocalTitleById(String id) {
    return mediaDao.getTitleById(id);
  }

  Future<List<Season>> getSeasonsForMedia(String mediaId) {
    return mediaDao.getSeasonsForMedia(mediaId);
  }
}

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  final tmdbService = ref.watch(tmdbApiServiceProvider);
  final mediaDao = ref.watch(mediaDaoProvider);
  return MediaRepository(
    tmdbService: tmdbService,
    mediaDao: mediaDao,
  );
});
