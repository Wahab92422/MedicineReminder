import 'package:flutter/material.dart';

import '../features/medicines/medicine_reminder_time.dart';
import '../theme/app_spacing.dart';

/// Opens Material [showDatePicker] then [showTimePicker] and returns a local [DateTime].
Future<DateTime?> pickReminderDateTime(
  BuildContext context, {
  DateTime? initial,
}) async {
  final now = DateTime.now();
  final base = initial ?? now;

  final date = await showDatePicker(
    context: context,
    initialDate: DateTime(base.year, base.month, base.day),
    firstDate: DateTime(now.year - 1),
    lastDate: DateTime(now.year + 5),
  );
  if (date == null || !context.mounted) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
  );
  if (time == null || !context.mounted) return null;

  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

/// Two-step form: separate **date** and **time** pickers (clearer on iOS).
class ReminderDateTimeFormFields extends StatelessWidget {
  const ReminderDateTimeFormFields({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final base = value ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(base.year, base.month, base.day),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null || !context.mounted) return;
    onChanged(
      DateTime(picked.year, picked.month, picked.day, base.hour, base.minute),
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    final base = value ?? DateTime.now();
    final tod = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
    );
    if (tod == null || !context.mounted) return;
    onChanged(
      DateTime(base.year, base.month, base.day, tod.hour, tod.minute),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final timeStr = value == null
        ? 'Not set'
        : TimeOfDay(hour: value!.hour, minute: value!.minute).format(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: ListTile(
            leading: Icon(Icons.calendar_today_rounded, color: scheme.primary),
            title: const Text('Reminder date'),
            subtitle: Text(
              value == null ? 'Tap to choose' : MedicineReminderTime.formatDateOnly(value!),
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _pickDate(context),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: ListTile(
            leading: Icon(Icons.schedule_rounded, color: scheme.primary),
            title: const Text('Reminder time'),
            subtitle: Text(
              timeStr,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _pickTime(context),
          ),
        ),
        if (value != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Notifications repeat every day at $timeStr (local time). '
            'On iOS Simulator, allow alerts when prompted and send the app to the background to see the banner.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}

/// Single tile: opens date picker then time picker in one flow.
class ReminderDateTimePickerTile extends StatelessWidget {
  const ReminderDateTimePickerTile({
    super.key,
    required this.value,
    required this.onChanged,
    this.title = 'Reminder date & time',
  });

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        leading: Icon(Icons.event_available_rounded, color: scheme.primary),
        title: Text(
          value == null ? 'Choose date & time' : title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          value == null
              ? 'Pick when you should be reminded (repeats daily at this time)'
              : '${MedicineReminderTime.formatDateAndTime(value!)} · repeats daily',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () async {
          final picked = await pickReminderDateTime(context, initial: value);
          if (picked != null) onChanged(picked);
        },
      ),
    );
  }
}
