import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchmark/app/theme.dart';
import 'package:watchmark/core/database/daos/custom_lists_dao.dart';
import 'package:watchmark/features/custom_lists/widgets/create_list_dialog.dart';
import 'package:watchmark/shared/providers/database_provider.dart';

class AddToListBottomSheet extends ConsumerStatefulWidget {
  final String mediaId;
  final String titleName;

  const AddToListBottomSheet({
    super.key,
    required this.mediaId,
    required this.titleName,
  });

  @override
  ConsumerState<AddToListBottomSheet> createState() => _AddToListBottomSheetState();
}

class _AddToListBottomSheetState extends ConsumerState<AddToListBottomSheet> {
  List<String> _selectedListIds = [];

  @override
  void initState() {
    super.initState();
    _loadMembership();
  }

  Future<void> _loadMembership() async {
    final dao = ref.read(customListsDaoProvider);
    final listIds = await dao.getListsContainingMedia(widget.mediaId);
    if (mounted) {
      setState(() {
        _selectedListIds = listIds;
      });
    }
  }

  Future<void> _toggleList(String listId) async {
    final dao = ref.read(customListsDaoProvider);
    if (_selectedListIds.contains(listId)) {
      await dao.removeMediaFromList(listId: listId, mediaId: widget.mediaId);
      setState(() => _selectedListIds.remove(listId));
    } else {
      await dao.addMediaToList(listId: listId, mediaId: widget.mediaId);
      setState(() => _selectedListIds.add(listId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dao = ref.watch(customListsDaoProvider);
    final listsStream = dao.watchAllListsWithCounts();

    return Material(
      color: AppTheme.surface(context),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add to Custom List',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.titleName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: AppTheme.textMuted(context)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                  tooltip: 'Create New List',
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder: (context) => const CreateListDialog(),
                    );
                  },
                ),
              ],
            ),
            const Divider(height: 24),
            StreamBuilder<List<CustomListWithCount>>(
              stream: listsStream,
              initialData: const [],
              builder: (context, snapshot) {
                final lists = snapshot.data ?? [];
                if (lists.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            'No custom lists yet',
                            style: TextStyle(fontSize: 14, color: AppTheme.textMuted(context)),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => showDialog(
                              context: context,
                              builder: (context) => const CreateListDialog(),
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Create a List'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lists.length,
                  itemBuilder: (context, index) {
                    final item = lists[index];
                    final list = item.list;
                    final isChecked = _selectedListIds.contains(list.id);

                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(list.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(
                        '${item.itemCount} titles',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context)),
                      ),
                      value: isChecked,
                      activeColor: AppTheme.primary,
                      onChanged: (val) => _toggleList(list.id),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
