import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchmark/core/database/app_database.dart';
import 'package:watchmark/core/database/daos/custom_lists_dao.dart';
import 'package:watchmark/core/database/daos/library_dao.dart';
import 'package:watchmark/core/database/daos/media_dao.dart';
import 'package:watchmark/core/database/daos/sessions_dao.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final mediaDaoProvider = Provider<MediaDao>((ref) {
  return ref.watch(databaseProvider).mediaDao;
});

final libraryDaoProvider = Provider<LibraryDao>((ref) {
  return ref.watch(databaseProvider).libraryDao;
});

final sessionsDaoProvider = Provider<SessionsDao>((ref) {
  return ref.watch(databaseProvider).sessionsDao;
});

final customListsDaoProvider = Provider<CustomListsDao>((ref) {
  return ref.watch(databaseProvider).customListsDao;
});
