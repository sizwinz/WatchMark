import 'package:drift/drift.dart';
import 'package:watchmark/core/database/tables/media_titles.dart';
import 'package:watchmark/core/database/tables/seasons.dart';
import 'package:watchmark/core/utilities/uuid_helper.dart';

class Episodes extends Table {
  TextColumn get id => text().clientDefault(generateUuidV7)();
  TextColumn get seasonId => text().references(Seasons, #id)();
  TextColumn get mediaId => text().references(MediaTitles, #id)();
  IntColumn get episodeNumber => integer()();
  TextColumn get title => text()();
  TextColumn get overview => text().nullable()();
  TextColumn get stillPath => text().nullable()();
  IntColumn get runtimeMinutes => integer().nullable()();
  DateTimeColumn get airDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
