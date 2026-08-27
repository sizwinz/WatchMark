// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_lists_dao.dart';

// ignore_for_file: type=lint
mixin _$CustomListsDaoMixin on DatabaseAccessor<AppDatabase> {
  $CustomListsTable get customLists => attachedDatabase.customLists;
  $MediaTitlesTable get mediaTitles => attachedDatabase.mediaTitles;
  $CustomListItemsTable get customListItems => attachedDatabase.customListItems;
  CustomListsDaoManager get managers => CustomListsDaoManager(this);
}

class CustomListsDaoManager {
  final _$CustomListsDaoMixin _db;
  CustomListsDaoManager(this._db);
  $$CustomListsTableTableManager get customLists =>
      $$CustomListsTableTableManager(_db.attachedDatabase, _db.customLists);
  $$MediaTitlesTableTableManager get mediaTitles =>
      $$MediaTitlesTableTableManager(_db.attachedDatabase, _db.mediaTitles);
  $$CustomListItemsTableTableManager get customListItems =>
      $$CustomListItemsTableTableManager(
        _db.attachedDatabase,
        _db.customListItems,
      );
}
