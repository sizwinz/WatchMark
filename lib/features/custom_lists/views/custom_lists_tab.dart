import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchmark/app/theme.dart';
import 'package:watchmark/core/database/app_database.dart';
import 'package:watchmark/features/custom_lists/controllers/custom_lists_controller.dart';
import 'package:watchmark/features/custom_lists/views/custom_list_details_view.dart';
import 'package:watchmark/features/custom_lists/widgets/create_list_dialog.dart';
import 'package:watchmark/shared/providers/database_provider.dart';

class CustomListsTab extends ConsumerWidget {
  const CustomListsTab({super.key});

  Future<void> _deleteList(BuildContext context, WidgetRef ref, CustomList list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${list.name}"?'),
        content: const Text(
          'Are you sure you want to delete this custom list? The media titles in it will remain safely in your library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(customListsDaoProvider).deleteList(list.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(customListsWithCountsStreamProvider);

    return listsAsync.when(
      data: (lists) {
        if (lists.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.playlist_play_outlined,
                    size: 64,
                    color: AppTheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Custom Lists Yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create thematic lists like "Halloween Marathons", "Top Sci-Fi 2026", or "Favorites" to organize your titles.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted(context)),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => const CreateListDialog(),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create Your First List'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: lists.length,
          itemBuilder: (context, index) {
            final item = lists[index];
            final list = item.list;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CustomListDetailsView(customList: list),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.playlist_play, color: AppTheme.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    list.name,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (list.isRanked) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.warning.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Ranked',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.warning,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (list.description != null && list.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                list.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context)),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              '${item.itemCount} ${item.itemCount == 1 ? 'title' : 'titles'}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: AppTheme.textMuted(context)),
                        onSelected: (val) {
                          if (val == 'edit') {
                            showDialog(
                              context: context,
                              builder: (context) => CreateListDialog(existingList: list),
                            );
                          } else if (val == 'delete') {
                            _deleteList(context, ref, list);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: AppTheme.error)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading lists: $err')),
    );
  }
}
