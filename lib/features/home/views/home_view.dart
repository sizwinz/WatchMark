import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:watchmark/app/theme.dart';
import 'package:watchmark/core/database/daos/sessions_dao.dart';
import 'package:watchmark/core/network/api_endpoints.dart';
import 'package:watchmark/core/network/tmdb_api_service.dart';
import 'package:watchmark/features/home/controllers/home_controller.dart';
import 'package:watchmark/features/home/widgets/continue_watching_card.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final continueWatchingAsync = ref.watch(continueWatchingStreamProvider);
    final statsAsync = ref.watch(homeStatsProvider);
    final trendingAsync = ref.watch(homeTrendingProvider);
    final recentActivityAsync = ref.watch(homeRecentActivityProvider);
    final watchlistAsync = ref.watch(homeWatchlistProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'WatchMark',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Statistics',
            onPressed: () => context.push('/statistics'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Summary Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: statsAsync.maybeWhen(
                data: (stats) {
                  final hours = (stats.totalMinutesWatched / 60).toStringAsFixed(1);
                  return InkWell(
                    onTap: () => context.push('/statistics'),
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface(context),
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        border: Border.all(color: AppTheme.border(context)),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _StatItem(label: 'Watching', value: '${stats.watchingCount}')),
                          _Divider(),
                          Expanded(child: _StatItem(label: 'Paused', value: '${stats.pausedCount}')),
                          _Divider(),
                          Expanded(child: _StatItem(label: 'Watchlist', value: '${stats.watchlistCount}')),
                          _Divider(),
                          Expanded(child: _StatItem(label: 'Completed', value: '${stats.completedCount}')),
                          _Divider(),
                          Expanded(child: _StatItem(label: 'Tracked', value: '${hours}h')),
                        ],
                      ),
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 24),

            // Continue Watching Section Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Continue Watching',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            // Continue Watching Carousel or Empty state
            continueWatchingAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error loading in-progress media: $err', style: const TextStyle(color: Colors.red)),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                      decoration: BoxDecoration(
                        color: AppTheme.surface(context),
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        border: Border.all(color: AppTheme.border(context)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.movie_filter_rounded,
                              size: 32,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No titles in progress',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Search for movies or series to begin tracking your watch progress.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted(context),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => context.go('/search'),
                            icon: const Icon(Icons.search, size: 16),
                            label: const Text('Discover Titles'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: 235,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ContinueWatchingCard(
                        item: item,
                        onTap: () {
                          context.push(
                            '/title/${item.media.tmdbId}?type=${item.media.mediaType}',
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 28),

            // Trending Today Section
            trendingAsync.maybeWhen(
              data: (trending) {
                if (trending.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Trending Today',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () => context.go('/search'),
                            child: const Text('Explore all', style: TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 205,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: trending.take(10).length,
                        separatorBuilder: (context, index) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final item = trending[index];
                          return _HomePosterCard(item: item);
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),

            // Recent Activity Section
            recentActivityAsync.maybeWhen(
              data: (sessions) {
                if (sessions.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Activity',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () => context.go('/history'),
                            child: const Text('View history', style: TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sessions.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final s = sessions[index];
                        return _HomeRecentSessionTile(item: s);
                      },
                    ),
                    const SizedBox(height: 28),
                  ],
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),

            // Watchlist Section (if items exist)
            watchlistAsync.maybeWhen(
              data: (watchlist) {
                if (watchlist.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Your Watchlist',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () => context.go('/library'),
                            child: const Text('View library', style: TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 195,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: watchlist.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final item = watchlist[index];
                          final posterUrl = ApiEndpoints.posterUrl(item.media.posterPath, size: 'w500');
                          return InkWell(
                            onTap: () {
                              context.push(
                                '/title/${item.media.tmdbId}?type=${item.media.mediaType}',
                              );
                            },
                            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                            child: SizedBox(
                              width: 110,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                                    child: SizedBox(
                                      width: 110,
                                      height: 155,
                                      child: posterUrl != null
                                          ? CachedNetworkImage(
                                              imageUrl: posterUrl,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Container(
                                                color: AppTheme.isDark(context)
                                                    ? const Color(0xFF161A22)
                                                    : const Color(0xFFE2E6EE),
                                              ),
                                              errorWidget: (context, url, error) => Container(
                                                color: AppTheme.isDark(context)
                                                    ? const Color(0xFF161A22)
                                                    : const Color(0xFFE2E6EE),
                                                child: const Icon(Icons.movie_outlined, size: 28, color: Colors.grey),
                                              ),
                                            )
                                          : Container(
                                              color: AppTheme.isDark(context)
                                                  ? const Color(0xFF161A22)
                                                  : const Color(0xFFE2E6EE),
                                              child: const Icon(Icons.movie_outlined, size: 28, color: Colors.grey),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.media.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomePosterCard extends StatelessWidget {
  final TmdbSearchResult item;

  const _HomePosterCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final posterUrl = ApiEndpoints.posterUrl(item.posterPath, size: 'w500');
    final isMovie = item.mediaType == 'movie';

    return InkWell(
      onTap: () {
        context.push('/title/${item.id}?type=${item.mediaType}');
      },
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      child: SizedBox(
        width: 115,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  child: SizedBox(
                    width: 115,
                    height: 160,
                    child: posterUrl != null
                        ? CachedNetworkImage(
                            imageUrl: posterUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppTheme.isDark(context)
                                  ? const Color(0xFF161A22)
                                  : const Color(0xFFE2E6EE),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppTheme.isDark(context)
                                  ? const Color(0xFF161A22)
                                  : const Color(0xFFE2E6EE),
                              child: const Icon(Icons.movie_outlined, size: 28, color: Colors.grey),
                            ),
                          )
                        : Container(
                            color: AppTheme.isDark(context)
                                ? const Color(0xFF161A22)
                                : const Color(0xFFE2E6EE),
                            child: const Icon(Icons.movie_outlined, size: 28, color: Colors.grey),
                          ),
                  ),
                ),
                if (item.voteAverage != null && item.voteAverage! > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 12, color: AppTheme.warning),
                          const SizedBox(width: 2),
                          Text(
                            item.voteAverage!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isMovie ? 'MOVIE' : 'TV',
                      style: const TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeRecentSessionTile extends StatelessWidget {
  final WatchSessionWithMedia item;

  const _HomeRecentSessionTile({required this.item});

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0 && m > 0) return '+${h}h ${m}m';
    if (h > 0) return '+${h}h';
    return '+${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final durationSecs = item.session.positionAfterSeconds - item.session.positionBeforeSeconds;
    final posterUrl = ApiEndpoints.posterUrl(item.media.posterPath, size: 'w500');
    final timeStr = DateFormat('h:mm a • MMM d').format(item.session.startedAt);
    final isMovie = item.media.mediaType == 'movie';
    final pColor = AppTheme.getPlatformColor(item.session.provider);

    final subtitle = !isMovie && item.episode != null
        ? 'S${item.episode!.seasonId}:E${item.episode!.episodeNumber} • ${item.episode!.title}'
        : (item.media.releaseDate != null ? '${item.media.releaseDate!.year}' : 'Movie');

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: ListTile(
        onTap: () {
          context.push('/title/${item.media.tmdbId}?type=${item.media.mediaType}');
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 42,
            height: 58,
            child: posterUrl != null
                ? CachedNetworkImage(
                    imageUrl: posterUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      color: AppTheme.isDark(context)
                          ? const Color(0xFF161A22)
                          : const Color(0xFFE2E6EE),
                      child: const Icon(Icons.movie_outlined, size: 20, color: Colors.grey),
                    ),
                  )
                : Container(
                    color: AppTheme.isDark(context)
                        ? const Color(0xFF161A22)
                        : const Color(0xFFE2E6EE),
                    child: const Icon(Icons.movie_outlined, size: 20, color: Colors.grey),
                  ),
          ),
        ),
        title: Text(
          item.media.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context)),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: pColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: pColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    item.session.provider ?? 'Other',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: pColor),
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
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            _formatDuration(durationSecs),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.success),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted(context)),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: 1,
      color: AppTheme.border(context),
    );
  }
}
