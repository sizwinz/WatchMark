import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchmark/app/theme.dart';
import 'package:watchmark/core/services/progress_service.dart';
import 'package:watchmark/features/custom_lists/widgets/add_to_list_bottom_sheet.dart';
import 'package:watchmark/features/progress/widgets/progress_modal_sheet.dart';
import 'package:watchmark/features/title_details/controllers/title_details_controller.dart';
import 'package:watchmark/features/title_details/widgets/cast_list.dart';
import 'package:watchmark/features/title_details/widgets/hero_backdrop.dart';
import 'package:watchmark/features/title_details/widgets/season_tab_view.dart';
import 'package:watchmark/features/title_details/widgets/status_selector_button.dart';

class TitleDetailsView extends ConsumerWidget {
  final int tmdbId;
  final String mediaType;

  const TitleDetailsView({
    super.key,
    required this.tmdbId,
    required this.mediaType,
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
    final state = ref.watch(
      titleDetailsControllerProvider((tmdbId: tmdbId, mediaType: mediaType)),
    );
    final controller = ref.read(
      titleDetailsControllerProvider((tmdbId: tmdbId, mediaType: mediaType)).notifier,
    );

    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.detail == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Text(
            state.errorMessage ?? 'Unable to load title details.',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final detail = state.detail!;
    final totalSeconds = (detail.runtimeMinutes ?? 120) * 60;
    final hasProgress = state.libraryEntry != null &&
        state.libraryEntry!.progressSeconds > 0 &&
        state.libraryEntry!.status != 'completed';
    final progressPct = totalSeconds > 0 && state.libraryEntry != null
        ? ((state.libraryEntry!.progressSeconds / totalSeconds) * 100).clamp(0, 100).toInt()
        : 0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black.withValues(alpha: 0.6),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HeroBackdrop(detail: detail),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      StatusSelectorButton(
                        libraryEntry: state.libraryEntry,
                        onStatusSelected: (status) => controller.updateLibraryStatus(status),
                        onRemove: () => controller.removeFromLibrary(),
                        onAddToList: state.localTitle != null
                            ? () => showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (context) => AddToListBottomSheet(
                                    mediaId: state.localTitle!.id,
                                    titleName: detail.title,
                                  ),
                                )
                            : null,
                      ),
                      if (detail.mediaType == 'movie' && state.localTitle != null && !hasProgress)
                        OutlinedButton.icon(
                          onPressed: () {
                            ProgressModalSheet.show(
                              context,
                              mediaId: state.localTitle!.id,
                              title: detail.title,
                              totalDurationSeconds: totalSeconds,
                              initialProgressSeconds: state.libraryEntry?.progressSeconds ?? 0,
                              isMovie: true,
                            );
                          },
                          icon: const Icon(Icons.timer_outlined, size: 18),
                          label: const Text('Update Progress'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Watch Progress Panel
                  if (hasProgress && state.localTitle != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface(context),
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        border: Border.all(color: AppTheme.border(context)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.play_circle_outline, size: 20, color: AppTheme.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Watch Progress',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary(context),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$progressPct%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(state.libraryEntry!.progressSeconds),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary(context),
                                ),
                              ),
                              Text(
                                _formatDuration(totalSeconds),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textMuted(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (progressPct / 100).clamp(0.0, 1.0),
                              backgroundColor: AppTheme.isDark(context)
                                  ? const Color(0xFF262C38)
                                  : const Color(0xFFE2E5EC),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ActionChip(
                                avatar: const Icon(Icons.add, size: 16, color: AppTheme.primary),
                                label: const Text('+15 min', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                onPressed: () {
                                  ref.read(progressServiceProvider).incrementProgress(
                                    mediaId: state.localTitle!.id,
                                    deltaSeconds: 15 * 60,
                                    seasonNumber: state.libraryEntry?.currentSeason,
                                    episodeNumber: state.libraryEntry?.currentEpisode,
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  ProgressModalSheet.show(
                                    context,
                                    mediaId: state.localTitle!.id,
                                    title: detail.title,
                                    totalDurationSeconds: totalSeconds,
                                    initialProgressSeconds: state.libraryEntry?.progressSeconds ?? 0,
                                    seasonNumber: state.libraryEntry?.currentSeason,
                                    episodeNumber: state.libraryEntry?.currentEpisode,
                                    isMovie: detail.mediaType == 'movie',
                                  );
                                },
                                icon: const Icon(Icons.tune, size: 16),
                                label: const Text('Update Progress', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (detail.genres.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: detail.genres.map((g) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceElevated(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.border(context)),
                          ),
                          child: Text(
                            g.name,
                            style: TextStyle(fontSize: 12, color: AppTheme.textPrimary(context)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (detail.overview != null && detail.overview!.isNotEmpty) ...[
                    const Text(
                      'Overview',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      detail.overview!,
                      style: TextStyle(fontSize: 14, height: 1.5, color: AppTheme.textPrimary(context)),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
            CastList(cast: detail.cast),
            const SizedBox(height: 24),
            if (detail.mediaType == 'tv') ...[
              SeasonTabView(
                mediaId: state.localTitle?.id ?? '',
                seasons: detail.seasons,
                selectedSeasonNumber: state.selectedSeasonNumber,
                episodes: state.seasonEpisodes,
                isLoadingSeason: state.isLoadingSeason,
                onSeasonSelected: (seasonNum) => controller.selectSeason(seasonNum),
              ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }
}
