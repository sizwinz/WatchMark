import 'dart:math';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchmark/core/database/app_database.dart';
import 'package:watchmark/shared/providers/database_provider.dart';

class ConflictResolver {
  final AppDatabase db;

  ConflictResolver(this.db);

  Future<void> applyRemoteEvent({
    required String entityType,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    switch (entityType) {
      case 'media_title':
        await _applyMediaTitle(payload, operation);
        break;
      case 'library_entry':
        await _applyLibraryEntry(payload, operation);
        break;
      case 'watch_session':
        await _applyWatchSession(payload, operation);
        break;
      case 'user_rating':
        await _applyUserRating(payload, operation);
        break;
    }
  }

  Future<void> _applyMediaTitle(Map<String, dynamic> payload, String operation) async {
    final remoteTitle = MediaTitle.fromJson(payload);
    final existing = await (db.select(db.mediaTitles)..where((t) => t.id.equals(remoteTitle.id))).getSingleOrNull();

    if (existing == null) {
      await db.into(db.mediaTitles).insertOnConflictUpdate(remoteTitle);
    } else if (remoteTitle.updatedAt.isAfter(existing.updatedAt) || remoteTitle.updatedAt.isAtSameMomentAs(existing.updatedAt)) {
      await db.into(db.mediaTitles).insertOnConflictUpdate(remoteTitle);
    }
  }

  Future<void> _applyLibraryEntry(Map<String, dynamic> payload, String operation) async {
    final remoteEntry = LibraryEntry.fromJson(payload);
    final existing = await (db.select(db.libraryEntries)..where((e) => e.mediaId.equals(remoteEntry.mediaId))).getSingleOrNull();

    if (existing == null) {
      await db.into(db.libraryEntries).insertOnConflictUpdate(remoteEntry);
      return;
    }

    // Furthest Progress Rule
    final mergedProgress = max(existing.progressSeconds, remoteEntry.progressSeconds);

    // Latest Status Timestamp Rule
    final isRemoteNewer = remoteEntry.updatedAt.isAfter(existing.updatedAt) ||
        remoteEntry.updatedAt.isAtSameMomentAs(existing.updatedAt);

    final mergedStatus = isRemoteNewer ? remoteEntry.status : existing.status;
    final mergedSeason = isRemoteNewer ? remoteEntry.currentSeason : existing.currentSeason;
    final mergedEpisode = isRemoteNewer ? remoteEntry.currentEpisode : existing.currentEpisode;
    final mergedLastWatched = (remoteEntry.lastWatchedAt != null && (existing.lastWatchedAt == null || remoteEntry.lastWatchedAt!.isAfter(existing.lastWatchedAt!)))
        ? remoteEntry.lastWatchedAt
        : existing.lastWatchedAt;

    await (db.update(db.libraryEntries)..where((e) => e.id.equals(existing.id))).write(
      LibraryEntriesCompanion(
        status: drift.Value(mergedStatus),
        progressSeconds: drift.Value(mergedProgress),
        currentSeason: drift.Value(mergedSeason),
        currentEpisode: drift.Value(mergedEpisode),
        lastWatchedAt: drift.Value(mergedLastWatched),
        updatedAt: drift.Value(isRemoteNewer ? remoteEntry.updatedAt : existing.updatedAt),
      ),
    );
  }

  Future<void> _applyWatchSession(Map<String, dynamic> payload, String operation) async {
    final remoteSession = WatchSession.fromJson(payload);
    final existing = await (db.select(db.watchSessions)..where((s) => s.id.equals(remoteSession.id))).getSingleOrNull();

    if (existing == null) {
      await db.into(db.watchSessions).insert(remoteSession);
    } else if (remoteSession.deletedAt != null && existing.deletedAt == null) {
      await (db.update(db.watchSessions)..where((s) => s.id.equals(existing.id))).write(
        WatchSessionsCompanion(
          deletedAt: drift.Value(remoteSession.deletedAt),
          updatedAt: drift.Value(remoteSession.updatedAt),
        ),
      );
    }
  }

  Future<void> _applyUserRating(Map<String, dynamic> payload, String operation) async {
    final remoteRating = UserRating.fromJson(payload);
    final existing = await (db.select(db.userRatings)..where((r) => r.id.equals(remoteRating.id))).getSingleOrNull();

    if (existing == null) {
      await db.into(db.userRatings).insertOnConflictUpdate(remoteRating);
    } else if (remoteRating.updatedAt.isAfter(existing.updatedAt) || remoteRating.updatedAt.isAtSameMomentAs(existing.updatedAt)) {
      await db.into(db.userRatings).insertOnConflictUpdate(remoteRating);
    }
  }
}

final conflictResolverProvider = Provider<ConflictResolver>((ref) {
  final db = ref.watch(databaseProvider);
  return ConflictResolver(db);
});
