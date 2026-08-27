import 'dart:convert';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchmark/core/database/app_database.dart';
import 'package:watchmark/shared/providers/database_provider.dart';

class BackupValidationResult {
  final bool isValid;
  final String? errorMessage;
  final int titleCount;
  final int seasonCount;
  final int episodeCount;
  final int libraryCount;
  final int sessionCount;
  final int ratingCount;
  final DateTime? exportedAt;
  final int? version;

  const BackupValidationResult({
    required this.isValid,
    this.errorMessage,
    this.titleCount = 0,
    this.seasonCount = 0,
    this.episodeCount = 0,
    this.libraryCount = 0,
    this.sessionCount = 0,
    this.ratingCount = 0,
    this.exportedAt,
    this.version,
  });
}

class BackupService {
  final AppDatabase db;

  BackupService(this.db);

  Future<String> exportBackupJson() async {
    final titles = await db.select(db.mediaTitles).get();
    final seasons = await db.select(db.seasons).get();
    final episodes = await db.select(db.episodes).get();
    final library = await db.select(db.libraryEntries).get();
    final sessions = await db.select(db.watchSessions).get();
    final ratings = await db.select(db.userRatings).get();
    final customLists = await db.select(db.customLists).get();
    final customListItems = await db.select(db.customListItems).get();

    final payload = <String, dynamic>{
      'version': 1,
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'app_version': '1.0.0+1',
      'media_titles': titles.map((t) => t.toJson()).toList(),
      'seasons': seasons.map((s) => s.toJson()).toList(),
      'episodes': episodes.map((e) => e.toJson()).toList(),
      'library_entries': library.map((l) => l.toJson()).toList(),
      'watch_sessions': sessions.map((s) => s.toJson()).toList(),
      'user_ratings': ratings.map((r) => r.toJson()).toList(),
      'custom_lists': customLists.map((c) => c.toJson()).toList(),
      'custom_list_items': customListItems.map((cli) => cli.toJson()).toList(),
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(payload);
  }

  BackupValidationResult validateBackupJson(String jsonStr) {
    try {
      final dynamic decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) {
        return const BackupValidationResult(
          isValid: false,
          errorMessage: 'Invalid format: Root element must be a JSON object.',
        );
      }

      final version = decoded['version'];
      if (version == null || version is! int) {
        return const BackupValidationResult(
          isValid: false,
          errorMessage: 'Invalid format: Missing or invalid schema version.',
        );
      }

      if (version != 1) {
        return BackupValidationResult(
          isValid: false,
          errorMessage: 'Unsupported schema version: $version (expected 1).',
        );
      }

      DateTime? exportedAt;
      if (decoded['exported_at'] is String) {
        exportedAt = DateTime.tryParse(decoded['exported_at'] as String);
      }

      final titles = decoded['media_titles'] as List? ?? [];
      final seasons = decoded['seasons'] as List? ?? [];
      final episodes = decoded['episodes'] as List? ?? [];
      final library = decoded['library_entries'] as List? ?? [];
      final sessions = decoded['watch_sessions'] as List? ?? [];
      final ratings = decoded['user_ratings'] as List? ?? [];

      return BackupValidationResult(
        isValid: true,
        version: version,
        exportedAt: exportedAt,
        titleCount: titles.length,
        seasonCount: seasons.length,
        episodeCount: episodes.length,
        libraryCount: library.length,
        sessionCount: sessions.length,
        ratingCount: ratings.length,
      );
    } catch (e) {
      return BackupValidationResult(
        isValid: false,
        errorMessage: 'JSON parse error: $e',
      );
    }
  }

  Future<void> importBackup({
    required String jsonStr,
    required bool overwrite,
  }) async {
    final validation = validateBackupJson(jsonStr);
    if (!validation.isValid) {
      throw ArgumentError('Invalid backup file: ${validation.errorMessage}');
    }

    final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

    await db.transaction(() async {
      if (overwrite) {
        await db.delete(db.customListItems).go();
        await db.delete(db.customLists).go();
        await db.delete(db.userRatings).go();
        await db.delete(db.watchSessions).go();
        await db.delete(db.libraryEntries).go();
        await db.delete(db.episodes).go();
        await db.delete(db.seasons).go();
        await db.delete(db.mediaTitles).go();
      }

      // Media Titles
      if (decoded['media_titles'] is List) {
        for (final item in decoded['media_titles']) {
          final row = MediaTitle.fromJson(item as Map<String, dynamic>);
          await db.into(db.mediaTitles).insertOnConflictUpdate(row);
        }
      }

      // Seasons
      if (decoded['seasons'] is List) {
        for (final item in decoded['seasons']) {
          final row = Season.fromJson(item as Map<String, dynamic>);
          await db.into(db.seasons).insertOnConflictUpdate(row);
        }
      }

      // Episodes
      if (decoded['episodes'] is List) {
        for (final item in decoded['episodes']) {
          final row = Episode.fromJson(item as Map<String, dynamic>);
          await db.into(db.episodes).insertOnConflictUpdate(row);
        }
      }

      // Library Entries
      if (decoded['library_entries'] is List) {
        for (final item in decoded['library_entries']) {
          final row = LibraryEntry.fromJson(item as Map<String, dynamic>);
          await db.into(db.libraryEntries).insertOnConflictUpdate(row);
        }
      }

      // Watch Sessions
      if (decoded['watch_sessions'] is List) {
        for (final item in decoded['watch_sessions']) {
          final row = WatchSession.fromJson(item as Map<String, dynamic>);
          await db.into(db.watchSessions).insertOnConflictUpdate(row);
        }
      }

      // User Ratings
      if (decoded['user_ratings'] is List) {
        for (final item in decoded['user_ratings']) {
          final row = UserRating.fromJson(item as Map<String, dynamic>);
          await db.into(db.userRatings).insertOnConflictUpdate(row);
        }
      }

      // Custom Lists
      if (decoded['custom_lists'] is List) {
        for (final item in decoded['custom_lists']) {
          final row = CustomList.fromJson(item as Map<String, dynamic>);
          await db.into(db.customLists).insertOnConflictUpdate(row);
        }
      }

      // Custom List Items
      if (decoded['custom_list_items'] is List) {
        for (final item in decoded['custom_list_items']) {
          final row = CustomListItem.fromJson(item as Map<String, dynamic>);
          await db.into(db.customListItems).insertOnConflictUpdate(row);
        }
      }
    });
  }

  Future<int> clearMetadataCache() async {
    // Collect media IDs referenced in library or watch sessions
    final library = await db.select(db.libraryEntries).get();
    final sessions = await db.select(db.watchSessions).get();

    final activeMediaIds = <String>{
      ...library.map((l) => l.mediaId),
      ...sessions.map((s) => s.mediaId),
    };

    // Find unreferenced media titles
    final allTitles = await db.select(db.mediaTitles).get();
    final unreferenced = allTitles.where((t) => !activeMediaIds.contains(t.id)).toList();

    int deletedCount = 0;
    await db.transaction(() async {
      for (final title in unreferenced) {
        final titleSeasons = await (db.select(db.seasons)..where((s) => s.mediaId.equals(title.id))).get();
        for (final s in titleSeasons) {
          await (db.delete(db.episodes)..where((e) => e.seasonId.equals(s.id))).go();
        }
        await (db.delete(db.seasons)..where((s) => s.mediaId.equals(title.id))).go();
        await (db.delete(db.mediaTitles)..where((t) => t.id.equals(title.id))).go();
        deletedCount++;
      }
    });

    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    return deletedCount;
  }

  Future<void> resetDatabase() async {
    await db.transaction(() async {
      await db.delete(db.customListItems).go();
      await db.delete(db.customLists).go();
      await db.delete(db.userRatings).go();
      await db.delete(db.watchSessions).go();
      await db.delete(db.libraryEntries).go();
      await db.delete(db.episodes).go();
      await db.delete(db.seasons).go();
      await db.delete(db.mediaTitles).go();
      await db.delete(db.progressEvents).go();
      await db.delete(db.syncEvents).go();
    });

    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  final db = ref.watch(databaseProvider);
  return BackupService(db);
});
