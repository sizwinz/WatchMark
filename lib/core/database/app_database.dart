import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:watchmark/core/database/daos/custom_lists_dao.dart';
import 'package:watchmark/core/database/daos/library_dao.dart';
import 'package:watchmark/core/database/daos/media_dao.dart';
import 'package:watchmark/core/database/daos/sessions_dao.dart';
import 'package:watchmark/core/database/tables/app_settings.dart';
import 'package:watchmark/core/database/tables/custom_list_items.dart';
import 'package:watchmark/core/database/tables/custom_lists.dart';
import 'package:watchmark/core/database/tables/episodes.dart';
import 'package:watchmark/core/database/tables/library_entries.dart';
import 'package:watchmark/core/database/tables/media_titles.dart';
import 'package:watchmark/core/database/tables/progress_events.dart';
import 'package:watchmark/core/database/tables/seasons.dart';
import 'package:watchmark/core/database/tables/sync_events.dart';
import 'package:watchmark/core/database/tables/user_ratings.dart';
import 'package:watchmark/core/database/tables/watch_sessions.dart';
import 'package:watchmark/core/utilities/uuid_helper.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    MediaTitles,
    Seasons,
    Episodes,
    LibraryEntries,
    WatchSessions,
    ProgressEvents,
    CustomLists,
    CustomListItems,
    UserRatings,
    SyncEvents,
    AppSettings,
  ],
  daos: [
    MediaDao,
    LibraryDao,
    SessionsDao,
    CustomListsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'watchmark_db');
  }
}
