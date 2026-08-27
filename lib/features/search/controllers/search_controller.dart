import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchmark/core/network/tmdb_api_service.dart';

class SearchState {
  final String query;
  final bool isLoading;
  final List<TmdbSearchResult> results;
  final String? errorMessage;
  final List<String> recentQueries;
  final List<TmdbSearchResult> trendingResults;
  final bool isLoadingTrending;
  final String trendingCategory; // 'all', 'movie', 'tv'

  const SearchState({
    this.query = '',
    this.isLoading = false,
    this.results = const [],
    this.errorMessage,
    this.recentQueries = const [],
    this.trendingResults = const [],
    this.isLoadingTrending = false,
    this.trendingCategory = 'all',
  });

  SearchState copyWith({
    String? query,
    bool? isLoading,
    List<TmdbSearchResult>? results,
    String? errorMessage,
    List<String>? recentQueries,
    List<TmdbSearchResult>? trendingResults,
    bool? isLoadingTrending,
    String? trendingCategory,
  }) {
    return SearchState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      results: results ?? this.results,
      errorMessage: errorMessage,
      recentQueries: recentQueries ?? this.recentQueries,
      trendingResults: trendingResults ?? this.trendingResults,
      isLoadingTrending: isLoadingTrending ?? this.isLoadingTrending,
      trendingCategory: trendingCategory ?? this.trendingCategory,
    );
  }
}

class SearchStateNotifier extends StateNotifier<SearchState> {
  final TmdbApiService _tmdbService;
  Timer? _debounceTimer;

  SearchStateNotifier(this._tmdbService) : super(const SearchState());

  Future<void> loadTrending({String? category}) async {
    final cat = category ?? state.trendingCategory;
    state = state.copyWith(isLoadingTrending: true, trendingCategory: cat);

    try {
      List<TmdbSearchResult> results;
      if (cat == 'movie') {
        results = await _tmdbService.getPopularMovies();
      } else if (cat == 'tv') {
        results = await _tmdbService.getPopularTv();
      } else {
        results = await _tmdbService.getTrending();
      }

      state = state.copyWith(
        trendingResults: results,
        isLoadingTrending: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingTrending: false);
    }
  }

  void setTrendingCategory(String category) {
    if (state.trendingCategory == category) return;
    loadTrending(category: category);
  }

  void onQueryChanged(String newQuery) {
    _debounceTimer?.cancel();
    state = state.copyWith(query: newQuery);

    final cleanQuery = newQuery.trim();
    if (cleanQuery.length < 2) {
      state = state.copyWith(
        results: const [],
        isLoading: false,
        errorMessage: null,
      );
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _executeSearch(cleanQuery);
    });
  }

  Future<void> _executeSearch(String query) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final results = await _tmdbService.multiSearch(query);
      _addRecentQuery(query);
      state = state.copyWith(
        results: results,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        results: const [],
        isLoading: false,
        errorMessage: 'Failed to load search results',
      );
    }
  }

  void selectRecentQuery(String query) {
    onQueryChanged(query);
    _executeSearch(query);
  }

  void _addRecentQuery(String query) {
    final clean = query.trim();
    if (clean.isEmpty) return;

    final updated = List<String>.from(state.recentQueries);
    updated.remove(clean);
    updated.insert(0, clean);
    if (updated.length > 10) {
      updated.removeLast();
    }
    state = state.copyWith(recentQueries: updated);
  }

  void removeRecentQuery(String query) {
    final updated = List<String>.from(state.recentQueries)..remove(query);
    state = state.copyWith(recentQueries: updated);
  }

  void clearRecentQueries() {
    state = state.copyWith(recentQueries: const []);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final searchControllerProvider =
    StateNotifierProvider<SearchStateNotifier, SearchState>((ref) {
  final tmdbService = ref.watch(tmdbApiServiceProvider);
  return SearchStateNotifier(tmdbService);
});
