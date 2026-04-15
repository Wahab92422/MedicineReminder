import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/surgical_history/surgical_history_model.dart';
import '../features/surgical_history/surgical_history_providers.dart';
import '../theme/app_spacing.dart';
import '../widgets/ehr_date_picker_tile.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_header.dart';

class AddSurgicalHistoryScreen extends ConsumerStatefulWidget {
  const AddSurgicalHistoryScreen({super.key, this.existing});

  final SurgicalHistoryRecord? existing;

  @override
  ConsumerState<AddSurgicalHistoryScreen> createState() =>
      _AddSurgicalHistoryScreenState();
}

class _AddSurgicalHistoryScreenState extends ConsumerState<AddSurgicalHistoryScreen> {
  final _procedureController = TextEditingController();
  final _surgeonController = TextEditingController();
  final _facilityController = TextEditingController();
  final _siteController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _procedureDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _procedureController.text = e.procedureName;
      _surgeonController.text = e.surgeonName;
      _facilityController.text = e.facilityName;
      _siteController.text = e.bodySite;
      _notesController.text = e.notes;
      _procedureDate = e.procedureDate;
    } else {
      final n = DateTime.now();
      _procedureDate = DateTime(n.year, n.month, n.day);
    }
  }

  @override
  void dispose() {
    _procedureController.dispose();
    _surgeonController.dispose();
    _facilityController.dispose();
    _siteController.dispose();
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

    final name = _procedureController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the procedure name.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final ctrl = ref.read(surgicalHistoryControllerProvider);
      final existing = widget.existing;
      final now = DateTime.now();

      final rec = SurgicalHistoryRecord(
        id: existing?.id ?? '',
        userId: user.uid,
        procedureName: name,
        procedureDate: _procedureDate,
        surgeonName: _surgeonController.text.trim(),
        facilityName: _facilityController.text.trim(),
        bodySite: _siteController.text.trim(),
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
        title: Text(isEdit ? 'Edit procedure' : 'Add surgical procedure'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SectionHeader(title: 'Procedure'),
          TextField(
            controller: _procedureController,
            textCapitalization: TextCapitalization.words,
            decoration: _dec(
              context,
              label: 'Procedure name',
              hint: 'e.g. Laparoscopic cholecystectomy',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Procedure date'),
          EhrDatePickerTile(
            value: _procedureDate,
            title: 'Date of surgery',
            subtitle: 'When the procedure was performed',
            onChanged: (d) {
              if (d != null) setState(() => _procedureDate = d);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Details (optional)'),
          TextField(
            controller: _surgeonController,
            textCapitalization: TextCapitalization.words,
            decoration: _dec(context, label: 'Surgeon / provider'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _facilityController,
            textCapitalization: TextCapitalization.words,
            decoration: _dec(context, label: 'Hospital or facility'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _siteController,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec(
              context,
              label: 'Body site / side',
              hint: 'e.g. Right knee',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Clinical notes'),
          TextField(
            controller: _notesController,
            minLines: 4,
            maxLines: 10,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec(
              context,
              label: 'Operative summary & follow-up',
              hint: 'Indication, findings, complications…',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: isEdit ? 'Save changes' : 'Save procedure',
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
