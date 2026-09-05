import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchmark/app/theme.dart';
import 'package:watchmark/core/network/tmdb_api_service.dart';
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        systemOverlayStyle: AppTheme.darkOverlayStyle,
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
                              initialPlatform: state.currentPlatform,
                              isMovie: true,
                            );
                          },
                          icon: const Icon(Icons.timer_outlined, size: 18),
                          label: const Text('Log Progress'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      if (detail.mediaType == 'tv' && state.localTitle != null && state.libraryEntry == null)
                        OutlinedButton.icon(
                          onPressed: () => controller.startWatchingFirstEpisode(),
                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                          label: const Text('Start Watching S1:E1'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Watch Progress Panel
                  if (state.libraryEntry != null && state.localTitle != null) ...[
                    if (detail.mediaType == 'movie' && (hasProgress || state.libraryEntry!.status == 'completed'))
                      _buildMovieProgressCard(context, state, controller, detail)
                    else if (detail.mediaType == 'tv')
                      _buildSeriesProgressCard(context, state, controller, detail),
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
                currentSeason: state.libraryEntry?.currentSeason,
                currentEpisode: state.libraryEntry?.currentEpisode,
                currentProgressSeconds: state.libraryEntry?.progressSeconds ?? 0,
                isSeriesCompleted: state.libraryEntry?.status == 'completed',
                onMarkEpisodeWatched: (seasonNum, epNum) => controller.markEpisodeWatched(seasonNum, epNum),
                currentPlatform: state.currentPlatform,
              ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSeriesProgressCard(
    BuildContext context,
    TitleDetailsState state,
    TitleDetailsController controller,
    TmdbMediaDetail detail,
  ) {
    final entry = state.libraryEntry!;
    final isCompleted = entry.status == 'completed';
    final curSeason = entry.currentSeason ?? 1;
    final curEp = entry.currentEpisode ?? 1;

    final activeEp = state.activeEpisode;
    final epTitle = activeEp != null && activeEp.title.isNotEmpty ? activeEp.title : 'Episode $curEp';
    final epRuntimeMinutes = activeEp?.runtimeMinutes ?? detail.runtimeMinutes ?? 45;
    final epRuntimeSeconds = epRuntimeMinutes * 60;

    final epProgressPct = epRuntimeSeconds > 0
        ? ((entry.progressSeconds / epRuntimeSeconds) * 100).clamp(0, 100).toInt()
        : 0;

    final totalEps = state.totalEpisodesCount > 0
        ? state.totalEpisodesCount
        : detail.seasons.where((s) => s.seasonNumber > 0).fold<int>(0, (sum, s) => sum + s.episodeCount);
    final watchedEps = state.watchedEpisodesCount;
    final seriesProgressPct = totalEps > 0 ? ((watchedEps / totalEps) * 100).clamp(0, 100).toInt() : 0;

    return Container(
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
                  Icon(
                    isCompleted ? Icons.check_circle_rounded : Icons.play_circle_outline,
                    size: 20,
                    color: isCompleted ? AppTheme.success : AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isCompleted ? 'Series Completed' : (entry.progressSeconds > 0 ? 'Currently Watching' : 'Next Up'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.currentPlatform != null) ...[
                    _buildPlatformBadge(context, state.currentPlatform!, onTap: () {
                      ProgressModalSheet.show(
                        context,
                        mediaId: state.localTitle!.id,
                        title: 'S$curSeason:E$curEp • $epTitle',
                        totalDurationSeconds: epRuntimeSeconds,
                        initialProgressSeconds: entry.progressSeconds,
                        seasonNumber: curSeason,
                        episodeNumber: curEp,
                        initialPlatform: state.currentPlatform,
                        isMovie: false,
                      );
                    }),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: (isCompleted ? AppTheme.success : AppTheme.primary).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isCompleted ? '100%' : 'S$curSeason:E$curEp',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? AppTheme.success : AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!isCompleted) ...[
            Text(
              'S$curSeason:E$curEp • $epTitle',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_formatDuration(entry.progressSeconds)} / ${_formatDuration(epRuntimeSeconds)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                Text(
                  '$epProgressPct% episode',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (epProgressPct / 100).clamp(0.0, 1.0),
                backgroundColor: AppTheme.isDark(context) ? const Color(0xFF262C38) : const Color(0xFFE2E5EC),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Overall Series Progress',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted(context),
                      ),
                    ),
                    Text(
                      totalEps > 0 ? '$watchedEps of $totalEps eps ($seriesProgressPct%)' : '$watchedEps eps watched',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? AppTheme.success : AppTheme.textPrimary(context),
                      ),
                    ),
                  ],
                ),
                if (totalEps > 0) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: (seriesProgressPct / 100).clamp(0.0, 1.0),
                      backgroundColor: AppTheme.isDark(context) ? const Color(0xFF1E232F) : const Color(0xFFE2E5EC),
                      valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? AppTheme.success : AppTheme.primary),
                      minHeight: 4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (!isCompleted)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => controller.incrementActiveProgress(15 * 60),
                        icon: const Icon(Icons.add, size: 16, color: AppTheme.primary),
                        label: const Text('+15 min', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                          ),
                          side: BorderSide(
                            color: AppTheme.isDark(context) ? const Color(0xFF353C4D) : const Color(0xFFD0D5DD),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ProgressModalSheet.show(
                            context,
                            mediaId: state.localTitle!.id,
                            title: 'S$curSeason:E$curEp • $epTitle',
                            totalDurationSeconds: epRuntimeSeconds,
                            initialProgressSeconds: entry.progressSeconds,
                            seasonNumber: curSeason,
                            episodeNumber: curEp,
                            initialPlatform: state.currentPlatform,
                            isMovie: false,
                          );
                        },
                        icon: const Icon(Icons.tune, size: 16),
                        label: const Text('Log Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                          ),
                          side: BorderSide(
                            color: AppTheme.isDark(context) ? const Color(0xFF353C4D) : const Color(0xFFD0D5DD),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => controller.markEpisodeWatched(curSeason, curEp),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: Text(
                      'Mark S$curSeason:E$curEp Watched & Next',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => controller.startWatchingFirstEpisode(),
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text('Rewatch Series from S1:E1'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMovieProgressCard(
    BuildContext context,
    TitleDetailsState state,
    TitleDetailsController controller,
    TmdbMediaDetail detail,
  ) {
    final entry = state.libraryEntry!;
    final totalSeconds = (detail.runtimeMinutes ?? 120) * 60;
    final progressPct = totalSeconds > 0
        ? ((entry.progressSeconds / totalSeconds) * 100).clamp(0, 100).toInt()
        : 0;
    final isCompleted = entry.status == 'completed';

    return Container(
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
                  Icon(
                    isCompleted ? Icons.check_circle_rounded : Icons.play_circle_outline,
                    size: 20,
                    color: isCompleted ? AppTheme.success : AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isCompleted ? 'Movie Completed' : 'Watch Progress',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.currentPlatform != null) ...[
                    _buildPlatformBadge(context, state.currentPlatform!, onTap: () {
                      ProgressModalSheet.show(
                        context,
                        mediaId: state.localTitle!.id,
                        title: detail.title,
                        totalDurationSeconds: totalSeconds,
                        initialProgressSeconds: entry.progressSeconds,
                        initialPlatform: state.currentPlatform,
                        isMovie: true,
                      );
                    }),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isCompleted ? AppTheme.success : AppTheme.primary).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$progressPct%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? AppTheme.success : AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(entry.progressSeconds),
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
              backgroundColor: AppTheme.isDark(context) ? const Color(0xFF262C38) : const Color(0xFFE2E5EC),
              valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? AppTheme.success : AppTheme.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => controller.incrementActiveProgress(15 * 60),
                  icon: const Icon(Icons.add, size: 16, color: AppTheme.primary),
                  label: const Text('+15 min', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                    ),
                    side: BorderSide(
                      color: AppTheme.isDark(context) ? const Color(0xFF353C4D) : const Color(0xFFD0D5DD),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ProgressModalSheet.show(
                      context,
                      mediaId: state.localTitle!.id,
                      title: detail.title,
                      totalDurationSeconds: totalSeconds,
                      initialProgressSeconds: entry.progressSeconds,
                      initialPlatform: state.currentPlatform,
                      isMovie: true,
                    );
                  },
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('Log Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                    ),
                    side: BorderSide(
                      color: AppTheme.isDark(context) ? const Color(0xFF353C4D) : const Color(0xFFD0D5DD),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!isCompleted) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => controller.markMovieWatched(),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text(
                  'Mark Movie as Watched',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlatformBadge(BuildContext context, String platform, {VoidCallback? onTap}) {
    final color = AppTheme.getPlatformColor(platform);
    final name = AppTheme.getPlatformDisplayName(platform);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 3.5, backgroundColor: color),
            const SizedBox(width: 5),
            Text(
              name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
