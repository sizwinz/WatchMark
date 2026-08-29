import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchmark/core/network/api_endpoints.dart';
import 'package:watchmark/core/storage/secure_storage_service.dart';

class _CachedResponse {
  final dynamic data;
  final DateTime timestamp;
  _CachedResponse(this.data, this.timestamp);

  bool isValid(Duration ttl) => DateTime.now().difference(timestamp) < ttl;
}

class TmdbCacheAndRetryInterceptor extends QueuedInterceptor {
  final Dio dio;
  final Map<String, _CachedResponse> _cache = {};
  static const Duration _cacheTtl = Duration(minutes: 5);

  TmdbCacheAndRetryInterceptor(this.dio);

  String _cacheKey(RequestOptions options) {
    final sortedParams = options.queryParameters.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return '${options.path}?${sortedParams.map((e) => '${e.key}=${e.value}').join('&')}';
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method.toUpperCase() == 'GET' && options.extra['skip_cache'] != true) {
      final key = _cacheKey(options);
      final cached = _cache[key];
      if (cached != null && cached.isValid(_cacheTtl)) {
        return handler.resolve(
          Response(
            requestOptions: options,
            data: cached.data,
            statusCode: 200,
          ),
        );
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.method.toUpperCase() == 'GET' &&
        response.statusCode == 200 &&
        response.data != null) {
      final key = _cacheKey(response.requestOptions);
      _cache[key] = _CachedResponse(response.data, DateTime.now());
      if (_cache.length > 150) {
        _cache.remove(_cache.keys.first);
      }
    }
    handler.next(response);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    if (status == 429 || status == 503) {
      final retries = (err.requestOptions.extra['retry_count'] as int?) ?? 0;
      if (retries < 3) {
        err.requestOptions.extra['retry_count'] = retries + 1;
        int delayMs = 1500 * (retries + 1);
        final retryAfterHeader = err.response?.headers.value('retry-after');
        if (retryAfterHeader != null) {
          final parsed = int.tryParse(retryAfterHeader);
          if (parsed != null && parsed > 0 && parsed <= 10) {
            delayMs = parsed * 1000;
          }
        }

        await Future.delayed(Duration(milliseconds: delayMs));
        try {
          final response = await dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          if (e is DioException) {
            return handler.reject(e);
          }
        }
      }
    }
    handler.next(err);
  }
}

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
  dio.interceptors.add(TmdbCacheAndRetryInterceptor(dio));
  return dio;
});
