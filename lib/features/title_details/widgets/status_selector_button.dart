import 'package:flutter/material.dart';
import 'package:watchmark/app/theme.dart';
import 'package:watchmark/core/database/app_database.dart';

class StatusSelectorButton extends StatelessWidget {
  final LibraryEntry? libraryEntry;
  final ValueChanged<String> onStatusSelected;
  final VoidCallback onRemove;
  final VoidCallback? onAddToList;

  const StatusSelectorButton({
    super.key,
    required this.libraryEntry,
    required this.onStatusSelected,
    required this.onRemove,
    this.onAddToList,
  });

  String _formatStatus(String? status) {
    switch (status) {
      case 'watchlist':
        return 'In Watchlist';
      case 'watching':
        return 'Watching';
      case 'completed':
        return 'Completed';
      case 'paused':
        return 'Paused';
      case 'dropped':
        return 'Dropped';
      default:
        return 'Add to Library';
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'watchlist':
        return Icons.bookmark;
      case 'watching':
        return Icons.play_circle_filled;
      case 'completed':
        return Icons.check_circle;
      case 'paused':
        return Icons.pause_circle_filled;
      case 'dropped':
        return Icons.cancel;
      default:
        return Icons.add;
    }
  }

  void _showStatusSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.cardRadius)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Update Watch Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.bookmark_outline, color: AppTheme.primary),
                  title: const Text('Watchlist'),
                  trailing: libraryEntry?.status == 'watchlist' ? const Icon(Icons.check, color: AppTheme.primary) : null,
                  onTap: () {
                    Navigator.pop(context);
                    onStatusSelected('watchlist');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.play_circle_outline, color: AppTheme.primary),
                  title: const Text('Watching'),
                  trailing: libraryEntry?.status == 'watching' ? const Icon(Icons.check, color: AppTheme.primary) : null,
                  onTap: () {
                    Navigator.pop(context);
                    onStatusSelected('watching');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.check_circle_outline, color: AppTheme.success),
                  title: const Text('Completed'),
                  trailing: libraryEntry?.status == 'completed' ? const Icon(Icons.check, color: AppTheme.success) : null,
                  onTap: () {
                    Navigator.pop(context);
                    onStatusSelected('completed');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.pause_circle_outline, color: AppTheme.warning),
                  title: const Text('Paused'),
                  trailing: libraryEntry?.status == 'paused' ? const Icon(Icons.check, color: AppTheme.warning) : null,
                  onTap: () {
                    Navigator.pop(context);
                    onStatusSelected('paused');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cancel_outlined, color: Colors.grey),
                  title: const Text('Dropped'),
                  trailing: libraryEntry?.status == 'dropped' ? const Icon(Icons.check, color: Colors.grey) : null,
                  onTap: () {
                    Navigator.pop(context);
                    onStatusSelected('dropped');
                  },
                ),
                if (onAddToList != null) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.playlist_add, color: AppTheme.primary),
                    title: const Text('Add to Custom List...'),
                    onTap: () {
                      Navigator.pop(context);
                      onAddToList!();
                    },
                  ),
                ],
                if (libraryEntry != null) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                    title: const Text('Remove from Library', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      onRemove();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = libraryEntry?.status;
    final isAdded = status != null;

    return ElevatedButton.icon(
      onPressed: () => _showStatusSheet(context),
      icon: Icon(_getStatusIcon(status), size: 18),
      label: Text(_formatStatus(status)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isAdded ? AppTheme.primaryDark : AppTheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }
}
