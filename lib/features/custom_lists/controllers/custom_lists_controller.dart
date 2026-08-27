import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchmark/core/database/daos/custom_lists_dao.dart';
import 'package:watchmark/shared/providers/database_provider.dart';

final customListsWithCountsStreamProvider =
    StreamProvider.autoDispose<List<CustomListWithCount>>((ref) {
  final dao = ref.watch(customListsDaoProvider);
  return dao.watchAllListsWithCounts();
});

final customListItemsStreamProvider =
    StreamProvider.autoDispose.family<List<CustomListItemWithMedia>, String>((ref, listId) {
  final dao = ref.watch(customListsDaoProvider);
  return dao.watchItemsForList(listId);
});
