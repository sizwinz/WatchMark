import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:watchmark/app/theme.dart';
import 'package:watchmark/core/database/daos/sessions_dao.dart';
import 'package:watchmark/core/network/api_endpoints.dart';
import 'package:watchmark/shared/providers/database_provider.dart';

class HistorySessionTile extends ConsumerWidget {
  final WatchSessionWithMedia item;
  final VoidCallback onTap;

  const HistorySessionTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0 && m > 0) return '+${h}h ${m}m';
    if (h > 0) return '+${h}h';
    return '+${m}m';
  }

  String _formatPlatform(String? p) {
    switch (p) {
      case 'netflix':
        return 'Netflix';
      case 'prime':
        return 'Prime Video';
      case 'disney':
        return 'Disney+';
      case 'apple_tv':
        return 'Apple TV+';
      case 'max':
        return 'Max';
      case 'hulu':
        return 'Hulu';
      case 'crunchyroll':
        return 'Crunchyroll';
      case 'youtube':
        return 'YouTube';
      case 'local':
        return 'Local';
      default:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final durationSecs = item.session.positionAfterSeconds - item.session.positionBeforeSeconds;
    final posterUrl = ApiEndpoints.posterUrl(item.media.posterPath, size: 'w500');
    final timeStr = DateFormat('h:mm a').format(item.session.startedAt);
    final isMovie = item.media.mediaType == 'movie';

    final subtitle = !isMovie && item.episode != null
        ? 'Episode ${item.episode!.episodeNumber} • ${item.episode!.title}'
        : (item.media.releaseDate != null ? '${item.media.releaseDate!.year}' : 'Movie');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 44,
            height: 64,
            child: posterUrl != null
                ? CachedNetworkImage(
                    imageUrl: posterUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      color: AppTheme.isDark(context) ? const Color(0xFF1E232E) : const Color(0xFFE2E6EE),
                      child: const Icon(Icons.movie_outlined, size: 20),
                    ),
                  )
                : Container(
                    color: AppTheme.isDark(context) ? const Color(0xFF1E232E) : const Color(0xFFE2E6EE),
                    child: const Icon(Icons.movie_outlined, size: 20),
                  ),
          ),
        ),
        title: Text(
          item.media.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context)),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatPlatform(item.session.provider),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeStr,
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context)),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatDuration(durationSecs),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.success),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
              onPressed: () {
                ref.read(sessionsDaoProvider).softDeleteSession(item.session.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
