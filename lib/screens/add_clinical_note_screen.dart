import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/clinical_notes/clinical_note_model.dart';
import '../features/clinical_notes/clinical_note_providers.dart';
import '../theme/app_spacing.dart';
import '../widgets/clinical_note_category_selector.dart';
import '../widgets/meal_datetime_picker_tile.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_header.dart';

class AddClinicalNoteScreen extends ConsumerStatefulWidget {
  const AddClinicalNoteScreen({super.key, this.existing});

  final ClinicalNote? existing;

  @override
  ConsumerState<AddClinicalNoteScreen> createState() =>
      _AddClinicalNoteScreenState();
}

class _AddClinicalNoteScreenState extends ConsumerState<AddClinicalNoteScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  late ClinicalNoteCategory _category;
  late DateTime _encounterAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleController.text = e.title;
      _bodyController.text = e.body;
      _category = e.category;
      _encounterAt = e.encounterAt;
    } else {
      _category = ClinicalNoteCategory.general;
      _encounterAt = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  InputDecoration _dec(BuildContext context, {String? label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
    ).applyDefaults(Theme.of(context).inputDecorationTheme);
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a title for this note.')),
      );
      return;
    }
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the clinical note content.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final ctrl = ref.read(clinicalNoteControllerProvider);
      final existing = widget.existing;
      final now = DateTime.now();

      if (existing == null) {
        final note = ClinicalNote(
          id: '',
          userId: user.uid,
          title: title,
          body: body,
          category: _category,
          encounterAt: _encounterAt,
          createdAt: now,
          updatedAt: now,
        );
        await ctrl.addNote(note);
      } else {
        final note = ClinicalNote(
          id: existing.id,
          userId: existing.userId,
          title: title,
          body: body,
          category: _category,
          encounterAt: _encounterAt,
          createdAt: existing.createdAt,
          updatedAt: now,
        );
        await ctrl.updateNote(note);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit clinical note' : 'Add clinical note'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SectionHeader(title: 'Category'),
          ClinicalNoteCategorySelector(
            value: _category,
            onChanged: (c) => setState(() => _category = c),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Title'),
          TextField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec(
              context,
              label: 'Note title',
              hint: 'e.g. Follow-up — diabetes management',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Encounter date & time'),
          MealDateTimePickerTile(
            value: _encounterAt,
            title: 'When did this encounter happen?',
            onChanged: (d) => setState(() => _encounterAt = d),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Clinical narrative'),
          TextField(
            controller: _bodyController,
            minLines: 8,
            maxLines: 18,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec(
              context,
              label: 'Note body',
              hint:
                  'Subjective, objective, assessment, plan, or free-text documentation…',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: isEdit ? 'Save changes' : 'Save note',
            isLoading: _saving,
            icon: Icons.check_rounded,
            onPressed: _saving ? null : _submit,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
