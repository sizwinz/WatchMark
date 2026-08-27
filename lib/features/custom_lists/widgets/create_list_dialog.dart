import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watchmark/app/theme.dart';
import 'package:watchmark/core/database/app_database.dart';
import 'package:watchmark/core/utilities/uuid_helper.dart';
import 'package:watchmark/shared/providers/database_provider.dart';

class CreateListDialog extends ConsumerStatefulWidget {
  final CustomList? existingList;

  const CreateListDialog({super.key, this.existingList});

  @override
  ConsumerState<CreateListDialog> createState() => _CreateListDialogState();
}

class _CreateListDialogState extends ConsumerState<CreateListDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late bool _isRanked;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingList?.name ?? '');
    _descController = TextEditingController(text: widget.existingList?.description ?? '');
    _isRanked = widget.existingList?.isRanked ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    final dao = ref.read(customListsDaoProvider);

    if (widget.existingList != null) {
      await dao.updateList(
        CustomListsCompanion(
          id: drift.Value(widget.existingList!.id),
          name: drift.Value(name),
          description: drift.Value(_descController.text.trim().isNotEmpty ? _descController.text.trim() : null),
          isRanked: drift.Value(_isRanked),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
    } else {
      await dao.createList(
        CustomListsCompanion.insert(
          id: drift.Value(generateUuidV7()),
          name: name,
          description: drift.Value(_descController.text.trim().isNotEmpty ? _descController.text.trim() : null),
          isRanked: drift.Value(_isRanked),
          createdAt: drift.Value(DateTime.now()),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingList != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Custom List' : 'Create Custom List'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'List Name *',
                hintText: 'e.g. Spooky Season, Top Sci-Fi',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Notes or theme for this list...',
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ranked List', style: TextStyle(fontSize: 14)),
              subtitle: Text(
                'Show numbered positions (#1, #2, ...)',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context)),
              ),
              value: _isRanked,
              thumbColor: const WidgetStatePropertyAll(AppTheme.primary),
              onChanged: (val) => setState(() => _isRanked = val),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(isEditing ? 'Save Changes' : 'Create List'),
        ),
      ],
    );
  }
}
