import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  final SharedPreferences? _preferences;

  SecureStorageService([SharedPreferences? preferences]) : _preferences = preferences;

  static const String _tmdbApiKey = 'tmdb_api_key';

  Future<String?> getCustomTmdbApiKey() async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    return prefs.getString(_tmdbApiKey);
  }

  Future<void> setCustomTmdbApiKey(String key) async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    await prefs.setString(_tmdbApiKey, key.trim());
  }

  Future<void> clearCustomTmdbApiKey() async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    await prefs.remove(_tmdbApiKey);
  }
}

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
