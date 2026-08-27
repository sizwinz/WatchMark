import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:watchmark/app/theme.dart';
import 'package:watchmark/core/database/app_database.dart';
import 'package:watchmark/core/database/daos/custom_lists_dao.dart';
import 'package:watchmark/shared/providers/database_provider.dart';

class CustomListDetailsView extends ConsumerWidget {
  final CustomList customList;

  const CustomListDetailsView({super.key, required this.customList});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(customListsDaoProvider);
    final itemsStream = dao.watchItemsForList(customList.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(customList.name),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<List<CustomListItemWithMedia>>(
        stream: itemsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (customList.description != null && customList.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    customList.description!,
                    style: TextStyle(fontSize: 14, color: AppTheme.textMuted(context)),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '${items.length} ${items.length == 1 ? 'title' : 'titles'}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                    if (customList.isRanked) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Ranked',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.warning),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 16),
              if (items.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.video_library_outlined, size: 48, color: AppTheme.textMuted(context)),
                        const SizedBox(height: 12),
                        const Text(
                          'This list is empty',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add movies and TV series from their details page.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    onReorderItem: (oldIndex, newIndex) {
                      final mutableItems = List<CustomListItemWithMedia>.from(items);
                      final item = mutableItems.removeAt(oldIndex);
                      mutableItems.insert(newIndex, item);

                      final orderedIds = mutableItems.map((i) => i.item.id).toList();
                      dao.reorderItems(customList.id, orderedIds);
                    },
                    itemBuilder: (context, index) {
                      final itemWithMedia = items[index];
                      final media = itemWithMedia.media;

                      return Card(
                        key: ValueKey(itemWithMedia.item.id),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (customList.isRanked) ...[
                                SizedBox(
                                  width: 24,
                                  child: Text(
                                    '#${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.warning,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: media.posterPath != null
                                    ? CachedNetworkImage(
                                        imageUrl: 'https://image.tmdb.org/t/p/w92${media.posterPath}',
                                        width: 40,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorWidget: (context, url, error) => Container(
                                          width: 40,
                                          height: 60,
                                          color: AppTheme.isDark(context) ? Colors.white10 : const Color(0xFFE2E6EE),
                                          child: const Icon(Icons.movie, size: 20),
                                        ),
                                      )
                                    : Container(
                                        width: 40,
                                        height: 60,
                                        color: AppTheme.isDark(context) ? Colors.white10 : const Color(0xFFE2E6EE),
                                        child: const Icon(Icons.movie, size: 20),
                                      ),
                              ),
                            ],
                          ),
                          title: Text(
                            media.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          subtitle: Text(
                            media.mediaType == 'movie' ? 'Movie' : 'TV Series',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context)),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.error),
                                tooltip: 'Remove from list',
                                onPressed: () {
                                  dao.removeMediaFromList(
                                    listId: customList.id,
                                    mediaId: media.id,
                                  );
                                },
                              ),
                              ReorderableDragStartListener(
                                index: index,
                                child: Icon(Icons.drag_handle, color: AppTheme.textMuted(context)),
                              ),
                            ],
                          ),
                          onTap: () {
                            final tmdbId = int.tryParse(media.tmdbId) ?? 0;
                            context.push('/title/$tmdbId?type=${media.mediaType}');
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
