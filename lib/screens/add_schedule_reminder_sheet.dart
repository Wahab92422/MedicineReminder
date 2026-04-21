import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/schedule/schedule_providers.dart';
import '../features/schedule/schedule_reminder_kind.dart';
import '../features/schedule/schedule_reminder_sheet_result.dart';
import '../features/schedule/user_schedule_reminder.dart';
import '../theme/app_spacing.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

/// Bottom sheet: general reminders save here; meal / medicine / appointment
/// continue to the module screen with prefilled data and status locked to Scheduled.
class AddScheduleReminderSheet extends ConsumerStatefulWidget {
  const AddScheduleReminderSheet({super.key});

  @override
  ConsumerState<AddScheduleReminderSheet> createState() =>
      _AddScheduleReminderSheetState();
}

class _AddScheduleReminderSheetState
    extends ConsumerState<AddScheduleReminderSheet> {
  final _notesController = TextEditingController();
  ScheduleReminderKind _kind = ScheduleReminderKind.general;
  DateTime _scheduledAt = DateTime.now().add(const Duration(hours: 1));
  bool _saving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(DateTime.now().year + 3),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (time == null || !mounted) return;

    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  (String title, String notes) _titleAndNotesForStorage() {
    final raw = _notesController.text.trim();
    if (raw.isEmpty) return ('Reminder', '');
    final lines = raw.split('\n');
    final first = lines.first.trim();
    final rest = lines.skip(1).join('\n').trim();
    return (first.isEmpty ? 'Reminder' : first, rest);
  }

  Future<void> _continue() async {
    switch (_kind) {
      case ScheduleReminderKind.general:
        await _saveGeneralReminder();
        return;
      case ScheduleReminderKind.meal:
        Navigator.of(context).pop(
          ScheduleReminderOpenMeal(
            mealAt: _scheduledAt,
            prefilledNotes: _notesController.text.trim(),
          ),
        );
        return;
      case ScheduleReminderKind.appointment:
        Navigator.of(context).pop(
          ScheduleReminderOpenAppointment(
            scheduledAt: _scheduledAt,
            prefilledNotes: _notesController.text.trim(),
          ),
        );
        return;
      case ScheduleReminderKind.medicine:
        Navigator.of(context).pop(
          ScheduleReminderOpenMedicineLog(
            loggedAt: _scheduledAt,
            prefilledNotes: _notesController.text.trim(),
          ),
        );
        return;
    }
  }

  Future<void> _saveGeneralReminder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final (title, notes) = _titleAndNotesForStorage();
      final repo = ref.read(userScheduleReminderRepositoryProvider);
      final id = repo.allocateId(user.uid);
      final now = DateTime.now();
      final reminder = UserScheduleReminder(
        id: id,
        userId: user.uid,
        title: title,
        notes: notes,
        scheduledAt: _scheduledAt,
        kind: _kind,
        createdAt: now,
        updatedAt: now,
      );
      await repo.createReminder(userId: user.uid, reminder: reminder);
      if (mounted) {
        Navigator.of(context).pop(ScheduleReminderGeneralSaved());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save reminder: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _primaryLabel() {
    if (_kind == ScheduleReminderKind.general) return 'Save reminder';
    return 'Continue';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final localizations = MaterialLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.sm,
        bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'New reminder',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _kind == ScheduleReminderKind.general
                  ? 'Describe what to remember. The first line is used as the reminder title; extra lines are saved as details.'
                  : 'Add optional notes, pick a time, then continue. The right screen opens with status Scheduled.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<ScheduleReminderKind>(
              // ignore: deprecated_member_use
              value: _kind,
              decoration: const InputDecoration(labelText: 'Type'),
              items: ScheduleReminderKind.values
                  .map(
                    (k) => DropdownMenuItem(
                      value: k,
                      child: Text(k.label),
                    ),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (v) {
                      if (v != null) setState(() => _kind = v);
                    },
            ),
            const SizedBox(height: AppSpacing.md),
            CustomTextField(
              controller: _notesController,
              label: 'Notes',
              hint: _kind == ScheduleReminderKind.general
                  ? 'First line = title, more lines = details (optional)'
                  : 'Optional — carried into the next screen',
              maxLines: 4,
            ),
            const SizedBox(height: AppSpacing.md),
            Material(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                onTap: _saving ? null : _pickDateTime,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(Icons.schedule_rounded, color: scheme.primary),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'When',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${localizations.formatMediumDate(_scheduledAt)} · '
                              '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(_scheduledAt))}',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: scheme.outline),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: _primaryLabel(),
              isLoading: _saving,
              onPressed: _saving ? null : _continue,
            ),
          ],
        ),
      ),
    );
  }
}
