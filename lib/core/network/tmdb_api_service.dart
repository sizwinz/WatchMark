import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchmark/core/network/dio_client.dart';

class TmdbGenre {
  final int id;
  final String name;

  const TmdbGenre({required this.id, required this.name});

  factory TmdbGenre.fromJson(Map<String, dynamic> json) {
    return TmdbGenre(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }
}

class TmdbCastMember {
  final int id;
  final String name;
  final String character;
  final String? profilePath;

  const TmdbCastMember({
    required this.id,
    required this.name,
    required this.character,
    this.profilePath,
  });

  factory TmdbCastMember.fromJson(Map<String, dynamic> json) {
    return TmdbCastMember(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      character: json['character'] as String? ?? '',
      profilePath: json['profile_path'] as String?,
    );
  }
}

class TmdbSeasonSummary {
  final int id;
  final int seasonNumber;
  final String name;
  final String? overview;
  final String? posterPath;
  final int episodeCount;
  final String? airDate;

  const TmdbSeasonSummary({
    required this.id,
    required this.seasonNumber,
    required this.name,
    this.overview,
    this.posterPath,
    required this.episodeCount,
    this.airDate,
  });

  factory TmdbSeasonSummary.fromJson(Map<String, dynamic> json) {
    return TmdbSeasonSummary(
      id: json['id'] as int? ?? 0,
      seasonNumber: json['season_number'] as int? ?? 0,
      name: json['name'] as String? ?? 'Season ${json['season_number'] ?? 1}',
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      episodeCount: json['episode_count'] as int? ?? 0,
      airDate: json['air_date'] as String?,
    );
  }
}

class TmdbEpisode {
  final int id;
  final int seasonNumber;
  final int episodeNumber;
  final String name;
  final String? overview;
  final String? stillPath;
  final int? runtimeMinutes;
  final String? airDate;
  final double? voteAverage;

  const TmdbEpisode({
    required this.id,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.name,
    this.overview,
    this.stillPath,
    this.runtimeMinutes,
    this.airDate,
    this.voteAverage,
  });

  factory TmdbEpisode.fromJson(Map<String, dynamic> json) {
    return TmdbEpisode(
      id: json['id'] as int? ?? 0,
      seasonNumber: json['season_number'] as int? ?? 0,
      episodeNumber: json['episode_number'] as int? ?? 0,
      name: json['name'] as String? ?? 'Episode ${json['episode_number'] ?? 1}',
      overview: json['overview'] as String?,
      stillPath: json['still_path'] as String?,
      runtimeMinutes: json['runtime'] as int?,
      airDate: json['air_date'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
    );
  }
}

class TmdbSearchResult {
  final int id;
  final String mediaType; // 'movie', 'tv'
  final String title;
  final String? originalTitle;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final double? voteAverage;

  const TmdbSearchResult({
    required this.id,
    required this.mediaType,
    required this.title,
    this.originalTitle,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.voteAverage,
  });

  factory TmdbSearchResult.fromJson(Map<String, dynamic> json) {
    final mediaType = json['media_type'] as String? ?? 'movie';
    final isMovie = mediaType == 'movie';

    return TmdbSearchResult(
      id: json['id'] as int? ?? 0,
      mediaType: mediaType,
      title: (isMovie ? json['title'] : json['name']) as String? ?? '',
      originalTitle: (isMovie ? json['original_title'] : json['original_name']) as String?,
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: (isMovie ? json['release_date'] : json['first_air_date']) as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
    );
  }
}

class TmdbMediaDetail {
  final int id;
  final String mediaType;
  final String title;
  final String? originalTitle;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final int? runtimeMinutes;
  final List<TmdbGenre> genres;
  final List<TmdbCastMember> cast;
  final List<TmdbSeasonSummary> seasons;
  final double? voteAverage;

  const TmdbMediaDetail({
    required this.id,
    required this.mediaType,
    required this.title,
    this.originalTitle,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.runtimeMinutes,
    this.genres = const [],
    this.cast = const [],
    this.seasons = const [],
    this.voteAverage,
  });

  factory TmdbMediaDetail.fromMovieJson(Map<String, dynamic> json) {
    final genresList = (json['genres'] as List<dynamic>?)
            ?.map((g) => TmdbGenre.fromJson(g as Map<String, dynamic>))
            .toList() ??
        [];

    final credits = json['credits'] as Map<String, dynamic>?;
    final castList = (credits?['cast'] as List<dynamic>?)
            ?.map((c) => TmdbCastMember.fromJson(c as Map<String, dynamic>))
            .take(15)
            .toList() ??
        [];

    return TmdbMediaDetail(
      id: json['id'] as int? ?? 0,
      mediaType: 'movie',
      title: json['title'] as String? ?? '',
      originalTitle: json['original_title'] as String?,
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: json['release_date'] as String?,
      runtimeMinutes: json['runtime'] as int?,
      genres: genresList,
      cast: castList,
      seasons: const [],
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
    );
  }

  factory TmdbMediaDetail.fromTvJson(Map<String, dynamic> json) {
    final genresList = (json['genres'] as List<dynamic>?)
            ?.map((g) => TmdbGenre.fromJson(g as Map<String, dynamic>))
            .toList() ??
        [];

    final credits = json['credits'] as Map<String, dynamic>?;
    final castList = (credits?['cast'] as List<dynamic>?)
            ?.map((c) => TmdbCastMember.fromJson(c as Map<String, dynamic>))
            .take(15)
            .toList() ??
        [];

    final seasonsList = (json['seasons'] as List<dynamic>?)
            ?.map((s) => TmdbSeasonSummary.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];

    final episodeRunTime = (json['episode_run_time'] as List<dynamic>?)?.firstOrNull as int?;

    return TmdbMediaDetail(
      id: json['id'] as int? ?? 0,
      mediaType: 'tv',
      title: json['name'] as String? ?? '',
      originalTitle: json['original_name'] as String?,
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: json['first_air_date'] as String?,
      runtimeMinutes: episodeRunTime,
      genres: genresList,
      cast: castList,
      seasons: seasonsList,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
    );
  }
}

class TmdbApiService {
  final Dio _dio;

  TmdbApiService(this._dio);

  Future<List<TmdbSearchResult>> multiSearch(String query, {int page = 1}) async {
    if (query.trim().isEmpty) return [];

    try {
      final response = await _dio.get(
        '/search/multi',
        queryParameters: {
          'query': query.trim(),
          'page': page,
          'include_adult': false,
        },
      );

      final results = response.data['results'] as List<dynamic>? ?? [];
      return results
          .where((r) => r['media_type'] == 'movie' || r['media_type'] == 'tv')
          .map((r) => TmdbSearchResult.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<TmdbMediaDetail?> getMovieDetails(int tmdbId) async {
    try {
      final response = await _dio.get(
        '/movie/$tmdbId',
        queryParameters: {
          'append_to_response': 'credits',
        },
      );
      return TmdbMediaDetail.fromMovieJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<TmdbMediaDetail?> getTvDetails(int tmdbId) async {
    try {
      final response = await _dio.get(
        '/tv/$tmdbId',
        queryParameters: {
          'append_to_response': 'credits',
        },
      );
      return TmdbMediaDetail.fromTvJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<List<TmdbEpisode>> getSeasonDetails(int tvTmdbId, int seasonNumber) async {
    try {
      final response = await _dio.get(
        '/tv/$tvTmdbId/season/$seasonNumber',
      );
      final episodes = response.data['episodes'] as List<dynamic>? ?? [];
      return episodes
          .map((e) => TmdbEpisode.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
}

final tmdbApiServiceProvider = Provider<TmdbApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return TmdbApiService(dio);
});
