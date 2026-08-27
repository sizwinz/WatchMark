import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchmark/app/theme.dart';
import 'package:watchmark/core/database/daos/library_dao.dart';
import 'package:watchmark/core/network/api_endpoints.dart';
import 'package:watchmark/shared/providers/database_provider.dart';

class LibraryCard extends ConsumerWidget {
  final LibraryItemWithMedia item;
  final VoidCallback onTap;

  const LibraryCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) {
      if (m > 0) {
        return '${h}h ${m}m';
      }
      return '${h}h';
    }
    return '${m}m';
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'watchlist':
        return 'Watchlist';
      case 'watching':
        return 'Watching';
      case 'completed':
        return 'Completed';
      case 'paused':
        return 'Paused';
      case 'dropped':
        return 'Dropped';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'watchlist':
        return AppTheme.primary;
      case 'watching':
        return AppTheme.primaryDark;
      case 'completed':
        return AppTheme.success;
      case 'paused':
        return AppTheme.warning;
      case 'dropped':
        return Colors.grey;
      default:
        return AppTheme.primary;
    }
  }

  Future<void> _updateStatus(WidgetRef ref, String status) async {
    final libraryDao = ref.read(libraryDaoProvider);
    await libraryDao.updateLibraryStatus(item.entry.id, status);
  }

  Future<void> _removeEntry(WidgetRef ref) async {
    final libraryDao = ref.read(libraryDaoProvider);
    await libraryDao.softDeleteLibraryEntry(item.entry.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posterUrl = ApiEndpoints.posterUrl(item.media.posterPath, size: 'w500');
    final isMovie = item.media.mediaType == 'movie';
    final year = item.media.releaseDate != null ? item.media.releaseDate!.year.toString() : '';
    final statusColor = _getStatusColor(item.entry.status);

    final totalSeconds = (item.media.runtimeMinutes ?? 120) * 60;
    final hasProgress = item.entry.progressSeconds > 0 && item.entry.status != 'completed';
    final progressPct = totalSeconds > 0
        ? ((item.entry.progressSeconds / totalSeconds) * 100).clamp(0, 100).toInt()
        : 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: AppTheme.border(context), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (posterUrl != null)
                    CachedNetworkImage(
                      imageUrl: posterUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppTheme.isDark(context) ? const Color(0xFF161A22) : const Color(0xFFE2E6EE),
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppTheme.isDark(context) ? const Color(0xFF161A22) : const Color(0xFFE2E6EE),
                        child: const Icon(Icons.movie_outlined, size: 36, color: Colors.grey),
                      ),
                    )
                  else
                    Container(
                      color: AppTheme.isDark(context) ? const Color(0xFF161A22) : const Color(0xFFE2E6EE),
                      child: const Center(
                        child: Icon(Icons.movie_outlined, size: 36, color: Colors.grey),
                      ),
                    ),
                  // Status badge top-left
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        _formatStatus(item.entry.status).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // More action menu top-right
                  Positioned(
                    top: 4,
                    right: 4,
                    child: PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.more_vert, size: 18, color: Colors.white),
                      ),
                      onSelected: (action) {
                        if (action == 'remove') {
                          _removeEntry(ref);
                        } else {
                          _updateStatus(ref, action);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'watching', child: Text('Mark as Watching')),
                        PopupMenuItem(value: 'watchlist', child: Text('Mark as Watchlist')),
                        PopupMenuItem(value: 'completed', child: Text('Mark as Completed')),
                        PopupMenuItem(value: 'paused', child: Text('Mark as Paused')),
                        PopupMenuItem(value: 'dropped', child: Text('Mark as Dropped')),
                        PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'remove',
                          child: Text('Remove from Library', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                  // Progress Bar overlay on bottom edge of poster
                  if (hasProgress)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: (progressPct / 100).clamp(0.0, 1.0),
                        backgroundColor: Colors.black.withValues(alpha: 0.35),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        minHeight: 3.5,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.media.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (hasProgress)
                    Text(
                      isMovie
                          ? '${_formatDuration(item.entry.progressSeconds)} / ${_formatDuration(totalSeconds)} ($progressPct%)'
                          : 'S${item.entry.currentSeason ?? 1}:E${item.entry.currentEpisode ?? 1} • ${_formatDuration(item.entry.progressSeconds)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isMovie ? 'Movie' : 'TV Series',
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context)),
                        ),
                        if (year.isNotEmpty)
                          Text(
                            year,
                            style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context)),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
