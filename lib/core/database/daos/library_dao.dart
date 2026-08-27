import 'package:drift/drift.dart';
import 'package:watchmark/core/database/app_database.dart';
import 'package:watchmark/core/database/tables/library_entries.dart';
import 'package:watchmark/core/database/tables/media_titles.dart';

part 'library_dao.g.dart';

class LibraryItemWithMedia {
  final LibraryEntry entry;
  final MediaTitle media;

  const LibraryItemWithMedia({
    required this.entry,
    required this.media,
  });
}

@DriftAccessor(tables: [LibraryEntries, MediaTitles])
class LibraryDao extends DatabaseAccessor<AppDatabase> with _$LibraryDaoMixin {
  LibraryDao(super.db);

  Future<List<LibraryEntry>> getAllLibraryEntries({bool includeDeleted = false}) {
    final query = select(libraryEntries);
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.get();
  }

  Stream<List<LibraryEntry>> watchAllLibraryEntries({bool includeDeleted = false}) {
    final query = select(libraryEntries);
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.watch();
  }

  Stream<List<LibraryItemWithMedia>> watchLibraryWithMedia({bool includeDeleted = false}) {
    final query = select(libraryEntries).join([
      innerJoin(mediaTitles, mediaTitles.id.equalsExp(libraryEntries.mediaId)),
    ]);
    if (!includeDeleted) {
      query.where(libraryEntries.deletedAt.isNull() & mediaTitles.deletedAt.isNull());
    }
    return query.watch().map((rows) {
      return rows.map((row) {
        return LibraryItemWithMedia(
          entry: row.readTable(libraryEntries),
          media: row.readTable(mediaTitles),
        );
      }).toList();
    });
  }

  Future<LibraryEntry?> getLibraryEntryByMediaId(String mediaId, {bool includeDeleted = false}) {
    final query = select(libraryEntries)..where((tbl) => tbl.mediaId.equals(mediaId));
    if (!includeDeleted) {
      query.where((tbl) => tbl.deletedAt.isNull());
    }
    return query.getSingleOrNull();
  }

  Future<int> upsertLibraryEntry(LibraryEntriesCompanion entry) {
    return into(libraryEntries).insertOnConflictUpdate(entry);
  }

  Future<int> updateProgress(String id, int progressSeconds, {int? season, int? episode}) {
    return (update(libraryEntries)..where((tbl) => tbl.id.equals(id))).write(
      LibraryEntriesCompanion(
        progressSeconds: Value(progressSeconds),
        currentSeason: season != null ? Value(season) : const Value.absent(),
        currentEpisode: episode != null ? Value(episode) : const Value.absent(),
        lastWatchedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> updateLibraryStatus(String id, String status) {
    return (update(libraryEntries)..where((tbl) => tbl.id.equals(id))).write(
      LibraryEntriesCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> softDeleteLibraryEntry(String id) {
    return (update(libraryEntries)..where((tbl) => tbl.id.equals(id))).write(
      LibraryEntriesCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
