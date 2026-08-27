import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:watchmark/core/database/daos/sessions_dao.dart';
import 'package:watchmark/shared/providers/database_provider.dart';

class MonthlyStats {
  final String monthKey; // e.g. "2026-08"
  final String monthLabel; // e.g. "Aug"
  final int minutes;
  final double relativePercentage; // 0.0 to 1.0 relative to peak month

  const MonthlyStats({
    required this.monthKey,
    required this.monthLabel,
    required this.minutes,
    required this.relativePercentage,
  });
}

class PlatformStats {
  final String platformId;
  final String displayName;
  final int colorValue;
  final int minutes;
  final double percentage; // 0.0 to 100.0

  const PlatformStats({
    required this.platformId,
    required this.displayName,
    required this.colorValue,
    required this.minutes,
    required this.percentage,
  });
}

class GenreStats {
  final String genreName;
  final int minutes;
  final int count;

  const GenreStats({
    required this.genreName,
    required this.minutes,
    required this.count,
  });
}

class ViewingStats {
  final int totalMinutes;
  final int moviesMinutes;
  final int episodesMinutes;
  final int totalSessions;
  final List<MonthlyStats> monthlyBreakdown;
  final List<PlatformStats> platformBreakdown;
  final List<GenreStats> topGenres;

  const ViewingStats({
    this.totalMinutes = 0,
    this.moviesMinutes = 0,
    this.episodesMinutes = 0,
    this.totalSessions = 0,
    this.monthlyBreakdown = const [],
    this.platformBreakdown = const [],
    this.topGenres = const [],
  });

  String get formattedTotalTime {
    final days = totalMinutes ~/ (24 * 60);
    final hours = (totalMinutes % (24 * 60)) ~/ 60;
    final mins = totalMinutes % 60;

    if (days > 0) {
      return '$days d $hours h $mins m';
    } else if (hours > 0) {
      return '$hours h $mins m';
    } else {
      return '$mins mins';
    }
  }

  String get formattedMoviesTime {
    final hours = moviesMinutes ~/ 60;
    final mins = moviesMinutes % 60;
    return hours > 0 ? '$hours h $mins m' : '$mins m';
  }

  String get formattedEpisodesTime {
    final hours = episodesMinutes ~/ 60;
    final mins = episodesMinutes % 60;
    return hours > 0 ? '$hours h $mins m' : '$mins m';
  }
}

class StatsService {
  final SessionsDao sessionsDao;

  StatsService(this.sessionsDao);

  Stream<ViewingStats> watchStats() {
    return sessionsDao.watchAllSessionsWithMedia().map((sessionsWithMedia) {
      if (sessionsWithMedia.isEmpty) {
        return const ViewingStats();
      }

      int totalSecs = 0;
      int movieSecs = 0;
      int episodeSecs = 0;

      final monthlyMap = <String, int>{};
      final platformMap = <String, int>{};
      final genreMap = <String, int>{};
      final genreCountMap = <String, int>{};

      for (final item in sessionsWithMedia) {
        final session = item.session;
        final media = item.media;
        final duration = (session.positionAfterSeconds - session.positionBeforeSeconds).clamp(0, 86400);

        totalSecs += duration;
        if (media.mediaType == 'movie') {
          movieSecs += duration;
        } else {
          episodeSecs += duration;
        }

        // Monthly bucket
        final monthKey = DateFormat('yyyy-MM').format(session.startedAt);
        monthlyMap[monthKey] = (monthlyMap[monthKey] ?? 0) + (duration ~/ 60);

        // Platform bucket
        final prov = session.provider;
        final platform = (prov != null && prov.isNotEmpty ? prov : 'other').toLowerCase();
        platformMap[platform] = (platformMap[platform] ?? 0) + (duration ~/ 60);

        // Genres if present in title overview or fallback
        final genres = _extractGenres(media.overview, media.mediaType);
        for (final g in genres) {
          genreMap[g] = (genreMap[g] ?? 0) + (duration ~/ 60);
          genreCountMap[g] = (genreCountMap[g] ?? 0) + 1;
        }
      }

      final totalMins = totalSecs ~/ 60;

      // 1. Monthly Breakdown (Last 6 months)
      final monthlyList = <MonthlyStats>[];
      final now = DateTime.now();
      int peakMonthlyMins = 1;

      for (int i = 5; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final key = DateFormat('yyyy-MM').format(monthDate);
        final mins = monthlyMap[key] ?? 0;
        peakMonthlyMins = max(peakMonthlyMins, mins);
      }

      for (int i = 5; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final key = DateFormat('yyyy-MM').format(monthDate);
        final label = DateFormat('MMM').format(monthDate);
        final mins = monthlyMap[key] ?? 0;
        final relPct = peakMonthlyMins > 0 ? (mins / peakMonthlyMins).clamp(0.0, 1.0) : 0.0;
        monthlyList.add(
          MonthlyStats(
            monthKey: key,
            monthLabel: label,
            minutes: mins,
            relativePercentage: relPct,
          ),
        );
      }

      // 2. Platform Breakdown
      final platformList = <PlatformStats>[];
      platformMap.forEach((platformId, mins) {
        final pct = totalMins > 0 ? (mins / totalMins) * 100.0 : 0.0;
        platformList.add(
          PlatformStats(
            platformId: platformId,
            displayName: _getPlatformName(platformId),
            colorValue: _getPlatformColor(platformId),
            minutes: mins,
            percentage: pct,
          ),
        );
      });
      platformList.sort((a, b) => b.minutes.compareTo(a.minutes));

      // 3. Top Genres
      final genreList = <GenreStats>[];
      genreMap.forEach((genreName, mins) {
        genreList.add(
          GenreStats(
            genreName: genreName,
            minutes: mins,
            count: genreCountMap[genreName] ?? 0,
          ),
        );
      });
      genreList.sort((a, b) => b.minutes.compareTo(a.minutes));

      return ViewingStats(
        totalMinutes: totalMins,
        moviesMinutes: movieSecs ~/ 60,
        episodesMinutes: episodeSecs ~/ 60,
        totalSessions: sessionsWithMedia.length,
        monthlyBreakdown: monthlyList,
        platformBreakdown: platformList,
        topGenres: genreList.take(5).toList(),
      );
    });
  }

  static List<String> _extractGenres(String? overview, String mediaType) {
    if (overview != null && overview.contains('[GENRE:')) {
      try {
        final start = overview.indexOf('[GENRE:') + 7;
        final end = overview.indexOf(']', start);
        if (end != -1) {
          final text = overview.substring(start, end);
          return text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        }
      } catch (_) {}
    }
    return [mediaType == 'movie' ? 'Feature Film' : 'TV Series'];
  }

  static String _getPlatformName(String id) {
    switch (id.toLowerCase()) {
      case 'netflix':
        return 'Netflix';
      case 'prime':
        return 'Prime Video';
      case 'disney':
        return 'Disney+';
      case 'apple':
        return 'Apple TV+';
      case 'max':
        return 'Max';
      case 'hulu':
        return 'Hulu';
      case 'crunchyroll':
        return 'Crunchyroll';
      case 'youtube':
        return 'YouTube';
      default:
        return 'Other';
    }
  }

  static int _getPlatformColor(String id) {
    switch (id.toLowerCase()) {
      case 'netflix':
        return 0xFFE50914;
      case 'prime':
        return 0xFF00A8E1;
      case 'disney':
        return 0xFF113CCF;
      case 'apple':
        return 0xFF999999;
      case 'max':
        return 0xFF5822B4;
      case 'hulu':
        return 0xFF1CE783;
      case 'crunchyroll':
        return 0xFFF47521;
      case 'youtube':
        return 0xFFFF0000;
      default:
        return 0xFF64748B;
    }
  }
}

final statsServiceProvider = Provider<StatsService>((ref) {
  final sessionsDao = ref.watch(sessionsDaoProvider);
  return StatsService(sessionsDao);
});

final viewingStatsStreamProvider = StreamProvider<ViewingStats>((ref) {
  final service = ref.watch(statsServiceProvider);
  return service.watchStats();
});
