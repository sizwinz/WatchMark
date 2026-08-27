import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:watchmark/app/theme.dart';
import 'package:watchmark/core/sync/services/google_auth_service.dart';
import 'package:watchmark/core/sync/services/sync_engine.dart';

class CloudSyncCard extends ConsumerWidget {
  const CloudSyncCard({super.key});

  String _formatLastSync(DateTime? dt) {
    if (dt == null) return 'Never';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM dd, hh:mm a').format(dt);
  }

  Future<void> _confirmDisconnect(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Google Drive?'),
        content: const Text(
          'Disconnecting will pause cloud synchronization. Your local database, watch history, and progress will remain completely intact on this device.',
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
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(googleAuthServiceProvider).signOut();
    }
  }

  void _showGoogleSetupDialog(BuildContext context, String? error) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_sync_outlined, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Google Drive Setup', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (error != null && error.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 18, color: AppTheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Google Sign-In failed to connect to Google Play Services.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textPrimary(context), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const Text(
                'To use Google Drive Sync on Android, register this app in Google Cloud Console / Firebase Console with the following credentials:',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              const Text(
                'Package Name:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              const SelectableText(
                'com.watchmark.watchmark',
                style: TextStyle(fontSize: 12, color: AppTheme.primary, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 10),
              const Text(
                'Debug SHA-1 Certificate:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              const SelectableText(
                'EC:36:6B:73:5B:91:A1:59:69:A1:77:8C:17:91:93:30:6A:D4:A2:98',
                style: TextStyle(fontSize: 11, color: AppTheme.primary, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 16, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You can also use "Export / Import JSON Backup" under Data & Storage below to sync and backup your data anytime without Google Sign-In.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncEngineProvider);
    final syncEngine = ref.read(syncEngineProvider.notifier);
    final authService = ref.read(googleAuthServiceProvider);

    if (!syncState.isConnected) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.cloud_outlined, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Text(
                    'Cloud Sync (Google Drive)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Synchronize your media library, progress, and viewing history across all your devices using hidden Google Drive appDataFolder storage.',
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted(context)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (Theme.of(context).platform == TargetPlatform.windows ||
                            Theme.of(context).platform == TargetPlatform.linux) {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Google Drive Cloud Sync'),
                              content: const Text(
                                'Google Sign-In on Windows and Linux desktop requires external OAuth credentials or a loopback server. Cloud Sync with Google Drive is supported out-of-the-box on Android and mobile devices.\n\nOn Desktop, you can use "Export / Import JSON Backup" under Data & Storage to easily backup or migrate your library across devices.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('Understood'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }

                        final success = await authService.signIn();
                        if (!success && context.mounted) {
                          final error = authService.lastErrorMessage ?? '';
                          if (error.contains('cancelled')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Google Sign-In was cancelled.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            _showGoogleSetupDialog(context, error);
                          }
                        }
                      },
                      icon: const Icon(Icons.account_circle_outlined, size: 18),
                      label: const Text('Connect Google Drive'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    onPressed: () => _showGoogleSetupDialog(context, null),
                    icon: const Icon(Icons.help_outline, size: 20),
                    tooltip: 'Setup Requirements',
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.cloud_done_outlined, color: AppTheme.success),
                    SizedBox(width: 8),
                    Text(
                      'Google Drive Sync',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: syncState.isSyncing
                        ? AppTheme.primary.withValues(alpha: 0.2)
                        : AppTheme.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (syncState.isSyncing) ...[
                        const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Syncing...',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                        ),
                      ] else ...[
                        const Text(
                          'Connected',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.success),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (syncState.accountEmail != null) ...[
              _InfoRow(label: 'Account', value: syncState.accountEmail!),
              const SizedBox(height: 6),
            ],
            _InfoRow(label: 'Device ID', value: syncState.deviceId.substring(0, 8)),
            const SizedBox(height: 6),
            _InfoRow(
              label: 'Pending Changes',
              value: syncState.pendingCount == 0 ? 'Up to date' : '${syncState.pendingCount} pending',
              valueColor: syncState.pendingCount == 0 ? AppTheme.success : AppTheme.warning,
            ),
            const SizedBox(height: 6),
            _InfoRow(label: 'Last Synced', value: _formatLastSync(syncState.lastSyncTime)),
            if (syncState.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                syncState.errorMessage!,
                style: const TextStyle(color: AppTheme.error, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDisconnect(context, ref),
                    icon: Icon(Icons.link_off, size: 16, color: AppTheme.textMuted(context)),
                    label: Text('Disconnect', style: TextStyle(color: AppTheme.textMuted(context))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: syncState.isSyncing ? null : () => syncEngine.syncNow(),
                    icon: syncState.isSyncing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.sync, size: 16),
                    label: const Text('Sync Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: AppTheme.textMuted(context)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppTheme.textPrimary(context),
          ),
        ),
      ],
    );
  }
}
