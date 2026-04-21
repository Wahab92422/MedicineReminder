import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/vitals/vital_entry.dart';
import '../features/vitals/vital_providers.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/date_picker_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/speech_text_field.dart';

/// Create or edit a vitals entry (Firestore).
class AddUpdateVitalsScreen extends ConsumerStatefulWidget {
  const AddUpdateVitalsScreen({super.key, this.existing});

  final VitalEntry? existing;

  @override
  ConsumerState<AddUpdateVitalsScreen> createState() =>
      _AddUpdateVitalsScreenState();
}

class _AddUpdateVitalsScreenState extends ConsumerState<AddUpdateVitalsScreen> {
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _tempController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _glucoseController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _recordedAt;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _recordedAt = e.recordedAt;
      if (e.systolicMmHg != null) {
        _systolicController.text = '${e.systolicMmHg}';
      }
      if (e.diastolicMmHg != null) {
        _diastolicController.text = '${e.diastolicMmHg}';
      }
      if (e.heartRateBpm != null) {
        _heartRateController.text = '${e.heartRateBpm}';
      }
      if (e.temperatureCelsius != null) {
        _tempController.text = e.temperatureCelsius!.toStringAsFixed(1);
      }
      if (e.weightKg != null) {
        _weightController.text = e.weightKg!.toStringAsFixed(1);
      }
      if (e.heightCm != null) {
        _heightController.text = e.heightCm!.toStringAsFixed(0);
      }
      if (e.glucoseMgDl != null) {
        _glucoseController.text = _formatNumber(e.glucoseMgDl!);
      }
      if (e.spo2Percent != null) {
        _spo2Controller.text = '${e.spo2Percent}';
      }
      _notesController.text = e.notes;
    } else {
      _recordedAt = DateTime.now();
    }
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _heartRateController.dispose();
    _tempController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _glucoseController.dispose();
    _spo2Controller.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int? _parseInt(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  double? _parseDouble(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t.replaceAll(',', '.'));
  }

  String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  VitalEntry _buildEntry(String entryId, DateTime now) {
    return VitalEntry(
      id: entryId,
      recordedAt: _recordedAt!,
      systolicMmHg: _parseInt(_systolicController.text),
      diastolicMmHg: _parseInt(_diastolicController.text),
      heartRateBpm: _parseInt(_heartRateController.text),
      temperatureCelsius: _parseDouble(_tempController.text),
      weightKg: _parseDouble(_weightController.text),
      heightCm: _parseDouble(_heightController.text),
      glucoseMgDl: _parseDouble(_glucoseController.text),
      spo2Percent: _parseInt(_spo2Controller.text),
      notes: _notesController.text.trim(),
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );
  }

  Future<void> _save() async {
    if (_recordedAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select date and time recorded.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final repo = ref.read(vitalRepositoryProvider);
    final uid = user.uid;
    final entryId = widget.existing?.id ?? repo.allocateEntryId(uid);
    final entry = _buildEntry(entryId, now);

    if (!entry.hasAnyData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter at least one measurement or notes.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final result = _isEdit
          ? await repo.updateEntry(userId: uid, entry: entry)
          : await repo.createEntry(userId: uid, entry: entry);

      if (!result.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.errorMessage ??
                  (_isEdit
                      ? 'Could not update vitals.'
                      : 'Could not save vitals.'),
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
                : (_isEdit ? 'Vitals updated.' : 'Vitals saved.'),
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
        title: _isEdit ? 'Edit Vitals' : 'Add Vitals',
        subtitle: _isEdit
            ? 'Adjust values, timing, or notes for this entry.'
            : 'Save a new vitals record for future tracking.',
        icon: _isEdit ? Icons.edit_note_outlined : Icons.monitor_heart_outlined,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              DatePickerField(
                label: 'Recorded at',
                value: _recordedAt,
                includeTime: true,
                onDateSelected: (d) => setState(() => _recordedAt = d),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Measurements',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _systolicController,
                      label: 'Systolic (mmHg)',
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: CustomTextField(
                      controller: _diastolicController,
                      label: 'Diastolic (mmHg)',
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                controller: _heartRateController,
                label: 'Heart rate (bpm)',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                autocorrect: false,
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                controller: _tempController,
                label: 'Temperature (°C)',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                autocorrect: false,
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                controller: _spo2Controller,
                label: 'SpO₂ (%)',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                autocorrect: false,
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                controller: _weightController,
                label: 'Weight (kg)',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                autocorrect: false,
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                controller: _heightController,
                label: 'Height (cm)',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                autocorrect: false,
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                controller: _glucoseController,
                label: 'Glucose (mg/dL)',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                autocorrect: false,
              ),
              const SizedBox(height: AppSpacing.md),
              SpeechTextField(
                controller: _notesController,
                label: 'Notes',
                maxLines: 3,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: _isEdit ? 'Update vitals' : 'Save vitals',
                icon: Icons.check_rounded,
                isLoading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
          if (_saving) const _BlockingLoadingOverlay(message: 'Saving…'),
        ],
      ),
    );
  }
}

class _BlockingLoadingOverlay extends StatelessWidget {
  const _BlockingLoadingOverlay({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const ModalBarrier(dismissible: false, color: Colors.black45),
        Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(message),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
