import 'package:drift/drift.dart';
import 'package:watchmark/core/utilities/uuid_helper.dart';

class SyncEvents extends Table {
  TextColumn get id => text().clientDefault(generateUuidV7)();
  TextColumn get entityType => text()(); // media_title, library_entry, watch_session, user_rating, custom_list
  TextColumn get entityId => text()();
  TextColumn get operation => text()(); // upsert, delete
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  TextColumn get deviceId => text()();
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();
  TextColumn get payloadJson => text()();
  BoolColumn get isUploaded => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
