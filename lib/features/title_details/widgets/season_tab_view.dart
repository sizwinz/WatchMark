import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:watchmark/app/theme.dart';
import 'package:watchmark/core/database/app_database.dart';
import 'package:watchmark/core/network/api_endpoints.dart';
import 'package:watchmark/core/network/tmdb_api_service.dart';
import 'package:watchmark/features/progress/widgets/progress_modal_sheet.dart';

class SeasonTabView extends StatelessWidget {
  final String mediaId;
  final List<TmdbSeasonSummary> seasons;
  final int selectedSeasonNumber;
  final List<Episode> episodes;
  final bool isLoadingSeason;
  final ValueChanged<int> onSeasonSelected;
  final int? currentSeason;
  final int? currentEpisode;
  final int currentProgressSeconds;
  final bool isSeriesCompleted;
  final void Function(int seasonNumber, int episodeNumber)? onMarkEpisodeWatched;
  final String? currentPlatform;

  const SeasonTabView({
    super.key,
    required this.mediaId,
    required this.seasons,
    required this.selectedSeasonNumber,
    required this.episodes,
    required this.isLoadingSeason,
    required this.onSeasonSelected,
    this.currentSeason,
    this.currentEpisode,
    this.currentProgressSeconds = 0,
    this.isSeriesCompleted = false,
    this.onMarkEpisodeWatched,
    this.currentPlatform,
  });

  @override
  Widget build(BuildContext context) {
    if (seasons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Seasons & Episodes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Horizontal Season Chips
        SizedBox(
          height: 38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: seasons.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final season = seasons[index];
              final isSelected = season.seasonNumber == selectedSeasonNumber;

              return ChoiceChip(
                label: Text(season.name),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    onSeasonSelected(season.seasonNumber);
                  }
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Episode List
        if (isLoadingSeason)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (episodes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Text(
              'No episode information available for this season.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: episodes.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final ep = episodes[index];
              final stillUrl = ApiEndpoints.stillUrl(ep.stillPath, size: 'w300');
              final runtimeSeconds = (ep.runtimeMinutes ?? 45) * 60;

              final isWatched = isSeriesCompleted ||
                  (currentSeason != null &&
                      (selectedSeasonNumber < currentSeason! ||
                          (selectedSeasonNumber == currentSeason! &&
                              ep.episodeNumber < (currentEpisode ?? 1))));

              final isCurrent = !isSeriesCompleted &&
                  currentSeason != null &&
                  selectedSeasonNumber == currentSeason &&
                  ep.episodeNumber == (currentEpisode ?? 1);

              final currentEpProgressPct = isCurrent && runtimeSeconds > 0
                  ? ((currentProgressSeconds / runtimeSeconds) * 100).clamp(0, 100).toInt()
                  : 0;

              return Card(
                clipBehavior: Clip.antiAlias,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  side: BorderSide(
                    color: isCurrent
                        ? AppTheme.primary.withValues(alpha: 0.6)
                        : AppTheme.border(context),
                    width: isCurrent ? 1.5 : 1,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    ProgressModalSheet.show(
                      context,
                      mediaId: mediaId,
                      title: '${ep.episodeNumber}. ${ep.title}',
                      totalDurationSeconds: runtimeSeconds,
                      initialProgressSeconds: isCurrent ? currentProgressSeconds : (isWatched ? runtimeSeconds : 0),
                      seasonNumber: selectedSeasonNumber,
                      episodeNumber: ep.episodeNumber,
                      initialPlatform: currentPlatform,
                      isMovie: false,
                    );
                  },
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 80),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 112,
                            child: Stack(
                              fit: StackFit.expand,
                          children: [
                            if (stillUrl != null)
                              CachedNetworkImage(
                                imageUrl: stillUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: AppTheme.isDark(context) ? const Color(0xFF161A22) : const Color(0xFFE2E6EE),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: AppTheme.isDark(context) ? const Color(0xFF161A22) : const Color(0xFFE2E6EE),
                                  child: const Icon(Icons.tv, color: Colors.grey),
                                ),
                              )
                            else
                              Container(
                                color: AppTheme.isDark(context) ? const Color(0xFF161A22) : const Color(0xFFE2E6EE),
                                child: const Icon(Icons.tv, color: Colors.grey),
                              ),

                            // Watched subtle shade (no duplicate icon)
                            if (isWatched)
                              Container(
                                color: Colors.black.withValues(alpha: 0.18),
                              ),

                            // Active episode badge
                            if (isCurrent)
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'WATCHING',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.4,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                            // Progress bar on current episode thumbnail
                            if (isCurrent && currentProgressSeconds > 0)
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: LinearProgressIndicator(
                                  value: (currentEpProgressPct / 100).clamp(0.0, 1.0),
                                  backgroundColor: Colors.black.withValues(alpha: 0.4),
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                                  minHeight: 3.5,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${ep.episodeNumber}. ${ep.title}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrent ? AppTheme.primary : AppTheme.textPrimary(context),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  if (ep.runtimeMinutes != null && ep.runtimeMinutes! > 0)
                                    Text(
                                      '${ep.runtimeMinutes}m',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textMuted(context),
                                      ),
                                    ),
                                  if (isCurrent && currentProgressSeconds > 0) ...[
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        '• ${currentProgressSeconds ~/ 60}m ($currentEpProgressPct%)',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (ep.overview != null && ep.overview!.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  ep.overview!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textMuted(context),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      // Action buttons
                      Padding(
                        padding: const EdgeInsets.only(top: 4, right: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                              padding: const EdgeInsets.all(4),
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                isWatched
                                    ? Icons.check_circle_rounded
                                    : (isCurrent ? Icons.play_circle_fill_rounded : Icons.check_circle_outline_rounded),
                                size: 21,
                                color: isWatched
                                    ? AppTheme.success
                                    : (isCurrent ? AppTheme.primary : AppTheme.textMuted(context)),
                              ),
                              tooltip: isWatched
                                  ? 'Watched (Tap to re-log)'
                                  : (isCurrent ? 'Mark this episode watched & advance' : 'Mark as watched'),
                              onPressed: () {
                                onMarkEpisodeWatched?.call(selectedSeasonNumber, ep.episodeNumber);
                              },
                            ),
                            IconButton(
                              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                              padding: const EdgeInsets.all(4),
                              visualDensity: VisualDensity.compact,
                              icon: Icon(Icons.timer_outlined, size: 19, color: AppTheme.textMuted(context)),
                              tooltip: 'Log exact minutes',
                              onPressed: () {
                                ProgressModalSheet.show(
                                  context,
                                  mediaId: mediaId,
                                  title: '${ep.episodeNumber}. ${ep.title}',
                                  totalDurationSeconds: runtimeSeconds,
                                  initialProgressSeconds: isCurrent ? currentProgressSeconds : (isWatched ? runtimeSeconds : 0),
                                  seasonNumber: selectedSeasonNumber,
                                  episodeNumber: ep.episodeNumber,
                                  initialPlatform: currentPlatform,
                                  isMovie: false,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
            },
          ),
      ],
    );
  }
}
