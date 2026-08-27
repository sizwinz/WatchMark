import 'package:drift/drift.dart';
import 'package:watchmark/core/database/app_database.dart';
import 'package:watchmark/core/database/tables/custom_list_items.dart';
import 'package:watchmark/core/database/tables/custom_lists.dart';
import 'package:watchmark/core/database/tables/media_titles.dart';
import 'package:watchmark/core/utilities/uuid_helper.dart';

part 'custom_lists_dao.g.dart';

class CustomListWithCount {
  final CustomList list;
  final int itemCount;

  const CustomListWithCount({
    required this.list,
    required this.itemCount,
  });
}

class CustomListItemWithMedia {
  final CustomListItem item;
  final MediaTitle media;

  const CustomListItemWithMedia({
    required this.item,
    required this.media,
  });
}

@DriftAccessor(tables: [CustomLists, CustomListItems, MediaTitles])
class CustomListsDao extends DatabaseAccessor<AppDatabase> with _$CustomListsDaoMixin {
  CustomListsDao(super.db);

  Stream<List<CustomListWithCount>> watchAllListsWithCounts() {
    final countExp = customListItems.id.count();
    final query = select(customLists).join([
      leftOuterJoin(
        customListItems,
        customListItems.listId.equalsExp(customLists.id) & customListItems.deletedAt.isNull(),
      ),
    ])
      ..addColumns([countExp])
      ..where(customLists.deletedAt.isNull())
      ..groupBy([customLists.id])
      ..orderBy([OrderingTerm.desc(customLists.updatedAt)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final list = row.readTable(customLists);
        final count = row.read(countExp) ?? 0;
        return CustomListWithCount(list: list, itemCount: count);
      }).toList();
    });
  }

  Future<CustomList?> getListById(String id) {
    return (select(customLists)..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
  }

  Future<void> createList(CustomListsCompanion companion) {
    return into(customLists).insert(companion);
  }

  Future<void> updateList(CustomListsCompanion companion) {
    return (update(customLists)..where((t) => t.id.equals(companion.id.value))).write(companion);
  }

  Future<void> deleteList(String id) async {
    final now = DateTime.now();
    await (update(customLists)..where((t) => t.id.equals(id))).write(
      CustomListsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    await (update(customListItems)..where((t) => t.listId.equals(id))).write(
      CustomListItemsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Stream<List<CustomListItemWithMedia>> watchItemsForList(String listId) {
    final query = select(customListItems).join([
      innerJoin(mediaTitles, mediaTitles.id.equalsExp(customListItems.mediaId)),
    ])
      ..where(customListItems.listId.equals(listId) & customListItems.deletedAt.isNull())
      ..orderBy([OrderingTerm.asc(customListItems.position)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return CustomListItemWithMedia(
          item: row.readTable(customListItems),
          media: row.readTable(mediaTitles),
        );
      }).toList();
    });
  }

  Future<void> addMediaToList({
    required String listId,
    required String mediaId,
    String? notes,
  }) async {
    // Check if already in list
    final existing = await (select(customListItems)
          ..where((t) => t.listId.equals(listId) & t.mediaId.equals(mediaId) & t.deletedAt.isNull()))
        .getSingleOrNull();

    if (existing != null) return;

    final count = await (select(customListItems)
          ..where((t) => t.listId.equals(listId) & t.deletedAt.isNull()))
        .get()
        .then((items) => items.length);

    await into(customListItems).insert(
      CustomListItemsCompanion.insert(
        id: Value(generateUuidV7()),
        listId: listId,
        mediaId: mediaId,
        position: Value(count),
        notes: Value(notes),
        updatedAt: Value(DateTime.now()),
      ),
    );

    await (update(customLists)..where((t) => t.id.equals(listId))).write(
      CustomListsCompanion(updatedAt: Value(DateTime.now())),
    );
  }

  Future<void> removeMediaFromList({
    required String listId,
    required String mediaId,
  }) async {
    await (delete(customListItems)..where((t) => t.listId.equals(listId) & t.mediaId.equals(mediaId))).go();
    await (update(customLists)..where((t) => t.id.equals(listId))).write(
      CustomListsCompanion(updatedAt: Value(DateTime.now())),
    );
  }

  Future<List<String>> getListsContainingMedia(String mediaId) async {
    final items = await (select(customListItems)
          ..where((t) => t.mediaId.equals(mediaId) & t.deletedAt.isNull()))
        .get();
    return items.map((i) => i.listId).toList();
  }

  Future<void> reorderItems(String listId, List<String> orderedItemIds) async {
    await batch((batch) {
      for (int i = 0; i < orderedItemIds.length; i++) {
        final itemId = orderedItemIds[i];
        batch.update(
          customListItems,
          CustomListItemsCompanion(position: Value(i), updatedAt: Value(DateTime.now())),
          where: (t) => t.id.equals(itemId),
        );
      }
    });
  }
}
