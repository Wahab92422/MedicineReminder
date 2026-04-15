import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/vitals/vital_bmi.dart';
import '../features/vitals/vital_entry_model.dart';
import '../features/vitals/vital_providers.dart';
import '../theme/app_spacing.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_header.dart';

class AddVitalScreen extends ConsumerStatefulWidget {
  const AddVitalScreen({super.key, this.existing});

  /// When set, screen updates this entry instead of creating a new one.
  final VitalEntry? existing;

  @override
  ConsumerState<AddVitalScreen> createState() => _AddVitalScreenState();
}

class _AddVitalScreenState extends ConsumerState<AddVitalScreen> {
  final _bpSysController = TextEditingController();
  final _bpDiaController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _tempController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _rrController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _glucoseController = TextEditingController();
  final _notesController = TextEditingController();

  bool _saving = false;
  double? _liveBmi;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _bpSysController.text =
          e.bloodPressureSystolic?.toString() ?? '';
      _bpDiaController.text =
          e.bloodPressureDiastolic?.toString() ?? '';
      _heartRateController.text = e.heartRate?.toString() ?? '';
      _tempController.text = e.temperatureC?.toString() ?? '';
      _heightController.text = e.heightCm?.toString() ?? '';
      _weightController.text = e.weightKg?.toString() ?? '';
      _rrController.text = e.respiratoryRate?.toString() ?? '';
      _spo2Controller.text = e.oxygenSaturation?.toString() ?? '';
      _glucoseController.text = e.bloodGlucose?.toString() ?? '';
      _notesController.text = e.notes;
      _liveBmi = computeBmiFromMetric(
        heightCm: e.heightCm,
        weightKg: e.weightKg,
      );
    }
    void recomputeBmi() {
      final h = _parseDouble(_heightController.text);
      final w = _parseDouble(_weightController.text);
      setState(() {
        _liveBmi = computeBmiFromMetric(heightCm: h, weightKg: w);
      });
    }

    _heightController.addListener(recomputeBmi);
    _weightController.addListener(recomputeBmi);
  }

  @override
  void dispose() {
    _bpSysController.dispose();
    _bpDiaController.dispose();
    _heartRateController.dispose();
    _tempController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _rrController.dispose();
    _spo2Controller.dispose();
    _glucoseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int? _parseInt(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  double? _parseDouble(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t.replaceAll(',', '.'));
  }

  bool _hasAnyInput() {
    bool nonEmpty(String s) => s.trim().isNotEmpty;
    return nonEmpty(_bpSysController.text) ||
        nonEmpty(_bpDiaController.text) ||
        nonEmpty(_heartRateController.text) ||
        nonEmpty(_tempController.text) ||
        nonEmpty(_heightController.text) ||
        nonEmpty(_weightController.text) ||
        nonEmpty(_rrController.text) ||
        nonEmpty(_spo2Controller.text) ||
        nonEmpty(_glucoseController.text) ||
        nonEmpty(_notesController.text);
  }

  Future<void> _save() async {
    if (!_hasAnyInput()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter at least one vital or a note.'),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final bpS = _parseInt(_bpSysController.text);
    final bpD = _parseInt(_bpDiaController.text);
    if ((bpS != null) != (bpD != null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter both systolic and diastolic for blood pressure, or leave both empty.',
          ),
        ),
      );
      return;
    }

    final spo2 = _parseInt(_spo2Controller.text);
    if (spo2 != null && (spo2 < 0 || spo2 > 100)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oxygen saturation must be between 0 and 100.')),
      );
      return;
    }

    setState(() => _saving = true);

    final height = _parseDouble(_heightController.text);
    final weight = _parseDouble(_weightController.text);
    final bmi = computeBmiFromMetric(heightCm: height, weightKg: weight);

    final existing = widget.existing;
    final entry = VitalEntry(
      id: existing?.id ?? '',
      userId: existing?.userId ?? user.uid,
      recordedAt: existing?.recordedAt ?? DateTime.now(),
      bloodPressureSystolic: bpS,
      bloodPressureDiastolic: bpD,
      heartRate: _parseInt(_heartRateController.text),
      temperatureC: _parseDouble(_tempController.text),
      heightCm: height,
      weightKg: weight,
      bmi: bmi,
      respiratoryRate: _parseInt(_rrController.text),
      oxygenSaturation: spo2,
      bloodGlucose: _parseDouble(_glucoseController.text),
      notes: _notesController.text.trim(),
    );

    try {
      if (existing != null) {
        await ref.read(vitalControllerProvider).updateVital(entry);
      } else {
        await ref.read(vitalRepositoryProvider).addVital(entry);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    String? labelText,
    String? hintText,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      alignLabelWithHint: alignLabelWithHint,
    ).applyDefaults(Theme.of(context).inputDecorationTheme);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit vitals' : 'Add vitals'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SectionHeader(title: 'Blood pressure'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _bpSysController,
                  keyboardType: TextInputType.number,
                  decoration: _fieldDecoration(
                    context,
                    labelText: 'Systolic (mmHg)',
                    hintText: 'e.g. 120',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextField(
                  controller: _bpDiaController,
                  keyboardType: TextInputType.number,
                  decoration: _fieldDecoration(
                    context,
                    labelText: 'Diastolic (mmHg)',
                    hintText: 'e.g. 80',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Cardiovascular & breathing'),
          TextField(
            controller: _heartRateController,
            keyboardType: TextInputType.number,
            decoration: _fieldDecoration(
              context,
              labelText: 'Heart rate (bpm)',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _rrController,
            keyboardType: TextInputType.number,
            decoration: _fieldDecoration(
              context,
              labelText: 'Respiratory rate (breaths/min)',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _spo2Controller,
            keyboardType: TextInputType.number,
            decoration: _fieldDecoration(
              context,
              labelText: 'Oxygen saturation (%)',
              hintText: '0–100',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Temperature'),
          TextField(
            controller: _tempController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _fieldDecoration(
              context,
              labelText: 'Temperature (°C)',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Body metrics'),
          TextField(
            controller: _heightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _fieldDecoration(
              context,
              labelText: 'Height (cm)',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _fieldDecoration(
              context,
              labelText: 'Weight (kg)',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InputDecorator(
            decoration: _fieldDecoration(
              context,
              labelText: 'BMI (auto)',
            ),
            child: Text(
              _liveBmi != null ? _liveBmi!.toStringAsFixed(1) : '—',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Metabolic'),
          TextField(
            controller: _glucoseController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _fieldDecoration(
              context,
              labelText: 'Blood glucose (mg/dL)',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Notes'),
          TextField(
            controller: _notesController,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: _fieldDecoration(
              context,
              labelText: 'Notes',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: isEdit ? 'Update vitals' : 'Save vitals',
            icon: Icons.check_rounded,
            isLoading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
