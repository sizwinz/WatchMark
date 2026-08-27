import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchmark/app/theme.dart';
import 'package:watchmark/core/network/api_endpoints.dart';
import 'package:watchmark/core/services/progress_service.dart';
import 'package:watchmark/features/home/controllers/home_controller.dart';
import 'package:watchmark/features/progress/widgets/progress_modal_sheet.dart';

class ContinueWatchingCard extends ConsumerWidget {
  final ContinueWatchingItem item;
  final VoidCallback onTap;

  const ContinueWatchingCard({
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMovie = item.media.mediaType == 'movie';
    final stillPath = item.currentEpisode?.stillPath ?? item.media.backdropPath ?? item.media.posterPath;
    final imageUrl = ApiEndpoints.backdropUrl(stillPath, size: 'w780') ??
        ApiEndpoints.stillUrl(stillPath, size: 'w300') ??
        ApiEndpoints.posterUrl(stillPath, size: 'w500');

    final subtitle = !isMovie && item.entry.currentSeason != null && item.entry.currentEpisode != null
        ? 'S${item.entry.currentSeason}:E${item.entry.currentEpisode}${item.currentEpisode != null ? ' • ${item.currentEpisode!.title}' : ''}'
        : (item.media.releaseDate != null ? item.media.releaseDate!.year.toString() : 'Movie');

    final elapsedStr = _formatDuration(item.entry.progressSeconds);
    final totalStr = _formatDuration(item.totalRuntimeSeconds);

    return Container(
      width: 260,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with Progress Bar Overlay
            SizedBox(
              height: 125,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null)
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppTheme.isDark(context) ? const Color(0xFF1E232E) : const Color(0xFFE2E6EE),
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppTheme.isDark(context) ? const Color(0xFF1E232E) : const Color(0xFFE2E6EE),
                        child: const Icon(Icons.movie_outlined, size: 40, color: Colors.grey),
                      ),
                    )
                  else
                    Container(
                      color: AppTheme.isDark(context) ? const Color(0xFF1E232E) : const Color(0xFFE2E6EE),
                      child: const Center(
                        child: Icon(Icons.movie_outlined, size: 40, color: Colors.grey),
                      ),
                    ),
                  // Gradient Overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.75),
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Media Type Pill top-left
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isMovie ? 'MOVIE' : 'TV',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                  // Progress Bar on bottom edge of thumbnail
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: (item.progressPercentage / 100).clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
            // Info & Quick Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.media.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '$elapsedStr / $totalStr (${item.progressPercentage}%)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textMuted(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              ref.read(progressServiceProvider).incrementProgress(
                                    mediaId: item.media.id,
                                    deltaSeconds: 15 * 60,
                                    seasonNumber: item.entry.currentSeason,
                                    episodeNumber: item.entry.currentEpisode,
                                  );
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                              ),
                              child: const Text(
                                '+15m',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () {
                              ProgressModalSheet.show(
                                context,
                                mediaId: item.media.id,
                                title: item.media.title,
                                totalDurationSeconds: item.totalRuntimeSeconds,
                                initialProgressSeconds: item.entry.progressSeconds,
                                seasonNumber: item.entry.currentSeason,
                                episodeNumber: item.entry.currentEpisode,
                                isMovie: isMovie,
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Icon(Icons.tune, size: 16, color: AppTheme.textMuted(context)),
                            ),
                          ),
                        ],
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
