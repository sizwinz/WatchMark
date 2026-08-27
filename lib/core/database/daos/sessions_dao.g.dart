// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sessions_dao.dart';

// ignore_for_file: type=lint
mixin _$SessionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $MediaTitlesTable get mediaTitles => attachedDatabase.mediaTitles;
  $SeasonsTable get seasons => attachedDatabase.seasons;
  $EpisodesTable get episodes => attachedDatabase.episodes;
  $WatchSessionsTable get watchSessions => attachedDatabase.watchSessions;
  SessionsDaoManager get managers => SessionsDaoManager(this);
}

class SessionsDaoManager {
  final _$SessionsDaoMixin _db;
  SessionsDaoManager(this._db);
  $$MediaTitlesTableTableManager get mediaTitles =>
      $$MediaTitlesTableTableManager(_db.attachedDatabase, _db.mediaTitles);
  $$SeasonsTableTableManager get seasons =>
      $$SeasonsTableTableManager(_db.attachedDatabase, _db.seasons);
  $$EpisodesTableTableManager get episodes =>
      $$EpisodesTableTableManager(_db.attachedDatabase, _db.episodes);
  $$WatchSessionsTableTableManager get watchSessions =>
      $$WatchSessionsTableTableManager(_db.attachedDatabase, _db.watchSessions);
}
