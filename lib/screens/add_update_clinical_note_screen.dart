import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/clinical_notes/clinical_note_entry.dart';
import '../features/clinical_notes/clinical_note_providers.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/date_picker_field.dart';
import '../widgets/primary_button.dart';

class AddUpdateClinicalNoteScreen extends ConsumerStatefulWidget {
  const AddUpdateClinicalNoteScreen({super.key, this.existing});

  final ClinicalNoteEntry? existing;

  @override
  ConsumerState<AddUpdateClinicalNoteScreen> createState() =>
      _AddUpdateClinicalNoteScreenState();
}

class _AddUpdateClinicalNoteScreenState
    extends ConsumerState<AddUpdateClinicalNoteScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;

  DateTime? _notedAt;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _bodyController = TextEditingController();

    final e = widget.existing;
    if (e != null) {
      _titleController.text = e.title;
      _bodyController.text = e.body;
      _notedAt = e.notedAt;
    } else {
      _notedAt = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a title for this note.')),
      );
      return;
    }

    if (_notedAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select date and time for this note.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);

    try {
      final repo = ref.read(clinicalNoteRepositoryProvider);
      final now = DateTime.now();
      final entryId = widget.existing?.id ?? repo.allocateNoteId(user.uid);

      final entry = ClinicalNoteEntry(
        id: entryId,
        title: title,
        body: _bodyController.text.trim(),
        notedAt: _notedAt!,
        createdAt: widget.existing?.createdAt ?? now,
        updatedAt: now,
      );

      final result = _isEdit
          ? await repo.updateEntry(userId: user.uid, entry: entry)
          : await repo.createEntry(userId: user.uid, entry: entry);

      if (!result.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.errorMessage ??
                  (_isEdit ? 'Could not update note.' : 'Could not save note.'),
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
                : (_isEdit ? 'Note updated.' : 'Note saved.'),
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppScreenHeader(
        title: _isEdit ? 'Edit clinical note' : 'Add clinical note',
        subtitle: _isEdit
            ? 'Update title, details, or the date/time of the visit or encounter.'
            : 'Record visit summaries, instructions, or questions for your care team.',
        icon: _isEdit ? Icons.edit_note_outlined : Icons.note_add_outlined,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          CustomTextField(
            controller: _titleController,
            label: 'Title',
            hint: 'e.g. Follow-up with Dr. Smith',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          DatePickerField(
            label: 'Date & time',
            value: _notedAt,
            includeTime: true,
            onDateSelected: (d) => setState(() => _notedAt = d),
          ),
          const SizedBox(height: AppSpacing.md),
          CustomTextField(
            controller: _bodyController,
            label: 'Notes',
            hint: 'Symptoms, plan, medications discussed…',
            maxLines: 8,
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: _isEdit ? 'Update note' : 'Save note',
            icon: Icons.check_rounded,
            isLoading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
