import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watchmark/core/database/app_database.dart';
import 'package:watchmark/core/database/daos/custom_lists_dao.dart';

void main() {
  late AppDatabase db;
  late CustomListsDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.customListsDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('CustomListsDao Unit Tests', () {
    test('Create, read, update and delete custom list', () async {
      // 1. Create list
      await dao.createList(
        CustomListsCompanion.insert(
          id: const drift.Value('list-1'),
          name: 'Spooky Season',
          description: const drift.Value('Horror movies for October'),
          isRanked: const drift.Value(true),
        ),
      );

      var lists = await dao.watchAllListsWithCounts().first;
      expect(lists.length, 1);
      expect(lists.first.list.name, 'Spooky Season');
      expect(lists.first.list.isRanked, isTrue);
      expect(lists.first.itemCount, 0);

      // 2. Update list
      await dao.updateList(
        const CustomListsCompanion(
          id: drift.Value('list-1'),
          name: drift.Value('Halloween Marathons'),
        ),
      );

      lists = await dao.watchAllListsWithCounts().first;
      expect(lists.first.list.name, 'Halloween Marathons');

      // 3. Delete list
      await dao.deleteList('list-1');
      lists = await dao.watchAllListsWithCounts().first;
      expect(lists, isEmpty);
    });

    test('Add items, check membership, and reorder items', () async {
      // Create list
      await dao.createList(
        CustomListsCompanion.insert(
          id: const drift.Value('list-sci-fi'),
          name: 'Top Sci-Fi',
          isRanked: const drift.Value(true),
        ),
      );

      // Insert media titles
      await db.mediaDao.upsertTitle(
        MediaTitlesCompanion.insert(
          id: const drift.Value('m-1'),
          tmdbId: '101',
          mediaType: 'movie',
          title: 'Interstellar',
        ),
      );
      await db.mediaDao.upsertTitle(
        MediaTitlesCompanion.insert(
          id: const drift.Value('m-2'),
          tmdbId: '102',
          mediaType: 'movie',
          title: 'Arrival',
        ),
      );

      // Add items
      await dao.addMediaToList(listId: 'list-sci-fi', mediaId: 'm-1');
      await dao.addMediaToList(listId: 'list-sci-fi', mediaId: 'm-2');

      var items = await dao.watchItemsForList('list-sci-fi').first;
      expect(items.length, 2);
      expect(items[0].media.title, 'Interstellar');
      expect(items[1].media.title, 'Arrival');

      // Check membership
      final containing = await dao.getListsContainingMedia('m-1');
      expect(containing, contains('list-sci-fi'));

      // Reorder items: swap position so Arrival is #1
      final item1Id = items[0].item.id;
      final item2Id = items[1].item.id;
      await dao.reorderItems('list-sci-fi', [item2Id, item1Id]);

      items = await dao.watchItemsForList('list-sci-fi').first;
      expect(items[0].media.title, 'Arrival');
      expect(items[1].media.title, 'Interstellar');

      // Remove item
      await dao.removeMediaFromList(listId: 'list-sci-fi', mediaId: 'm-1');
      items = await dao.watchItemsForList('list-sci-fi').first;
      expect(items.length, 1);
      expect(items.first.media.title, 'Arrival');
    });
  });
}
