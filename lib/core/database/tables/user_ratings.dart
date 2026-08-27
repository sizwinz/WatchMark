import 'package:drift/drift.dart';
import 'package:watchmark/core/database/tables/media_titles.dart';
import 'package:watchmark/core/utilities/uuid_helper.dart';

class UserRatings extends Table {
  TextColumn get id => text().clientDefault(generateUuidV7)();
  TextColumn get mediaId => text().references(MediaTitles, #id)();
  RealColumn get rating => real()(); // 1.0 to 10.0
  TextColumn get review => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
