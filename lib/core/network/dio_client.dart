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
    final customKey = await _secureStorage.getCustomTmdbApiKey();
    final effectiveKey = (customKey != null && customKey.trim().isNotEmpty)
        ? customKey.trim()
        : ApiEndpoints.defaultTmdbApiKey;

    options.queryParameters['api_key'] = effectiveKey;
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
      headers: {
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(TmdbAuthInterceptor(secureStorage));
  return dio;
});
