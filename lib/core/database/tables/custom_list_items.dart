import 'package:drift/drift.dart';
import 'package:watchmark/core/database/tables/custom_lists.dart';
import 'package:watchmark/core/database/tables/media_titles.dart';
import 'package:watchmark/core/utilities/uuid_helper.dart';

class CustomListItems extends Table {
  TextColumn get id => text().clientDefault(generateUuidV7)();
  TextColumn get listId => text().references(CustomLists, #id)();
  TextColumn get mediaId => text().references(MediaTitles, #id)();
  IntColumn get position => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
