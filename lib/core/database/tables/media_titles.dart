import 'package:drift/drift.dart';
import 'package:watchmark/core/utilities/uuid_helper.dart';

class MediaTitles extends Table {
  TextColumn get id => text().clientDefault(generateUuidV7)();
  TextColumn get tmdbId => text()();
  TextColumn get mediaType => text()(); // 'movie' or 'tv'
  TextColumn get title => text()();
  TextColumn get originalTitle => text().nullable()();
  TextColumn get overview => text().nullable()();
  TextColumn get posterPath => text().nullable()();
  TextColumn get backdropPath => text().nullable()();
  DateTimeColumn get releaseDate => dateTime().nullable()();
  IntColumn get runtimeMinutes => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
