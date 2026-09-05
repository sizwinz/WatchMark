import 'dart:async';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchmark/core/database/app_database.dart';
import 'package:watchmark/core/database/daos/library_dao.dart';
import 'package:watchmark/core/network/tmdb_api_service.dart';
import 'package:watchmark/core/repositories/media_repository.dart';
import 'package:watchmark/core/services/progress_service.dart';
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
  final Episode? activeEpisode;
  final int totalEpisodesCount;
  final int watchedEpisodesCount;
  final String? currentPlatform;

  const TitleDetailsState({
    this.isLoading = true,
    this.detail,
    this.localTitle,
    this.libraryEntry,
    this.selectedSeasonNumber = 1,
    this.seasonEpisodes = const [],
    this.isLoadingSeason = false,
    this.errorMessage,
    this.activeEpisode,
    this.totalEpisodesCount = 0,
    this.watchedEpisodesCount = 0,
    this.currentPlatform,
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
    Episode? activeEpisode,
    int? totalEpisodesCount,
    int? watchedEpisodesCount,
    String? currentPlatform,
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
      activeEpisode: activeEpisode ?? this.activeEpisode,
      totalEpisodesCount: totalEpisodesCount ?? this.totalEpisodesCount,
      watchedEpisodesCount: watchedEpisodesCount ?? this.watchedEpisodesCount,
      currentPlatform: currentPlatform ?? this.currentPlatform,
    );
  }
}

class TitleDetailsController extends StateNotifier<TitleDetailsState> {
  final TmdbApiService tmdbService;
  final MediaRepository mediaRepository;
  final LibraryDao libraryDao;
  final ProgressService progressService;
  final int tmdbId;
  final String mediaType;

  StreamSubscription<LibraryEntry?>? _entrySubscription;
  StreamSubscription<List<WatchSession>>? _sessionsSubscription;

  TitleDetailsController({
    required this.tmdbService,
    required this.mediaRepository,
    required this.libraryDao,
    required this.progressService,
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
      int totalEps = 0;
      if (detail != null && detail.seasons.isNotEmpty) {
        final seasons = detail.seasons;
        initialSeason = seasons
            .firstWhere((s) => s.seasonNumber > 0, orElse: () => seasons.first)
            .seasonNumber;

        for (final s in seasons) {
          if (s.seasonNumber > 0) {
            totalEps += s.episodeCount;
          }
        }
      }

      state = state.copyWith(
        isLoading: false,
        detail: detail,
        localTitle: cachedTitle,
        libraryEntry: entry,
        selectedSeasonNumber: initialSeason,
        totalEpisodesCount: totalEps,
      );

      _calculateWatchedCountAndActiveEp(entry);

      if (cachedTitle != null) {
        _entrySubscription?.cancel();
        _entrySubscription = libraryDao.watchLibraryEntryByMediaId(cachedTitle.id).listen((updatedEntry) {
          state = state.copyWith(libraryEntry: updatedEntry);
          _calculateWatchedCountAndActiveEp(updatedEntry);
        });

        _sessionsSubscription?.cancel();
        _sessionsSubscription = progressService.sessionsDao.watchSessionsForMedia(cachedTitle.id).listen((sessions) {
          final latest = sessions.firstOrNull;
          state = state.copyWith(currentPlatform: latest?.provider);
        });
      }

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

  void _calculateWatchedCountAndActiveEp(LibraryEntry? entry) {
    if (mediaType != 'tv' || state.detail == null) return;

    final detail = state.detail!;
    final totalEps = state.totalEpisodesCount > 0
        ? state.totalEpisodesCount
        : detail.seasons.where((s) => s.seasonNumber > 0).fold<int>(0, (sum, s) => sum + s.episodeCount);

    if (entry == null) {
      state = state.copyWith(
        totalEpisodesCount: totalEps,
        watchedEpisodesCount: 0,
        activeEpisode: null,
      );
      return;
    }

    if (entry.status == 'completed') {
      state = state.copyWith(
        totalEpisodesCount: totalEps,
        watchedEpisodesCount: totalEps,
      );
      return;
    }

    final curSeason = entry.currentSeason ?? 1;
    final curEpisode = entry.currentEpisode ?? 1;

    int watched = 0;
    for (final s in detail.seasons) {
      if (s.seasonNumber > 0) {
        if (s.seasonNumber < curSeason) {
          watched += s.episodeCount;
        } else if (s.seasonNumber == curSeason) {
          watched += (curEpisode - 1).clamp(0, s.episodeCount);
        }
      }
    }

    Episode? active;
    for (final ep in state.seasonEpisodes) {
      if (state.selectedSeasonNumber == curSeason && ep.episodeNumber == curEpisode) {
        active = ep;
        break;
      }
    }

    state = state.copyWith(
      totalEpisodesCount: totalEps,
      watchedEpisodesCount: watched.clamp(0, totalEps),
      activeEpisode: active ?? state.activeEpisode,
    );
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

        Episode? active;
        final curSeason = state.libraryEntry?.currentSeason ?? 1;
        final curEpisode = state.libraryEntry?.currentEpisode ?? 1;
        for (final ep in episodes) {
          if (seasonNumber == curSeason && ep.episodeNumber == curEpisode) {
            active = ep;
            break;
          }
        }

        state = state.copyWith(
          seasonEpisodes: episodes,
          isLoadingSeason: false,
          activeEpisode: active ?? state.activeEpisode,
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
          currentSeason: mediaType == 'tv' ? const drift.Value(1) : const drift.Value(null),
          currentEpisode: mediaType == 'tv' ? const drift.Value(1) : const drift.Value(null),
          updatedAt: drift.Value(DateTime.now()),
          deletedAt: const drift.Value(null),
        ),
      );
    }
  }

  Future<void> removeFromLibrary() async {
    final entry = state.libraryEntry;
    if (entry != null) {
      await libraryDao.softDeleteLibraryEntry(entry.id);
      state = state.copyWith(libraryEntry: null);
    }
  }

  Future<void> markEpisodeWatched(int seasonNumber, int episodeNumber, {String? platform}) async {
    final localTitle = state.localTitle;
    if (localTitle == null) return;

    await progressService.markEpisodeWatched(
      mediaId: localTitle.id,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      platform: platform ?? state.currentPlatform,
    );
  }

  Future<void> markMovieWatched({String? platform}) async {
    final localTitle = state.localTitle;
    if (localTitle == null) return;

    await progressService.markMovieWatched(
      mediaId: localTitle.id,
      platform: platform ?? state.currentPlatform,
    );
  }

  Future<void> startWatchingFirstEpisode({String? platform}) async {
    final localTitle = state.localTitle;
    if (localTitle == null) return;

    await progressService.updateProgress(
      mediaId: localTitle.id,
      newProgressSeconds: 0,
      seasonNumber: 1,
      episodeNumber: 1,
      platform: platform ?? state.currentPlatform,
    );
  }

  Future<void> incrementActiveProgress(int deltaSeconds) async {
    final localTitle = state.localTitle;
    if (localTitle == null) return;

    await progressService.incrementProgress(
      mediaId: localTitle.id,
      deltaSeconds: deltaSeconds,
      seasonNumber: state.libraryEntry?.currentSeason,
      episodeNumber: state.libraryEntry?.currentEpisode,
      platform: state.currentPlatform,
    );
  }

  @override
  void dispose() {
    _entrySubscription?.cancel();
    _sessionsSubscription?.cancel();
    super.dispose();
  }
}

final titleDetailsControllerProvider = StateNotifierProvider.autoDispose
    .family<TitleDetailsController, TitleDetailsState, ({int tmdbId, String mediaType})>((ref, arg) {
  final tmdbService = ref.watch(tmdbApiServiceProvider);
  final mediaRepository = ref.watch(mediaRepositoryProvider);
  final libraryDao = ref.watch(libraryDaoProvider);
  final progressService = ref.watch(progressServiceProvider);

  return TitleDetailsController(
    tmdbService: tmdbService,
    mediaRepository: mediaRepository,
    libraryDao: libraryDao,
    progressService: progressService,
    tmdbId: arg.tmdbId,
    mediaType: arg.mediaType,
  );
});
