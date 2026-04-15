import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/medical_history/medical_history_model.dart';
import '../features/medical_history/medical_history_providers.dart';
import '../theme/app_spacing.dart';
import '../widgets/ehr_date_picker_tile.dart';
import '../widgets/medical_condition_status_selector.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_header.dart';

class AddMedicalHistoryScreen extends ConsumerStatefulWidget {
  const AddMedicalHistoryScreen({super.key, this.existing});

  final MedicalHistoryRecord? existing;

  @override
  ConsumerState<AddMedicalHistoryScreen> createState() =>
      _AddMedicalHistoryScreenState();
}

class _AddMedicalHistoryScreenState extends ConsumerState<AddMedicalHistoryScreen> {
  final _conditionController = TextEditingController();
  final _notesController = TextEditingController();

  late MedicalConditionStatus _status;
  DateTime? _onsetDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _conditionController.text = e.conditionName;
      _notesController.text = e.notes;
      _status = e.status;
      _onsetDate = e.onsetDate;
    } else {
      _status = MedicalConditionStatus.active;
    }
  }

  @override
  void dispose() {
    _conditionController.dispose();
    _notesController.dispose();
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

    final name = _conditionController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the condition or diagnosis.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final ctrl = ref.read(medicalHistoryControllerProvider);
      final existing = widget.existing;
      final now = DateTime.now();

      final rec = MedicalHistoryRecord(
        id: existing?.id ?? '',
        userId: user.uid,
        conditionName: name,
        status: _status,
        onsetDate: _onsetDate,
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
        title: Text(isEdit ? 'Edit condition' : 'Add medical condition'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SectionHeader(title: 'Condition'),
          TextField(
            controller: _conditionController,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec(
              context,
              label: 'Diagnosis / problem',
              hint: 'e.g. Hypertension, asthma',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Status'),
          MedicalConditionStatusSelector(
            value: _status,
            onChanged: (s) => setState(() => _status = s),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Onset date'),
          EhrDatePickerTile(
            value: _onsetDate,
            title: 'Approximate onset',
            subtitle: 'Optional — when symptoms or diagnosis began',
            allowClear: true,
            onChanged: (d) => setState(() => _onsetDate = d),
            lastDate: DateTime.now(),
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
              label: 'Clinical details',
              hint: 'Medications, specialists, hospitalizations…',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: isEdit ? 'Save changes' : 'Save condition',
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
