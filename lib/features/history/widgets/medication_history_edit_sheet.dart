import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../medicines/medicine_reminder_time.dart';
import '../../../services/time_clock_service.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/primary_button.dart';
import '../history_controller.dart';
import '../history_model.dart';

class MedicationHistoryEditSheet extends ConsumerStatefulWidget {
  const MedicationHistoryEditSheet({
    super.key,
    required this.record,
    required this.onClose,
  });

  final History record;
  final VoidCallback onClose;

  @override
  ConsumerState<MedicationHistoryEditSheet> createState() =>
      _MedicationHistoryEditSheetState();
}

class _MedicationHistoryEditSheetState extends ConsumerState<MedicationHistoryEditSheet> {
  late String _status;
  late TimeOfDay _scheduled;
  late DateTime _takenAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.record.status;
    _scheduled = TimeClockService.parseScheduledClock(widget.record.scheduledTime);
    _takenAt = widget.record.takenTime ?? DateTime.now();
  }

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
    setState(() => _saving = true);
    try {
      final updated = widget.record.copyWith(
        scheduledTime: _scheduledStr,
        status: _status,
        takenTime: _status == 'taken' ? _takenAt : null,
        clearTakenTime: _status == 'missed',
      );
      await ref.read(historyControllerProvider).updateHistory(updated);
      if (mounted) widget.onClose();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

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
            'Edit record',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            widget.record.medicineName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
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
            label: 'Update record',
            icon: Icons.save_rounded,
            isLoading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
