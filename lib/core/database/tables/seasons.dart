import 'package:drift/drift.dart';
import 'package:watchmark/core/database/tables/media_titles.dart';
import 'package:watchmark/core/utilities/uuid_helper.dart';

class Seasons extends Table {
  TextColumn get id => text().clientDefault(generateUuidV7)();
  TextColumn get mediaId => text().references(MediaTitles, #id)();
  IntColumn get seasonNumber => integer()();
  TextColumn get name => text()();
  TextColumn get overview => text().nullable()();
  TextColumn get posterPath => text().nullable()();
  IntColumn get episodeCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get airDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
