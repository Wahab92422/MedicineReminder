import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/schedule/schedule_providers.dart';
import '../features/schedule/schedule_reminder_sheet_result.dart';
import '../features/schedule/unified_schedule_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/skeleton_placeholders.dart';
import 'add_schedule_reminder_sheet.dart';
import 'add_update_appointment_screen.dart';
import 'add_update_meal_screen.dart';
import 'add_update_medicine_log_screen.dart';

/// First line → visit title; remaining lines → notes (for Schedule → appointment flow).
(String, String) _splitAppointmentTitleNotes(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return ('Appointment', '');
  final i = t.indexOf('\n');
  if (i == -1) return (t, '');
  return (t.substring(0, i).trim(), t.substring(i + 1).trim());
}

/// Month calendar plus daily agenda from appointments, meals, medicine logs, and user reminders.
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  late DateTime _monthStart;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _monthStart = DateTime(now.year, now.month, 1);
    _selectedDay = dateOnly(now);
  }

  void _shiftMonth(int delta) {
    final d = DateTime(_monthStart.year, _monthStart.month + delta, 1);
    setState(() {
      _monthStart = d;
      if (_selectedDay.year != d.year || _selectedDay.month != d.month) {
        _selectedDay = DateTime(d.year, d.month, 1);
      }
    });
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _refreshMonth() {
    ref.invalidate(scheduleMonthDataProvider(_monthStart));
  }

  Future<void> _openItem(UnifiedScheduleItem item) async {
    switch (item.source) {
      case UnifiedScheduleSource.appointment:
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) =>
                AddUpdateAppointmentScreen(existing: item.appointment),
          ),
        );
        break;
      case UnifiedScheduleSource.meal:
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => AddUpdateMealScreen(existing: item.meal),
          ),
        );
        break;
      case UnifiedScheduleSource.medicineLog:
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) =>
                AddUpdateMedicineLogScreen(existing: item.medicineLog),
          ),
        );
        break;
      case UnifiedScheduleSource.userReminder:
        await _confirmDeleteUserReminder(item);
        return;
    }
    if (mounted) _refreshMonth();
  }

  Future<void> _confirmDeleteUserReminder(UnifiedScheduleItem item) async {
    final r = item.userReminder;
    if (r == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete reminder?'),
        content: Text(
          'Remove “${r.title}” and cancel its notification.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref.read(userScheduleReminderRepositoryProvider).deleteReminder(
            userId: uid,
            reminderId: r.id,
          );
      if (mounted) _refreshMonth();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final monthAsync = ref.watch(scheduleMonthDataProvider(_monthStart));
    final loc = MaterialLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await showModalBottomSheet<ScheduleReminderSheetResult?>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => const AddScheduleReminderSheet(),
          );
          if (!context.mounted || result == null) return;

          if (result is ScheduleReminderGeneralSaved) {
            _refreshMonth();
            return;
          }

          if (result is ScheduleReminderOpenMeal) {
            await Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => AddUpdateMealScreen(
                  initialMealAt: result.mealAt,
                  initialNotes: result.prefilledNotes,
                  lockStatusToScheduled: true,
                ),
              ),
            );
          } else if (result is ScheduleReminderOpenAppointment) {
            final split = _splitAppointmentTitleNotes(result.prefilledNotes);
            await Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => AddUpdateAppointmentScreen(
                  initialScheduledAt: result.scheduledAt,
                  initialTitle: split.$1,
                  initialNotes: split.$2,
                  lockStatusToScheduled: true,
                ),
              ),
            );
          } else if (result is ScheduleReminderOpenMedicineLog) {
            await Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => AddUpdateMedicineLogScreen(
                  initialLoggedAt: result.loggedAt,
                  initialNotes: result.prefilledNotes,
                  lockStatusToScheduled: true,
                ),
              ),
            );
          }

          if (context.mounted) _refreshMonth();
        },
        icon: const Icon(Icons.add_alert_rounded),
        label: const Text('Reminder'),
      ),
      body: monthAsync.when(
        loading: () => const ListLoadingSkeleton(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            96,
          ),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Could not load schedule',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '$e',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: _refreshMonth,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          final dayItems = items
              .where((e) => _sameDay(e.at, _selectedDay))
              .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              96,
            ),
            children: [
              _MonthHeader(
                monthStart: _monthStart,
                onPrev: () => _shiftMonth(-1),
                onNext: () => _shiftMonth(1),
              ),
              const SizedBox(height: AppSpacing.sm),
              _MonthCalendar(
                monthStart: _monthStart,
                selectedDay: _selectedDay,
                items: items,
                onSelectDay: (d) => setState(() => _selectedDay = d),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                loc.formatMediumDate(_selectedDay),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (dayItems.isEmpty)
                const SizedBox(
                  height: 200,
                  child: EmptyStateWidget(
                    title: 'Nothing on this day',
                    subtitle:
                        'Add a reminder with the button below, or log meals, medicines, and appointments in their screens.',
                    icon: Icons.event_available_outlined,
                  ),
                )
              else
                ...dayItems.map(
                  (e) => _ScheduleItemTile(
                    item: e,
                    onTap: () => _openItem(e),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.monthStart,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime monthStart;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final label = loc.formatMonthYear(monthStart);
    return Row(
      children: [
        IconButton(
          tooltip: 'Previous month',
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Next month',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.monthStart,
    required this.selectedDay,
    required this.items,
    required this.onSelectDay,
  });

  final DateTime monthStart;
  final DateTime selectedDay;
  final List<UnifiedScheduleItem> items;
  final ValueChanged<DateTime> onSelectDay;

  static const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  Set<UnifiedScheduleSource> _sourcesOnDay(DateTime day) {
    final out = <UnifiedScheduleSource>{};
    for (final it in items) {
      if (it.at.year == day.year &&
          it.at.month == day.month &&
          it.at.day == day.day) {
        out.add(it.source);
      }
    }
    return out;
  }

  Color _dotColor(UnifiedScheduleSource s) {
    switch (s) {
      case UnifiedScheduleSource.appointment:
        return AppColors.statBlue;
      case UnifiedScheduleSource.meal:
        return AppColors.freePlan;
      case UnifiedScheduleSource.medicineLog:
        return AppColors.seed;
      case UnifiedScheduleSource.userReminder:
        return AppColors.premium;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final first = DateTime(monthStart.year, monthStart.month, 1);
    final daysInMonth = DateTime(monthStart.year, monthStart.month + 1, 0).day;
    final leading = first.weekday - 1;
    final totalCells = ((leading + daysInMonth + 6) ~/ 7) * 7;

    return Column(
      children: [
        Row(
          children: [
            for (final w in _weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.05,
          ),
          itemCount: totalCells,
          itemBuilder: (context, i) {
            if (i < leading || i >= leading + daysInMonth) {
              return const SizedBox.shrink();
            }
            final dayNum = i - leading + 1;
            final day = DateTime(monthStart.year, monthStart.month, dayNum);
            final isSelected =
                day.year == selectedDay.year &&
                day.month == selectedDay.month &&
                day.day == selectedDay.day;
            final isToday = () {
              final n = DateTime.now();
              return day.year == n.year &&
                  day.month == n.month &&
                  day.day == n.day;
            }();

            final sources = _sourcesOnDay(day);
            return Material(
              color: isSelected
                  ? scheme.primaryContainer.withValues(alpha: 0.55)
                  : scheme.surfaceContainerHighest.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                onTap: () => onSelectDay(day),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$dayNum',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? scheme.primary : scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (sources.isNotEmpty)
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 2,
                        children: [
                          for (final s in sources.take(4))
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: _dotColor(s),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ScheduleItemTile extends StatelessWidget {
  const _ScheduleItemTile({required this.item, required this.onTap});

  final UnifiedScheduleItem item;
  final VoidCallback onTap;

  IconData _icon() {
    switch (item.source) {
      case UnifiedScheduleSource.appointment:
        return Icons.event_rounded;
      case UnifiedScheduleSource.meal:
        return Icons.restaurant_rounded;
      case UnifiedScheduleSource.medicineLog:
        return Icons.medication_rounded;
      case UnifiedScheduleSource.userReminder:
        return Icons.notifications_active_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final timeStr = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(item.at));

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer.withValues(alpha: 0.5),
          foregroundColor: scheme.primary,
          child: Icon(_icon(), size: 22),
        ),
        title: Text(item.title),
        subtitle: Text(
          '${item.subtitle} · $timeStr',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: item.source == UnifiedScheduleSource.userReminder
            ? Icon(Icons.delete_outline_rounded, color: scheme.outline)
            : const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
