import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchmark/core/database/daos/sessions_dao.dart';
import 'package:watchmark/shared/providers/database_provider.dart';

class HistoryGroup {
  final String title;
  final List<WatchSessionWithMedia> items;
  final int totalMinutes;

  const HistoryGroup({
    required this.title,
    required this.items,
    required this.totalMinutes,
  });
}

final groupedHistoryStreamProvider =
    StreamProvider.autoDispose<List<HistoryGroup>>((ref) {
  final sessionsDao = ref.watch(sessionsDaoProvider);

  return sessionsDao.watchAllSessionsWithMedia().map((sessions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeekStart = today.subtract(const Duration(days: 7));

    final todayItems = <WatchSessionWithMedia>[];
    final yesterdayItems = <WatchSessionWithMedia>[];
    final thisWeekItems = <WatchSessionWithMedia>[];
    final earlierItems = <WatchSessionWithMedia>[];

    for (final s in sessions) {
      final sessionDate = DateTime(
        s.session.startedAt.year,
        s.session.startedAt.month,
        s.session.startedAt.day,
      );

      if (sessionDate.isAtSameMomentAs(today) || sessionDate.isAfter(today)) {
        todayItems.add(s);
      } else if (sessionDate.isAtSameMomentAs(yesterday)) {
        yesterdayItems.add(s);
      } else if (sessionDate.isAfter(thisWeekStart)) {
        thisWeekItems.add(s);
      } else {
        earlierItems.add(s);
      }
    }

    final groups = <HistoryGroup>[];

    int calcMins(List<WatchSessionWithMedia> list) {
      int total = 0;
      for (final i in list) {
        total += (i.session.positionAfterSeconds - i.session.positionBeforeSeconds);
      }
      return (total / 60).round();
    }

    if (todayItems.isNotEmpty) {
      groups.add(HistoryGroup(title: 'Today', items: todayItems, totalMinutes: calcMins(todayItems)));
    }
    if (yesterdayItems.isNotEmpty) {
      groups.add(HistoryGroup(title: 'Yesterday', items: yesterdayItems, totalMinutes: calcMins(yesterdayItems)));
    }
    if (thisWeekItems.isNotEmpty) {
      groups.add(HistoryGroup(title: 'This Week', items: thisWeekItems, totalMinutes: calcMins(thisWeekItems)));
    }
    if (earlierItems.isNotEmpty) {
      groups.add(HistoryGroup(title: 'Earlier', items: earlierItems, totalMinutes: calcMins(earlierItems)));
    }

    return groups;
  });
});
