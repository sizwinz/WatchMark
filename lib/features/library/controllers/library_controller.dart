import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchmark/core/database/daos/library_dao.dart';
import 'package:watchmark/shared/providers/database_provider.dart';

enum LibrarySortOrder {
  titleAsc,
  yearDesc,
  dateAddedDesc,
  lastWatchedDesc,
}

class LibraryFilterState {
  final String status; // 'all', 'watching', 'watchlist', 'completed', 'paused', 'dropped'
  final String mediaType; // 'all', 'movie', 'tv'
  final LibrarySortOrder sortOrder;

  const LibraryFilterState({
    this.status = 'all',
    this.mediaType = 'all',
    this.sortOrder = LibrarySortOrder.dateAddedDesc,
  });

  LibraryFilterState copyWith({
    String? status,
    String? mediaType,
    LibrarySortOrder? sortOrder,
  }) {
    return LibraryFilterState(
      status: status ?? this.status,
      mediaType: mediaType ?? this.mediaType,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class LibraryFilterNotifier extends StateNotifier<LibraryFilterState> {
  LibraryFilterNotifier() : super(const LibraryFilterState());

  void setStatus(String status) {
    state = state.copyWith(status: status);
  }

  void setMediaType(String mediaType) {
    state = state.copyWith(mediaType: mediaType);
  }

  void setSortOrder(LibrarySortOrder sortOrder) {
    state = state.copyWith(sortOrder: sortOrder);
  }
}

final libraryFilterProvider =
    StateNotifierProvider<LibraryFilterNotifier, LibraryFilterState>((ref) {
  return LibraryFilterNotifier();
});

final rawLibraryItemsStreamProvider =
    StreamProvider.autoDispose<List<LibraryItemWithMedia>>((ref) {
  final libraryDao = ref.watch(libraryDaoProvider);
  return libraryDao.watchLibraryWithMedia();
});

final filteredLibraryItemsProvider =
    Provider.autoDispose<AsyncValue<List<LibraryItemWithMedia>>>((ref) {
  final rawItemsAsync = ref.watch(rawLibraryItemsStreamProvider);
  final filter = ref.watch(libraryFilterProvider);

  return rawItemsAsync.whenData((items) {
    var filtered = items.where((item) {
      if (filter.status != 'all' && item.entry.status != filter.status) {
        return false;
      }
      if (filter.mediaType != 'all' && item.media.mediaType != filter.mediaType) {
        return false;
      }
      return true;
    }).toList();

    switch (filter.sortOrder) {
      case LibrarySortOrder.titleAsc:
        filtered.sort((a, b) =>
            a.media.title.toLowerCase().compareTo(b.media.title.toLowerCase()));
        break;
      case LibrarySortOrder.yearDesc:
        filtered.sort((a, b) {
          final aDate = a.media.releaseDate ?? DateTime(1900);
          final bDate = b.media.releaseDate ?? DateTime(1900);
          return bDate.compareTo(aDate);
        });
        break;
      case LibrarySortOrder.dateAddedDesc:
        filtered.sort((a, b) => b.entry.createdAt.compareTo(a.entry.createdAt));
        break;
      case LibrarySortOrder.lastWatchedDesc:
        filtered.sort((a, b) {
          final aTime = a.entry.lastWatchedAt ?? a.entry.updatedAt;
          final bTime = b.entry.lastWatchedAt ?? b.entry.updatedAt;
          return bTime.compareTo(aTime);
        });
        break;
    }

    return filtered;
  });
});

final libraryStatusCountsProvider =
    Provider.autoDispose<Map<String, int>>((ref) {
  final rawItemsAsync = ref.watch(rawLibraryItemsStreamProvider);
  return rawItemsAsync.maybeWhen(
    data: (items) {
      final counts = <String, int>{
        'all': items.length,
        'watching': 0,
        'watchlist': 0,
        'completed': 0,
        'paused': 0,
        'dropped': 0,
      };

      for (final item in items) {
        final st = item.entry.status;
        if (counts.containsKey(st)) {
          counts[st] = (counts[st] ?? 0) + 1;
        }
      }

      return counts;
    },
    orElse: () => {
      'all': 0,
      'watching': 0,
      'watchlist': 0,
      'completed': 0,
      'paused': 0,
      'dropped': 0,
    },
  );
});
