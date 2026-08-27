import 'package:cached_network_image/cached_network_image.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchmark/app/theme.dart';
import 'package:watchmark/core/database/app_database.dart';
import 'package:watchmark/core/network/api_endpoints.dart';
import 'package:watchmark/core/network/tmdb_api_service.dart';
import 'package:watchmark/core/repositories/media_repository.dart';
import 'package:watchmark/core/utilities/uuid_helper.dart';
import 'package:watchmark/shared/providers/database_provider.dart';

class SearchCard extends ConsumerWidget {
  final TmdbSearchResult item;
  final VoidCallback onTap;

  const SearchCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  String _getYear(String? date) {
    if (date == null || date.isEmpty) return '';
    final parts = date.split('-');
    return parts.isNotEmpty ? parts.first : '';
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, String status) async {
    final mediaRepository = ref.read(mediaRepositoryProvider);
    final libraryDao = ref.read(libraryDaoProvider);

    final tmdbService = ref.read(tmdbApiServiceProvider);
    TmdbMediaDetail? detail;
    if (item.mediaType == 'movie') {
      detail = await tmdbService.getMovieDetails(item.id);
    } else {
      detail = await tmdbService.getTvDetails(item.id);
    }

    if (detail != null) {
      final cached = await mediaRepository.cacheMediaDetail(detail);
      final existingEntry = await libraryDao.getLibraryEntryByMediaId(cached.id, includeDeleted: true);
      final entryId = existingEntry?.id ?? generateUuidV7();

      await libraryDao.upsertLibraryEntry(
        LibraryEntriesCompanion.insert(
          id: drift.Value(entryId),
          mediaId: cached.id,
          status: status,
          updatedAt: drift.Value(DateTime.now()),
          deletedAt: const drift.Value(null),
        ),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${item.title}" to ${_formatStatus(status)}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posterUrl = ApiEndpoints.posterUrl(item.posterPath, size: 'w500');
    final year = _getYear(item.releaseDate);
    final isMovie = item.mediaType == 'movie';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                        color: AppTheme.isDark(context) ? const Color(0xFF1E232E) : const Color(0xFFE2E6EE),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
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
                        child: const Icon(Icons.bookmark_add_outlined, size: 18, color: Colors.white),
                      ),
                      onSelected: (status) => _updateStatus(context, ref, status),
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'watchlist', child: Text('Add to Watchlist')),
                        PopupMenuItem(value: 'watching', child: Text('Mark as Watching')),
                        PopupMenuItem(value: 'completed', child: Text('Mark as Completed')),
                        PopupMenuItem(value: 'paused', child: Text('Mark as Paused')),
                        PopupMenuItem(value: 'dropped', child: Text('Mark as Dropped')),
                      ],
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
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        year,
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context)),
                      ),
                      if (item.voteAverage != null && item.voteAverage! > 0)
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: AppTheme.warning),
                            const SizedBox(width: 2),
                            Text(
                              item.voteAverage!.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
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
