import 'package:drift/drift.dart';
import 'package:watchmark/core/database/tables/media_titles.dart';
import 'package:watchmark/core/utilities/uuid_helper.dart';

class LibraryEntries extends Table {
  TextColumn get id => text().clientDefault(generateUuidV7)();
  TextColumn get mediaId => text().references(MediaTitles, #id)();
  TextColumn get status => text()(); // watchlist, watching, completed, paused, dropped
  IntColumn get progressSeconds => integer().withDefault(const Constant(0))();
  IntColumn get currentSeason => integer().nullable()();
  IntColumn get currentEpisode => integer().nullable()();
  DateTimeColumn get lastWatchedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
