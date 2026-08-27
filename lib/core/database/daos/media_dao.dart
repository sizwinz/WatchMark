import 'package:drift/drift.dart';
import 'package:watchmark/core/database/app_database.dart';
import 'package:watchmark/core/database/tables/episodes.dart';
import 'package:watchmark/core/database/tables/media_titles.dart';
import 'package:watchmark/core/database/tables/seasons.dart';

part 'media_dao.g.dart';

@DriftAccessor(tables: [MediaTitles, Seasons, Episodes])
class MediaDao extends DatabaseAccessor<AppDatabase> with _$MediaDaoMixin {
  MediaDao(super.db);

  Future<List<MediaTitle>> getAllTitles({bool includeDeleted = false}) {
    final query = select(mediaTitles);
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.get();
  }

  Stream<List<MediaTitle>> watchAllTitles({bool includeDeleted = false}) {
    final query = select(mediaTitles);
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.watch();
  }

  Future<MediaTitle?> getTitleById(String id, {bool includeDeleted = false}) {
    final query = select(mediaTitles)..where((tbl) => tbl.id.equals(id));
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  Future<MediaTitle?> getTitleByTmdbId(String tmdbId, String mediaType, {bool includeDeleted = false}) {
    final query = select(mediaTitles)
      ..where((tbl) => tbl.tmdbId.equals(tmdbId) & tbl.mediaType.equals(mediaType));
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  Future<int> upsertTitle(MediaTitlesCompanion entry) {
    return into(mediaTitles).insertOnConflictUpdate(entry);
  }

  Future<int> softDeleteTitle(String id) {
    return (update(mediaTitles)..where((tbl) => tbl.id.equals(id))).write(
      MediaTitlesCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<Season>> getSeasonsForMedia(String mediaId, {bool includeDeleted = false}) {
    final query = select(seasons)
      ..where((tbl) => tbl.mediaId.equals(mediaId))
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.seasonNumber)]);
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.get();
  }

  Future<int> upsertSeason(SeasonsCompanion entry) {
    return into(seasons).insertOnConflictUpdate(entry);
  }

  Future<int> softDeleteSeason(String id) {
    return (update(seasons)..where((tbl) => tbl.id.equals(id))).write(
      SeasonsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<Episode>> getEpisodesForSeason(String seasonId, {bool includeDeleted = false}) {
    final query = select(episodes)
      ..where((tbl) => tbl.seasonId.equals(seasonId))
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.episodeNumber)]);
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.get();
  }

  Future<int> upsertEpisode(EpisodesCompanion entry) {
    return into(episodes).insertOnConflictUpdate(entry);
  }

  Future<int> softDeleteEpisode(String id) {
    return (update(episodes)..where((tbl) => tbl.id.equals(id))).write(
      EpisodesCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
