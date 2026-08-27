import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watchmark/core/database/app_database.dart';
import 'package:watchmark/core/database/daos/library_dao.dart';
import 'package:watchmark/core/database/daos/media_dao.dart';
import 'package:watchmark/core/utilities/uuid_helper.dart';

void main() {
  late AppDatabase db;
  late LibraryDao libraryDao;
  late MediaDao mediaDao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    libraryDao = db.libraryDao;
    mediaDao = db.mediaDao;
  });

  tearDown(() async {
    await db.close();
  });

  test('updateLibraryStatus updates status without wiping progressSeconds or season info', () async {
    final mediaId = generateUuidV7();
    await mediaDao.upsertTitle(
      MediaTitlesCompanion.insert(
        id: drift.Value(mediaId),
        tmdbId: '100',
        mediaType: 'movie',
        title: 'Test Movie',
        updatedAt: drift.Value(DateTime.now()),
      ),
    );

    final entryId = generateUuidV7();
    await libraryDao.upsertLibraryEntry(
      LibraryEntriesCompanion.insert(
        id: drift.Value(entryId),
        mediaId: mediaId,
        status: 'watching',
        progressSeconds: const drift.Value(4500),
        currentSeason: const drift.Value(2),
        currentEpisode: const drift.Value(4),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );

    // Update status to paused
    await libraryDao.updateLibraryStatus(entryId, 'paused');

    final updated = await libraryDao.getLibraryEntryByMediaId(mediaId);
    expect(updated, isNotNull);
    expect(updated!.status, 'paused');
    expect(updated.progressSeconds, 4500);
    expect(updated.currentSeason, 2);
    expect(updated.currentEpisode, 4);
  });
}
