// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_dao.dart';

// ignore_for_file: type=lint
mixin _$MediaDaoMixin on DatabaseAccessor<AppDatabase> {
  $MediaTitlesTable get mediaTitles => attachedDatabase.mediaTitles;
  $SeasonsTable get seasons => attachedDatabase.seasons;
  $EpisodesTable get episodes => attachedDatabase.episodes;
  MediaDaoManager get managers => MediaDaoManager(this);
}

class MediaDaoManager {
  final _$MediaDaoMixin _db;
  MediaDaoManager(this._db);
  $$MediaTitlesTableTableManager get mediaTitles =>
      $$MediaTitlesTableTableManager(_db.attachedDatabase, _db.mediaTitles);
  $$SeasonsTableTableManager get seasons =>
      $$SeasonsTableTableManager(_db.attachedDatabase, _db.seasons);
  $$EpisodesTableTableManager get episodes =>
      $$EpisodesTableTableManager(_db.attachedDatabase, _db.episodes);
}
