import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchmark/core/network/api_endpoints.dart';
import 'package:watchmark/core/storage/secure_storage_service.dart';

class TmdbAuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;

  TmdbAuthInterceptor(this._secureStorage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final customKey = await _secureStorage.getCustomTmdbApiKey();
      final effectiveKey = (customKey != null && customKey.trim().isNotEmpty)
          ? customKey.trim()
          : ApiEndpoints.defaultTmdbApiKey;

      final queryParams = Map<String, dynamic>.from(options.queryParameters);
      queryParams['api_key'] = effectiveKey;
      options.queryParameters = queryParams;
    } catch (_) {
      final queryParams = Map<String, dynamic>.from(options.queryParameters);
      queryParams['api_key'] = ApiEndpoints.defaultTmdbApiKey;
      options.queryParameters = queryParams;
    }

    handler.next(options);
  }
}

final dioClientProvider = Provider<Dio>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.tmdbBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'WatchMark/1.0.0 (Android; Linux; Flutter; +https://github.com/sizwinz/WatchMark)',
        'Accept-Language': 'en-US,en;q=0.9',
      },
    ),
  );

  dio.interceptors.add(TmdbAuthInterceptor(secureStorage));
  return dio;
});
