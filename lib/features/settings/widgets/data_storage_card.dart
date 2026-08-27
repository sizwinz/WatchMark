import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:watchmark/app/theme.dart';
import 'package:watchmark/core/services/backup_service.dart';
import 'package:watchmark/features/settings/widgets/import_preview_dialog.dart';

class DataStorageCard extends ConsumerStatefulWidget {
  const DataStorageCard({super.key});

  @override
  ConsumerState<DataStorageCard> createState() => _DataStorageCardState();
}

class _DataStorageCardState extends ConsumerState<DataStorageCard> {
  bool _isProcessing = false;

  Future<void> _exportBackup() async {
    setState(() => _isProcessing = true);
    try {
      final service = ref.read(backupServiceProvider);
      final jsonStr = await service.exportBackupJson();

      final timestamp = DateFormat('yyyy-MM-dd-HHmm').format(DateTime.now());
      final defaultFileName = 'watchmark-backup-$timestamp.json';
      final bytes = Uint8List.fromList(utf8.encode(jsonStr));

      final outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save JSON Backup',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      if (outputFile == null) {
        // User cancelled file picker
        return;
      }

      // On desktop platforms where FilePicker only returns the selected path
      if (!outputFile.startsWith('content://')) {
        final file = File(outputFile);
        if (!await file.exists() || (await file.length()) == 0) {
          await file.writeAsBytes(bytes);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup saved successfully ($defaultFileName)'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final pickedFile = result.files.single;
      String jsonStr;
      if (pickedFile.bytes != null) {
        jsonStr = utf8.decode(pickedFile.bytes!);
      } else if (pickedFile.path != null) {
        jsonStr = await File(pickedFile.path!).readAsString();
      } else {
        return;
      }

      final service = ref.read(backupServiceProvider);
      final validation = service.validateBackupJson(jsonStr);

      if (!validation.isValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid backup: ${validation.errorMessage}'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      final success = await ImportPreviewDialog.show(
        context,
        validation: validation,
        onConfirm: (overwrite) async {
          await service.importBackup(jsonStr: jsonStr, overwrite: overwrite);
        },
      );

      if (success == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup restored successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _clearMetadataCache() async {
    setState(() => _isProcessing = true);
    try {
      final service = ref.read(backupServiceProvider);
      final count = await service.clearMetadataCache();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Freed $count cached unreferenced titles and purged image cache.'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cache clear failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _confirmResetDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.error),
            SizedBox(width: 8),
            Text('Reset All Data'),
          ],
        ),
        content: const Text(
          'Are you sure you want to completely erase all library items, viewing sessions, and ratings? This action cannot be undone.',
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
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isProcessing = true);
      try {
        final service = ref.read(backupServiceProvider);
        await service.resetDatabase();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All local data has been reset.'),
              backgroundColor: AppTheme.warning,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reset failed: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Data & Storage',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isProcessing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your local database, create human-readable JSON backups, or clear cache.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted(context),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.file_upload_outlined, color: AppTheme.primary),
              title: const Text('Export JSON Backup', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text('Save entire database to a standalone JSON file', style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context))),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: _isProcessing ? null : _exportBackup,
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.file_download_outlined, color: AppTheme.primary),
              title: const Text('Import JSON Backup', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text('Restore from a valid JSON backup file', style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context))),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: _isProcessing ? null : _importBackup,
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cleaning_services_outlined, color: AppTheme.primary),
              title: const Text('Clear Cached Metadata', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text('Purge unreferenced search metadata and image cache', style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context))),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: _isProcessing ? null : _clearMetadataCache,
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_forever_outlined, color: AppTheme.error),
              title: const Text('Reset All Data', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.error)),
              subtitle: Text('Wipe local database and start fresh', style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context))),
              trailing: const Icon(Icons.chevron_right, size: 20, color: AppTheme.error),
              onTap: _isProcessing ? null : _confirmResetDatabase,
            ),
          ],
        ),
      ),
    );
  }
}
