import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/history/history_controller.dart';
import '../features/history/history_model.dart';
import '../features/medicines/medicine_controller.dart';
import '../features/medicines/medicine_model.dart';
import '../features/medicines/medicine_reminder_time.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/empty_state.dart';
import '../widgets/primary_button.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  static String _dateKey(DateTime local) {
    final y = local.year;
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _sectionTitle(String key) {
    final now = DateTime.now();
    final today = _dateKey(DateTime(now.year, now.month, now.day));
    final y = now.subtract(const Duration(days: 1));
    final yesterday = _dateKey(DateTime(y.year, y.month, y.day));
    if (key == today) return 'Today';
    if (key == yesterday) return 'Yesterday';
    return key;
  }

  static List<({String key, List<History> items})> _grouped(List<History> list) {
    final map = <String, List<History>>{};
    for (final h in list) {
      final k = _dateKey(h.createdAt.toLocal());
      map.putIfAbsent(k, () => []).add(h);
    }
    final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return [for (final k in keys) (key: k, items: map[k]!)];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(medicationHistoryStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication history'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add record'),
      ),
      body: async.when(
        data: (records) {
          if (records.isEmpty) {
            return EmptyState(
              icon: Icons.history_rounded,
              title: 'No history yet',
              subtitle: 'Mark doses as taken from your list, or add a record manually.',
              actionLabel: 'Add record',
              onAction: () => _openAddSheet(context, ref),
            );
          }
          final sections = _grouped(records);
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xl + 48,
            ),
            itemCount: sections.length,
            itemBuilder: (context, si) {
              final section = sections[si];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: si == 0 ? 0 : AppSpacing.md,
                      bottom: AppSpacing.sm,
                    ),
                    child: Text(
                      _sectionTitle(section.key),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                  ...section.items.map(
                    (h) => _HistoryDismissibleCard(
                      record: h,
                      onEdit: () => _openEditSheet(context, ref, h),
                      onDelete: () =>
                          ref.read(historyControllerProvider).deleteHistory(h.id),
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Could not load history',
          subtitle: e.toString(),
        ),
      ),
    );
  }

  static Future<void> _openAddSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _AddHistorySheet(
        onClose: () => Navigator.pop(ctx),
      ),
    );
  }

  static Future<void> _openEditSheet(
    BuildContext context,
    WidgetRef ref,
    History record,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _EditHistorySheet(
        record: record,
        onClose: () => Navigator.pop(ctx),
      ),
    );
  }
}

TimeOfDay _parseScheduledClock(String s) {
  final p = s.trim().split(':');
  if (p.length >= 2) {
    final h = int.tryParse(p[0]) ?? 0;
    final m = int.tryParse(p[1]) ?? 0;
    return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
  }
  return TimeOfDay.now();
}

class _HistoryDismissibleCard extends StatelessWidget {
  const _HistoryDismissibleCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  final History record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final taken = record.isTaken;
    final accent = taken ? AppColors.statGreen : AppColors.missed;
    final icon = taken ? Icons.check_circle_rounded : Icons.cancel_rounded;

    return Dismissible(
      key: Key(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.error,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        child: Icon(Icons.delete_outline_rounded, color: scheme.onError),
      ),
      onDismissed: (_) => onDelete(),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Material(
          color: scheme.surface,
          elevation: 0,
          shadowColor: scheme.shadow.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(icon, color: accent, size: 28),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.medicineName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          record.dose.isEmpty ? '—' : record.dose,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.xs,
                          children: [
                            _MetaChip(
                              icon: Icons.alarm_rounded,
                              label: 'Scheduled ${record.scheduledTime}',
                            ),
                            if (record.takenTime != null)
                              _MetaChip(
                                icon: Icons.event_available_rounded,
                                label:
                                    'Taken ${MedicineReminderTime.formatDateAndTime(record.takenTime!.toLocal())}',
                              ),
                            _MetaChip(
                              icon: icon,
                              label: taken ? 'Taken' : 'Missed',
                              foreground: accent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onEdit,
                    tooltip: 'Edit',
                    icon: const Icon(Icons.edit_rounded),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.foreground,
  });

  final IconData icon;
  final String label;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = foreground ?? scheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: fg),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}

class _AddHistorySheet extends ConsumerStatefulWidget {
  const _AddHistorySheet({required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<_AddHistorySheet> createState() => _AddHistorySheetState();
}

class _AddHistorySheetState extends ConsumerState<_AddHistorySheet> {
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

  String get _scheduledStr {
    final h = _scheduled.hour.toString().padLeft(2, '0');
    final m = _scheduled.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

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

class _EditHistorySheet extends ConsumerStatefulWidget {
  const _EditHistorySheet({
    required this.record,
    required this.onClose,
  });

  final History record;
  final VoidCallback onClose;

  @override
  ConsumerState<_EditHistorySheet> createState() => _EditHistorySheetState();
}

class _EditHistorySheetState extends ConsumerState<_EditHistorySheet> {
  late String _status;
  late TimeOfDay _scheduled;
  late DateTime _takenAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.record.status;
    _scheduled = _parseScheduledClock(widget.record.scheduledTime);
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

  String get _scheduledStr {
    final h = _scheduled.hour.toString().padLeft(2, '0');
    final m = _scheduled.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

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
