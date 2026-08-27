import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchmark/core/database/app_database.dart';
import 'package:watchmark/core/database/daos/library_dao.dart';
import 'package:watchmark/core/network/tmdb_api_service.dart';
import 'package:watchmark/core/repositories/media_repository.dart';
import 'package:watchmark/core/utilities/uuid_helper.dart';
import 'package:watchmark/shared/providers/database_provider.dart';

class TitleDetailsState {
  final bool isLoading;
  final TmdbMediaDetail? detail;
  final MediaTitle? localTitle;
  final LibraryEntry? libraryEntry;
  final int selectedSeasonNumber;
  final List<Episode> seasonEpisodes;
  final bool isLoadingSeason;
  final String? errorMessage;

  const TitleDetailsState({
    this.isLoading = true,
    this.detail,
    this.localTitle,
    this.libraryEntry,
    this.selectedSeasonNumber = 1,
    this.seasonEpisodes = const [],
    this.isLoadingSeason = false,
    this.errorMessage,
  });

  TitleDetailsState copyWith({
    bool? isLoading,
    TmdbMediaDetail? detail,
    MediaTitle? localTitle,
    LibraryEntry? libraryEntry,
    int? selectedSeasonNumber,
    List<Episode>? seasonEpisodes,
    bool? isLoadingSeason,
    String? errorMessage,
  }) {
    return TitleDetailsState(
      isLoading: isLoading ?? this.isLoading,
      detail: detail ?? this.detail,
      localTitle: localTitle ?? this.localTitle,
      libraryEntry: libraryEntry ?? this.libraryEntry,
      selectedSeasonNumber: selectedSeasonNumber ?? this.selectedSeasonNumber,
      seasonEpisodes: seasonEpisodes ?? this.seasonEpisodes,
      isLoadingSeason: isLoadingSeason ?? this.isLoadingSeason,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class TitleDetailsController extends StateNotifier<TitleDetailsState> {
  final TmdbApiService tmdbService;
  final MediaRepository mediaRepository;
  final LibraryDao libraryDao;
  final int tmdbId;
  final String mediaType;

  TitleDetailsController({
    required this.tmdbService,
    required this.mediaRepository,
    required this.libraryDao,
    required this.tmdbId,
    required this.mediaType,
  }) : super(const TitleDetailsState()) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      TmdbMediaDetail? detail;
      if (mediaType == 'movie') {
        detail = await tmdbService.getMovieDetails(tmdbId);
      } else {
        detail = await tmdbService.getTvDetails(tmdbId);
      }

      MediaTitle? cachedTitle;
      LibraryEntry? entry;

      if (detail != null) {
        cachedTitle = await mediaRepository.cacheMediaDetail(detail);
        entry = await libraryDao.getLibraryEntryByMediaId(cachedTitle.id);
      } else {
        cachedTitle = await mediaRepository.getLocalTitleByTmdb(tmdbId.toString(), mediaType);
        if (cachedTitle != null) {
          entry = await libraryDao.getLibraryEntryByMediaId(cachedTitle.id);
        }
      }

      int initialSeason = 1;
      if (detail != null && detail.seasons.isNotEmpty) {
        final seasons = detail.seasons;
        initialSeason = seasons
            .firstWhere((s) => s.seasonNumber > 0, orElse: () => seasons.first)
            .seasonNumber;
      }

      state = state.copyWith(
        isLoading: false,
        detail: detail,
        localTitle: cachedTitle,
        libraryEntry: entry,
        selectedSeasonNumber: initialSeason,
      );

      if (mediaType == 'tv' && cachedTitle != null) {
        await selectSeason(initialSeason);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load details: $e',
      );
    }
  }

  Future<void> selectSeason(int seasonNumber) async {
    state = state.copyWith(
      selectedSeasonNumber: seasonNumber,
      isLoadingSeason: true,
    );

    final localTitle = state.localTitle;
    if (localTitle == null) return;

    try {
      final seasons = await mediaRepository.getSeasonsForMedia(localTitle.id);
      final season = seasons.where((s) => s.seasonNumber == seasonNumber).firstOrNull;

      if (season != null) {
        final episodes = await mediaRepository.getOrFetchEpisodes(
          mediaId: localTitle.id,
          seasonId: season.id,
          tvTmdbId: tmdbId,
          seasonNumber: seasonNumber,
        );
        state = state.copyWith(
          seasonEpisodes: episodes,
          isLoadingSeason: false,
        );
      } else {
        state = state.copyWith(
          seasonEpisodes: const [],
          isLoadingSeason: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        seasonEpisodes: const [],
        isLoadingSeason: false,
      );
    }
  }

  Future<void> updateLibraryStatus(String status) async {
    final localTitle = state.localTitle;
    if (localTitle == null) return;

    final existingEntry = state.libraryEntry;
    if (existingEntry != null) {
      await libraryDao.updateLibraryStatus(existingEntry.id, status);
    } else {
      final entryId = generateUuidV7();
      await libraryDao.upsertLibraryEntry(
        LibraryEntriesCompanion.insert(
          id: drift.Value(entryId),
          mediaId: localTitle.id,
          status: status,
          progressSeconds: const drift.Value(0),
          updatedAt: drift.Value(DateTime.now()),
          deletedAt: const drift.Value(null),
        ),
      );
    }

    final updated = await libraryDao.getLibraryEntryByMediaId(localTitle.id);
    state = state.copyWith(libraryEntry: updated);
  }

  Future<void> removeFromLibrary() async {
    final entry = state.libraryEntry;
    if (entry != null) {
      await libraryDao.softDeleteLibraryEntry(entry.id);
      state = state.copyWith(libraryEntry: null);
    }
  }
}

final titleDetailsControllerProvider = StateNotifierProvider.autoDispose
    .family<TitleDetailsController, TitleDetailsState, ({int tmdbId, String mediaType})>((ref, arg) {
  final tmdbService = ref.watch(tmdbApiServiceProvider);
  final mediaRepository = ref.watch(mediaRepositoryProvider);
  final libraryDao = ref.watch(libraryDaoProvider);

  return TitleDetailsController(
    tmdbService: tmdbService,
    mediaRepository: mediaRepository,
    libraryDao: libraryDao,
    tmdbId: arg.tmdbId,
    mediaType: arg.mediaType,
  );
});
