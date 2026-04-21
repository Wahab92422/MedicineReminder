import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/social_history/social_history_categories.dart';
import '../features/social_history/social_history_entry.dart';
import '../features/social_history/social_history_providers.dart';
import '../features/social_history/social_history_repository.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/date_picker_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/speech_text_field.dart';

class AddUpdateSocialHistoryScreen extends ConsumerStatefulWidget {
  const AddUpdateSocialHistoryScreen({super.key, this.existing});

  final SocialHistoryEntry? existing;

  @override
  ConsumerState<AddUpdateSocialHistoryScreen> createState() =>
      _AddUpdateSocialHistoryScreenState();
}

class _AddUpdateSocialHistoryScreenState
    extends ConsumerState<AddUpdateSocialHistoryScreen> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  String? _category;
  DateTime? _recordedAt;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  static String _mergedNotes(String details, String notes) {
    final d = details.trim();
    final n = notes.trim();
    if (d.isEmpty) return n;
    if (n.isEmpty) return d;
    return '$d\n\n$n';
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _category = existing.category;
      _recordedAt = existing.recordedAt;
      _titleController.text = existing.title;
      _notesController.text = _mergedNotes(existing.details, existing.notes);
    } else {
      _category = SocialHistoryCategories.tobacco;
      _recordedAt = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_category == null || _category!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a social history category.')),
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
      final repo = ref.read(socialHistoryRepositoryProvider);
      final now = DateTime.now();
      final entryId = widget.existing?.id ?? repo.allocateEntryId(user.uid);
      final entry = SocialHistoryEntry(
        id: entryId,
        recordedAt: _recordedAt!,
        category: _category!,
        title: _titleController.text.trim(),
        details: '',
        notes: _notesController.text.trim(),
        createdAt: widget.existing?.createdAt ?? now,
        updatedAt: now,
      );

      final SocialHistoryWriteResponse result = _isEdit
          ? await repo.updateEntry(userId: user.uid, entry: entry)
          : await repo.createEntry(userId: user.uid, entry: entry);

      if (!result.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.errorMessage ??
                  (_isEdit
                      ? 'Could not update social history.'
                      : 'Could not save social history.'),
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
                      ? 'Social history updated.'
                      : 'Social history saved.'),
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save social history: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppScreenHeader(
        title: _isEdit ? 'Edit Social History' : 'Add Social History',
        subtitle: _isEdit
            ? 'Update the context, summary, or notes for this entry.'
            : 'Record a social factor like habits, sleep, work, or living situation.',
        icon: _isEdit ? Icons.edit_note_outlined : Icons.groups_2_outlined,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          CustomDropdown<String>(
            label: 'Category',
            value: _category,
            items: SocialHistoryCategories.all
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
            hint: 'e.g. Former smoker, Night-shift job, Walks daily',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          SpeechTextField(
            controller: _notesController,
            label: 'Notes',
            hint: 'Context, habits, or anything else you want to remember.',
            maxLines: 6,
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: _isEdit ? 'Update social history' : 'Save social history',
            icon: _isEdit ? Icons.save_outlined : Icons.add_rounded,
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
