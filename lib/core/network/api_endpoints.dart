class ApiEndpoints {
  ApiEndpoints._();

  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p/';

  // Bundled default TMDB v3 API key for out-of-the-box discovery
  static const String defaultTmdbApiKey = '2dca580c2a14b55200e784d157207b4d';

  static String? posterUrl(String? path, {String size = 'w500'}) {
    if (path == null || path.trim().isEmpty) return null;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$tmdbImageBaseUrl$size$cleanPath';
  }

  static String? backdropUrl(String? path, {String size = 'w1280'}) {
    if (path == null || path.trim().isEmpty) return null;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$tmdbImageBaseUrl$size$cleanPath';
  }

  static String? profileUrl(String? path, {String size = 'w185'}) {
    if (path == null || path.trim().isEmpty) return null;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$tmdbImageBaseUrl$size$cleanPath';
  }

  static String? stillUrl(String? path, {String size = 'w300'}) {
    if (path == null || path.trim().isEmpty) return null;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$tmdbImageBaseUrl$size$cleanPath';
  }
}
