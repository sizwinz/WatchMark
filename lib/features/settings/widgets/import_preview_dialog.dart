import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:watchmark/app/theme.dart';
import 'package:watchmark/core/services/backup_service.dart';

class ImportPreviewDialog extends StatefulWidget {
  final BackupValidationResult validation;
  final Future<void> Function(bool overwrite) onConfirm;

  const ImportPreviewDialog({
    super.key,
    required this.validation,
    required this.onConfirm,
  });

  static Future<bool?> show(
    BuildContext context, {
    required BackupValidationResult validation,
    required Future<void> Function(bool overwrite) onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ImportPreviewDialog(
        validation: validation,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<ImportPreviewDialog> createState() => _ImportPreviewDialogState();
}

class _ImportPreviewDialogState extends State<ImportPreviewDialog> {
  bool _overwrite = false;
  bool _isImporting = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final v = widget.validation;
    final dateStr = v.exportedAt != null
        ? DateFormat('MMM dd, yyyy • hh:mm a').format(v.exportedAt!.toLocal())
        : 'Unknown Date';

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.restore_page_outlined, color: AppTheme.primary),
          SizedBox(width: 10),
          Text('Import Backup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backup File Summary',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textMuted(context)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated(context),
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              ),
              child: Column(
                children: [
                  _SummaryRow(label: 'Exported', value: dateStr),
                  const Divider(height: 12),
                  _SummaryRow(label: 'Library Titles', value: '${v.libraryCount}'),
                  const Divider(height: 12),
                  _SummaryRow(label: 'Media Metadata', value: '${v.titleCount} titles, ${v.episodeCount} episodes'),
                  const Divider(height: 12),
                  _SummaryRow(label: 'Watch Sessions', value: '${v.sessionCount}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Import Strategy',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textMuted(context)),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Overwrite Entire Database', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              subtitle: Text(
                _overwrite
                    ? 'Wipes current database and replaces everything with this backup.'
                    : 'Smart Merge: Keeps local items and updates/adds records from backup.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context)),
              ),
              value: _overwrite,
              thumbColor: const WidgetStatePropertyAll(AppTheme.warning),
              onChanged: (val) {
                setState(() {
                  _overwrite = val;
                });
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppTheme.error, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isImporting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isImporting
              ? null
              : () async {
                  setState(() {
                    _isImporting = true;
                    _errorMessage = null;
                  });
                  try {
                    await widget.onConfirm(_overwrite);
                    if (!context.mounted) return;
                    Navigator.of(context).pop(true);
                  } catch (e) {
                    if (mounted) {
                      setState(() {
                        _isImporting = false;
                        _errorMessage = 'Import failed: $e';
                      });
                    }
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: _overwrite ? AppTheme.warning : AppTheme.primary,
            foregroundColor: Colors.white,
          ),
          child: _isImporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(_overwrite ? 'Confirm Overwrite' : 'Apply Merge'),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context))),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
