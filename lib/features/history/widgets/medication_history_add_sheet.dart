import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../medicines/medicine_controller.dart';
import '../../medicines/medicine_model.dart';
import '../../medicines/medicine_reminder_time.dart';
import '../../../services/time_clock_service.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/primary_button.dart';
import '../history_controller.dart';
import '../history_model.dart';

class MedicationHistoryAddSheet extends ConsumerStatefulWidget {
  const MedicationHistoryAddSheet({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<MedicationHistoryAddSheet> createState() =>
      _MedicationHistoryAddSheetState();
}

class _MedicationHistoryAddSheetState extends ConsumerState<MedicationHistoryAddSheet> {
  Medicine? _selected;
  String _status = 'taken';
  TimeOfDay _scheduled = TimeOfDay.now();
  DateTime _takenAt = DateTime.now();
  bool _saving = false;

  Future<void> _pickScheduled() async {
    final t = await showTimePicker(context: context, initialTime: _scheduled);
    if (t != null) setState(() => _scheduled = t);
  }

  Future<void> _pickTaken() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _takenAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_takenAt),
    );
    if (t != null) {
      setState(() {
        _takenAt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
      });
    }
  }

  String get _scheduledStr => TimeClockService.toHHmm(_scheduled);

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    final list = ref.read(medicineStreamProvider).asData?.value;
    if (list == null || list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a medicine first.')),
      );
      return;
    }
    final med = _selected != null && list.any((m) => m.id == _selected!.id)
        ? _selected!
        : list.first;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      await ref.read(historyControllerProvider).addHistory(
            History(
              id: '',
              userId: user.uid,
              medicineId: med.id,
              medicineName: med.name,
              dose: med.dose,
              scheduledTime: _scheduledStr,
              takenTime: _status == 'taken' ? _takenAt : null,
              status: _status,
              createdAt: now,
            ),
          );
      if (mounted) widget.onClose();
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
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final medsAsync = ref.watch(medicineStreamProvider);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: bottom + AppSpacing.md,
        top: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Add record',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          medsAsync.when(
            data: (list) {
              if (list.isEmpty) {
                return Text(
                  'No medicines yet. Add one from the Medicines tab.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                );
              }
              final med = _selected != null && list.any((m) => m.id == _selected!.id)
                  ? _selected!
                  : list.first;
              return InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Medicine',
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Medicine>(
                    isExpanded: true,
                    value: med,
                    items: list
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(m.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selected = v),
                  ),
                ),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Status', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'taken', label: Text('Taken'), icon: Icon(Icons.check_rounded)),
              ButtonSegment(value: 'missed', label: Text('Missed'), icon: Icon(Icons.close_rounded)),
            ],
            selected: {_status},
            onSelectionChanged: (s) => setState(() => _status = s.first),
          ),
          const SizedBox(height: AppSpacing.md),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Scheduled time'),
            subtitle: Text(_scheduledStr),
            trailing: const Icon(Icons.schedule_rounded),
            onTap: _pickScheduled,
          ),
          if (_status == 'taken')
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Taken at'),
              subtitle: Text(
                MedicineReminderTime.formatDateAndTime(_takenAt.toLocal()),
              ),
              trailing: const Icon(Icons.event_rounded),
              onTap: _pickTaken,
            ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Save record',
            icon: Icons.save_rounded,
            isLoading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
