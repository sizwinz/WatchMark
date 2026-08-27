import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchmark/core/database/app_database.dart';
import 'package:watchmark/shared/providers/database_provider.dart';

class ContinueWatchingItem {
  final LibraryEntry entry;
  final MediaTitle media;
  final Episode? currentEpisode;
  final int totalRuntimeSeconds;
  final int progressPercentage;

  const ContinueWatchingItem({
    required this.entry,
    required this.media,
    this.currentEpisode,
    required this.totalRuntimeSeconds,
    required this.progressPercentage,
  });
}

class HomeStats {
  final int watchingCount;
  final int pausedCount;
  final int watchlistCount;
  final int completedCount;
  final int totalMinutesWatched;

  const HomeStats({
    this.watchingCount = 0,
    this.pausedCount = 0,
    this.watchlistCount = 0,
    this.completedCount = 0,
    this.totalMinutesWatched = 0,
  });
}

final continueWatchingStreamProvider =
    StreamProvider.autoDispose<List<ContinueWatchingItem>>((ref) {
  final libraryDao = ref.watch(libraryDaoProvider);
  final mediaDao = ref.watch(mediaDaoProvider);

  return libraryDao.watchLibraryWithMedia().asyncMap((items) async {
    final inProgressItems = items
        .where((i) =>
            i.entry.status != 'completed' &&
            i.entry.status != 'dropped' &&
            (i.entry.status == 'watching' || i.entry.status == 'paused' || i.entry.progressSeconds > 0))
        .toList()
      ..sort((a, b) {
        final aDate = a.entry.lastWatchedAt ?? a.entry.updatedAt;
        final bDate = b.entry.lastWatchedAt ?? b.entry.updatedAt;
        return bDate.compareTo(aDate);
      });

    final results = <ContinueWatchingItem>[];

    for (final item in inProgressItems) {
      int totalSeconds = (item.media.runtimeMinutes ?? 120) * 60;
      Episode? episode;

      if (item.media.mediaType == 'tv') {
        final seasonNum = item.entry.currentSeason ?? 1;
        final epNum = item.entry.currentEpisode ?? 1;

        final seasons = await mediaDao.getSeasonsForMedia(item.media.id);
        final season = seasons.where((s) => s.seasonNumber == seasonNum).firstOrNull;

        if (season != null) {
          final eps = await mediaDao.getEpisodesForSeason(season.id);
          episode = eps.where((e) => e.episodeNumber == epNum).firstOrNull;
          if (episode?.runtimeMinutes != null && episode!.runtimeMinutes! > 0) {
            totalSeconds = episode.runtimeMinutes! * 60;
          } else {
            totalSeconds = 45 * 60; // default 45m for episode
          }
        }
      }

      if (totalSeconds <= 0) totalSeconds = 3600;
      final progressSecs = item.entry.progressSeconds;
      final percentage = ((progressSecs / totalSeconds) * 100).clamp(0, 100).toInt();

      results.add(
        ContinueWatchingItem(
          entry: item.entry,
          media: item.media,
          currentEpisode: episode,
          totalRuntimeSeconds: totalSeconds,
          progressPercentage: percentage,
        ),
      );
    }

    return results;
  });
});

final homeStatsProvider = StreamProvider.autoDispose<HomeStats>((ref) {
  final sessionsDao = ref.watch(sessionsDaoProvider);
  final libraryDao = ref.watch(libraryDaoProvider);

  return libraryDao.watchAllLibraryEntries().asyncMap((entries) async {
    int watching = 0;
    int paused = 0;
    int watchlist = 0;
    int completed = 0;

    for (final e in entries) {
      if (e.status == 'watching') watching++;
      if (e.status == 'paused') paused++;
      if (e.status == 'watchlist') watchlist++;
      if (e.status == 'completed') completed++;
    }

    final sessions = await sessionsDao.getAllSessions();
    int totalSecs = 0;
    for (final s in sessions) {
      totalSecs += (s.positionAfterSeconds - s.positionBeforeSeconds);
    }

    return HomeStats(
      watchingCount: watching,
      pausedCount: paused,
      watchlistCount: watchlist,
      completedCount: completed,
      totalMinutesWatched: (totalSecs / 60).round(),
    );
  });
});
