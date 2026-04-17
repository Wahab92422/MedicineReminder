import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Tappable row that opens a date picker and shows formatted value.
class DatePickerField extends StatelessWidget {
  const DatePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
    this.includeTime = false,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool includeTime;

  String _format(BuildContext context) {
    if (value == null) return 'Select date';
    final l10n = MaterialLocalizations.of(context);
    final date = l10n.formatMediumDate(value!);
    if (!includeTime) return date;
    final time = l10n.formatTimeOfDay(TimeOfDay.fromDateTime(value!));
    return '$date $time';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final d = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: firstDate ?? DateTime(1990),
          lastDate: lastDate ?? DateTime(now.year + 5),
        );
        if (!context.mounted) return;
        if (d == null) return;
        if (!includeTime) {
          onDateSelected(d);
          return;
        }

        final initial = value ?? now;
        final t = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(initial),
        );
        if (!context.mounted) return;
        if (t == null) return;

        onDateSelected(DateTime(d.year, d.month, d.day, t.hour, t.minute));
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
        ).applyDefaults(Theme.of(context).inputDecorationTheme),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(
            _format(context),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
