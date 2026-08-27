import 'package:drift/drift.dart';
import 'package:watchmark/core/utilities/uuid_helper.dart';

class CustomLists extends Table {
  TextColumn get id => text().clientDefault(generateUuidV7)();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  BoolColumn get isRanked => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
