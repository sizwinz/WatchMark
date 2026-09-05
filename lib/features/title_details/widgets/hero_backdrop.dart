import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:watchmark/app/theme.dart';
import 'package:watchmark/core/network/api_endpoints.dart';
import 'package:watchmark/core/network/tmdb_api_service.dart';

class HeroBackdrop extends StatelessWidget {
  final TmdbMediaDetail detail;

  const HeroBackdrop({super.key, required this.detail});

  String _formatRuntime(int? minutes) {
    if (minutes == null || minutes <= 0) return '';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  String _getYear(String? date) {
    if (date == null || date.isEmpty) return '';
    final parts = date.split('-');
    return parts.isNotEmpty ? parts.first : '';
  }

  @override
  Widget build(BuildContext context) {
    final backdropUrl = ApiEndpoints.backdropUrl(detail.backdropPath, size: 'w1280');
    final posterUrl = ApiEndpoints.posterUrl(detail.posterPath, size: 'w500');
    final year = _getYear(detail.releaseDate);
    final runtime = _formatRuntime(detail.runtimeMinutes);
    final isMovie = detail.mediaType == 'movie';

    return Stack(
      children: [
        // Backdrop Image with Gradient
        if (backdropUrl != null) ...[
          SizedBox(
            height: 280,
            width: double.infinity,
            child: ShaderMask(
              shaderCallback: (rect) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black,
                    Colors.transparent,
                  ],
                  stops: [0.3, 1.0],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: CachedNetworkImage(
                imageUrl: backdropUrl,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(color: AppTheme.surface(context)),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 80,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ] else
          Container(
            height: 180,
            color: AppTheme.surface(context),
          ),

        // Metadata Header Content Overlaid
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 140, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Overlapping Poster
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                child: SizedBox(
                  width: 110,
                  height: 165,
                  child: posterUrl != null
                      ? CachedNetworkImage(
                          imageUrl: posterUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppTheme.isDark(context) ? const Color(0xFF1E232E) : const Color(0xFFE2E6EE),
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppTheme.isDark(context) ? const Color(0xFF1E232E) : const Color(0xFFE2E6EE),
                            child: const Icon(Icons.movie_outlined, size: 40),
                          ),
                        )
                      : Container(
                          color: AppTheme.isDark(context) ? const Color(0xFF1E232E) : const Color(0xFFE2E6EE),
                          child: const Icon(Icons.movie_outlined, size: 40),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Title & Badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            isMovie ? 'MOVIE' : 'TV SHOW',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        if (year.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            year,
                            style: TextStyle(fontSize: 13, color: AppTheme.textMuted(context)),
                          ),
                        ],
                        if (runtime.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            '• $runtime',
                            style: TextStyle(fontSize: 13, color: AppTheme.textMuted(context)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      detail.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    if (detail.voteAverage != null && detail.voteAverage! > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 18, color: AppTheme.warning),
                          const SizedBox(width: 4),
                          Text(
                            '${detail.voteAverage!.toStringAsFixed(1)} / 10',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
