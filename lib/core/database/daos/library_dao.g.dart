// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_dao.dart';

// ignore_for_file: type=lint
mixin _$LibraryDaoMixin on DatabaseAccessor<AppDatabase> {
  $MediaTitlesTable get mediaTitles => attachedDatabase.mediaTitles;
  $LibraryEntriesTable get libraryEntries => attachedDatabase.libraryEntries;
  LibraryDaoManager get managers => LibraryDaoManager(this);
}

class LibraryDaoManager {
  final _$LibraryDaoMixin _db;
  LibraryDaoManager(this._db);
  $$MediaTitlesTableTableManager get mediaTitles =>
      $$MediaTitlesTableTableManager(_db.attachedDatabase, _db.mediaTitles);
  $$LibraryEntriesTableTableManager get libraryEntries =>
      $$LibraryEntriesTableTableManager(
        _db.attachedDatabase,
        _db.libraryEntries,
      );
}
