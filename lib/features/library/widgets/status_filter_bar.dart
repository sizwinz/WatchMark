import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchmark/app/theme.dart';
import 'package:watchmark/features/library/controllers/library_controller.dart';

class StatusFilterBar extends ConsumerWidget {
  const StatusFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStatus = ref.watch(
      libraryFilterProvider.select((s) => s.status),
    );
    final counts = ref.watch(libraryStatusCountsProvider);

    final tabs = [
      ('all', 'All', counts['all'] ?? 0),
      ('watching', 'Watching', counts['watching'] ?? 0),
      ('watchlist', 'Watchlist', counts['watchlist'] ?? 0),
      ('completed', 'Completed', counts['completed'] ?? 0),
      ('paused', 'Paused', counts['paused'] ?? 0),
      ('dropped', 'Dropped', counts['dropped'] ?? 0),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: tabs.map((tab) {
          final isSelected = currentStatus == tab.$1;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                ref.read(libraryFilterProvider.notifier).setStatus(tab.$1);
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary.withValues(alpha: 0.18) : AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : AppTheme.border(context),
                    width: isSelected ? 1.2 : 1,
                  ),
                ),
                child: Text(
                  '${tab.$2} (${tab.$3})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppTheme.textPrimary(context) : AppTheme.textMuted(context),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
