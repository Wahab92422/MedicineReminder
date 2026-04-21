import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/surgical_history/surgical_history_categories.dart';
import '../features/surgical_history/surgical_history_entry.dart';
import '../features/surgical_history/surgical_history_providers.dart';
import '../features/surgical_history/surgical_history_repository.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/date_picker_field.dart';
import '../widgets/primary_button.dart';

class AddUpdateSurgicalHistoryScreen extends ConsumerStatefulWidget {
  const AddUpdateSurgicalHistoryScreen({super.key, this.existing});

  final SurgicalHistoryEntry? existing;

  @override
  ConsumerState<AddUpdateSurgicalHistoryScreen> createState() =>
      _AddUpdateSurgicalHistoryScreenState();
}

class _AddUpdateSurgicalHistoryScreenState
    extends ConsumerState<AddUpdateSurgicalHistoryScreen> {
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  final _notesController = TextEditingController();

  String? _category;
  DateTime? _recordedAt;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _category = existing.category;
      _recordedAt = existing.recordedAt;
      _titleController.text = existing.title;
      _detailsController.text = existing.details;
      _notesController.text = existing.notes;
    } else {
      _category = SurgicalHistoryCategories.orthopedic;
      _recordedAt = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_category == null || _category!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a surgical category.')),
      );
      return;
    }
    if (_recordedAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select the recorded date and time.')),
      );
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a short title or summary.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);

    try {
      final repo = ref.read(surgicalHistoryRepositoryProvider);
      final now = DateTime.now();
      final entryId = widget.existing?.id ?? repo.allocateEntryId(user.uid);
      final entry = SurgicalHistoryEntry(
        id: entryId,
        recordedAt: _recordedAt!,
        category: _category!,
        title: _titleController.text.trim(),
        details: _detailsController.text.trim(),
        notes: _notesController.text.trim(),
        createdAt: widget.existing?.createdAt ?? now,
        updatedAt: now,
      );

      final SurgicalHistoryWriteResponse result = _isEdit
          ? await repo.updateEntry(userId: user.uid, entry: entry)
          : await repo.createEntry(userId: user.uid, entry: entry);

      if (!result.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.errorMessage ??
                  (_isEdit
                      ? 'Could not update surgical history.'
                      : 'Could not save surgical history.'),
            ),
          ),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isQueuedForSync
                ? (_isEdit
                      ? 'Updated locally. Sync will complete when connection recovers.'
                      : 'Saved locally. Sync will complete when connection recovers.')
                : (_isEdit
                      ? 'Surgical history updated.'
                      : 'Surgical history saved.'),
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save surgical history: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppScreenHeader(
        title: _isEdit ? 'Edit Surgical History' : 'Add Surgical History',
        subtitle: _isEdit
            ? 'Update the procedure summary, details, or notes for this entry.'
            : 'Record a past surgery or procedure with the context your clinicians need.',
        icon: _isEdit
            ? Icons.edit_note_outlined
            : Icons.medical_services_outlined,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          CustomDropdown<String>(
            label: 'Category',
            value: _category,
            items: SurgicalHistoryCategories.all
                .map(
                  (category) => DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _category = value),
          ),
          const SizedBox(height: AppSpacing.md),
          DatePickerField(
            label: 'Recorded date & time',
            value: _recordedAt,
            includeTime: true,
            onDateSelected: (value) => setState(() => _recordedAt = value),
          ),
          const SizedBox(height: AppSpacing.md),
          CustomTextField(
            controller: _titleController,
            label: 'Title',
            hint: 'e.g. Appendectomy, Knee arthroscopy, CABG',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          CustomTextField(
            controller: _detailsController,
            label: 'Details',
            hint: 'Hospital, surgeon, indication, or recovery notes.',
            maxLines: 4,
          ),
          const SizedBox(height: AppSpacing.md),
          CustomTextField(
            controller: _notesController,
            label: 'Notes',
            hint: 'Optional',
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: _isEdit
                ? 'Update surgical history'
                : 'Save surgical history',
            icon: _isEdit ? Icons.save_outlined : Icons.add_rounded,
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
