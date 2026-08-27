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

  const SeasonTabView({
    super.key,
    required this.mediaId,
    required this.seasons,
    required this.selectedSeasonNumber,
    required this.episodes,
    required this.isLoadingSeason,
    required this.onSeasonSelected,
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

              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    ProgressModalSheet.show(
                      context,
                      mediaId: mediaId,
                      title: '${ep.episodeNumber}. ${ep.title}',
                      totalDurationSeconds: runtimeSeconds,
                      seasonNumber: selectedSeasonNumber,
                      episodeNumber: ep.episodeNumber,
                      isMovie: false,
                    );
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 80,
                        child: stillUrl != null
                            ? CachedNetworkImage(
                                imageUrl: stillUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: AppTheme.isDark(context) ? const Color(0xFF1E232E) : const Color(0xFFE2E6EE),
                                  child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: AppTheme.isDark(context) ? const Color(0xFF1E232E) : const Color(0xFFE2E6EE),
                                  child: const Icon(Icons.tv, color: Colors.grey),
                                ),
                              )
                            : Container(
                                color: AppTheme.isDark(context) ? const Color(0xFF1E232E) : const Color(0xFFE2E6EE),
                                child: const Icon(Icons.tv, color: Colors.grey),
                              ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${ep.episodeNumber}. ${ep.title}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (ep.runtimeMinutes != null && ep.runtimeMinutes! > 0)
                                Text(
                                  '${ep.runtimeMinutes}m',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textMuted(context),
                                  ),
                                ),
                              if (ep.overview != null && ep.overview!.isNotEmpty) ...[
                                const SizedBox(height: 4),
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
                      IconButton(
                        icon: const Icon(Icons.timer_outlined, size: 20, color: AppTheme.primary),
                        onPressed: () {
                          ProgressModalSheet.show(
                            context,
                            mediaId: mediaId,
                            title: '${ep.episodeNumber}. ${ep.title}',
                            totalDurationSeconds: runtimeSeconds,
                            seasonNumber: selectedSeasonNumber,
                            episodeNumber: ep.episodeNumber,
                            isMovie: false,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
