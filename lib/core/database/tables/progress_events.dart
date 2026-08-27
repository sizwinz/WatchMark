import 'package:drift/drift.dart';
import 'package:watchmark/core/database/tables/episodes.dart';
import 'package:watchmark/core/database/tables/media_titles.dart';
import 'package:watchmark/core/utilities/uuid_helper.dart';

class ProgressEvents extends Table {
  TextColumn get id => text().clientDefault(generateUuidV7)();
  TextColumn get mediaId => text().references(MediaTitles, #id)();
  TextColumn get episodeId => text().references(Episodes, #id).nullable()();
  IntColumn get positionSeconds => integer()();
  IntColumn get durationSeconds => integer().nullable()();
  TextColumn get deviceId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
