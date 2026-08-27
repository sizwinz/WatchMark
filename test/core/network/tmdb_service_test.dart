import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watchmark/core/database/app_database.dart';
import 'package:watchmark/core/network/api_endpoints.dart';
import 'package:watchmark/core/network/tmdb_api_service.dart';
import 'package:watchmark/core/repositories/media_repository.dart';

void main() {
  late AppDatabase db;
  late MediaRepository repository;
  late TmdbApiService tmdbService;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    tmdbService = TmdbApiService(Dio());
    repository = MediaRepository(
      tmdbService: tmdbService,
      mediaDao: db.mediaDao,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('TMDB API & Networking Tests', () {
    test('ApiEndpoints constructs valid image URLs', () {
      expect(
        ApiEndpoints.posterUrl('/path.jpg'),
        'https://image.tmdb.org/t/p/w500/path.jpg',
      );
      expect(
        ApiEndpoints.backdropUrl('path.jpg'),
        'https://image.tmdb.org/t/p/w1280/path.jpg',
      );
      expect(ApiEndpoints.posterUrl(null), isNull);
    });

    test('TmdbSearchResult correctly parses JSON', () {
      final json = {
        'id': 157336,
        'media_type': 'movie',
        'title': 'Interstellar',
        'overview': 'The adventures of a group of explorers...',
        'poster_path': '/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
        'release_date': '2014-11-05',
        'vote_average': 8.4,
      };

      final result = TmdbSearchResult.fromJson(json);
      expect(result.id, 157336);
      expect(result.mediaType, 'movie');
      expect(result.title, 'Interstellar');
      expect(result.voteAverage, 8.4);
    });

    test('MediaRepository caches TmdbMediaDetail to local Drift SQLite', () async {
      const detail = TmdbMediaDetail(
        id: 550,
        mediaType: 'movie',
        title: 'Fight Club',
        overview: 'An insomniac office worker...',
        posterPath: '/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg',
        releaseDate: '1999-10-15',
        runtimeMinutes: 139,
      );

      final cached = await repository.cacheMediaDetail(detail);
      expect(cached.title, 'Fight Club');
      expect(cached.tmdbId, '550');
      expect(cached.mediaType, 'movie');

      final localTitle = await repository.getLocalTitleByTmdb('550', 'movie');
      expect(localTitle, isNotNull);
      expect(localTitle!.title, 'Fight Club');
      expect(localTitle.runtimeMinutes, 139);
    });
  });
}
