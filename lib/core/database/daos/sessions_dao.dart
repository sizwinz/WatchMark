import 'package:drift/drift.dart';
import 'package:watchmark/core/database/app_database.dart';
import 'package:watchmark/core/database/tables/episodes.dart';
import 'package:watchmark/core/database/tables/media_titles.dart';
import 'package:watchmark/core/database/tables/watch_sessions.dart';

part 'sessions_dao.g.dart';

class WatchSessionWithMedia {
  final WatchSession session;
  final MediaTitle media;
  final Episode? episode;

  const WatchSessionWithMedia({
    required this.session,
    required this.media,
    this.episode,
  });
}

@DriftAccessor(tables: [WatchSessions, MediaTitles, Episodes])
class SessionsDao extends DatabaseAccessor<AppDatabase> with _$SessionsDaoMixin {
  SessionsDao(super.db);

  Future<List<WatchSession>> getAllSessions({bool includeDeleted = false}) {
    final query = select(watchSessions)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.startedAt)]);
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.get();
  }

  Stream<List<WatchSession>> watchSessionsForMedia(String mediaId, {bool includeDeleted = false}) {
    final query = select(watchSessions)
      ..where((tbl) => tbl.mediaId.equals(mediaId))
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.startedAt)]);
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.watch();
  }

  Stream<List<WatchSessionWithMedia>> watchAllSessionsWithMedia({bool includeDeleted = false}) {
    final query = select(watchSessions).join([
      innerJoin(mediaTitles, mediaTitles.id.equalsExp(watchSessions.mediaId)),
      leftOuterJoin(episodes, episodes.id.equalsExp(watchSessions.episodeId)),
    ])..orderBy([OrderingTerm.desc(watchSessions.startedAt)]);

    if (!includeDeleted) {
      query.where(watchSessions.deletedAt.isNull() & mediaTitles.deletedAt.isNull());
    }

    return query.watch().map((rows) {
      return rows.map((row) {
        return WatchSessionWithMedia(
          session: row.readTable(watchSessions),
          media: row.readTable(mediaTitles),
          episode: row.readTableOrNull(episodes),
        );
      }).toList();
    });
  }

  Future<int> insertSession(WatchSessionsCompanion entry) {
    return into(watchSessions).insert(entry);
  }

  Future<int> softDeleteSession(String id) {
    return (update(watchSessions)..where((tbl) => tbl.id.equals(id))).write(
      WatchSessionsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
