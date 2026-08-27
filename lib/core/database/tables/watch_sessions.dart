import 'package:drift/drift.dart';
import 'package:watchmark/core/database/tables/episodes.dart';
import 'package:watchmark/core/database/tables/media_titles.dart';
import 'package:watchmark/core/utilities/uuid_helper.dart';

class WatchSessions extends Table {
  TextColumn get id => text().clientDefault(generateUuidV7)();
  TextColumn get mediaId => text().references(MediaTitles, #id)();
  TextColumn get episodeId => text().references(Episodes, #id).nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();
  IntColumn get positionBeforeSeconds => integer().withDefault(const Constant(0))();
  IntColumn get positionAfterSeconds => integer()();
  TextColumn get provider => text().nullable()();
  TextColumn get entryMethod => text().withDefault(const Constant('manual'))(); // manual, quick_increment, external
  TextColumn get deviceId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
