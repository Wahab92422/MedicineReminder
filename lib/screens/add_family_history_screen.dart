import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/family_history/family_history_model.dart';
import '../features/family_history/family_history_providers.dart';
import '../theme/app_spacing.dart';
import '../widgets/family_relationship_selector.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_header.dart';

class AddFamilyHistoryScreen extends ConsumerStatefulWidget {
  const AddFamilyHistoryScreen({super.key, this.existing});

  final FamilyHistoryRecord? existing;

  @override
  ConsumerState<AddFamilyHistoryScreen> createState() =>
      _AddFamilyHistoryScreenState();
}

class _AddFamilyHistoryScreenState extends ConsumerState<AddFamilyHistoryScreen> {
  final _conditionController = TextEditingController();
  final _ageController = TextEditingController();
  final _notesController = TextEditingController();

  late FamilyRelationship _relationship;
  bool _deceased = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _conditionController.text = e.conditionName;
      if (e.ageAtOnset != null) {
        _ageController.text = '${e.ageAtOnset}';
      }
      _notesController.text = e.notes;
      _relationship = e.relationship;
      _deceased = e.deceased;
    } else {
      _relationship = FamilyRelationship.father;
    }
  }

  @override
  void dispose() {
    _conditionController.dispose();
    _ageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  InputDecoration _dec(BuildContext context, {String? label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
    ).applyDefaults(Theme.of(context).inputDecorationTheme);
  }

  int? _parseAge() {
    final t = _ageController.text.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final condition = _conditionController.text.trim();
    if (condition.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the condition or diagnosis.')),
      );
      return;
    }

    final age = _parseAge();
    if (_ageController.text.trim().isNotEmpty && age == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Age at onset must be a whole number.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final ctrl = ref.read(familyHistoryControllerProvider);
      final existing = widget.existing;
      final now = DateTime.now();

      final rec = FamilyHistoryRecord(
        id: existing?.id ?? '',
        userId: user.uid,
        relationship: _relationship,
        conditionName: condition,
        ageAtOnset: age,
        deceased: _deceased,
        notes: _notesController.text.trim(),
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );

      if (existing == null) {
        await ctrl.add(rec);
      } else {
        await ctrl.update(rec);
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
        title: Text(isEdit ? 'Edit family history' : 'Add family history'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SectionHeader(title: 'Relationship to you'),
          FamilyRelationshipSelector(
            value: _relationship,
            onChanged: (r) => setState(() => _relationship = r),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Condition'),
          TextField(
            controller: _conditionController,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec(
              context,
              label: 'Condition / diagnosis',
              hint: 'e.g. Type 2 diabetes, breast cancer',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _dec(
              context,
              label: 'Age at onset (optional)',
              hint: 'Years',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Relative is deceased'),
            value: _deceased,
            onChanged: (v) => setState(() => _deceased = v),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Notes'),
          TextField(
            controller: _notesController,
            minLines: 4,
            maxLines: 10,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec(
              context,
              label: 'Additional details',
              hint: 'Treatment, age at death, genetic testing…',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: isEdit ? 'Save changes' : 'Save entry',
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
