import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Single date (no time) for EHR forms — optional with clear, or required.
class EhrDatePickerTile extends StatelessWidget {
  const EhrDatePickerTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.allowClear = false,
    this.firstDate,
    this.lastDate,
  });

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String title;
  final String? subtitle;
  final bool allowClear;
  final DateTime? firstDate;
  final DateTime? lastDate;

  String _format(DateTime d) {
    final l = d.toLocal();
    final mo = l.month.toString().padLeft(2, '0');
    final day = l.day.toString().padLeft(2, '0');
    return '${l.year}-$mo-$day';
  }

  Future<void> _pick(BuildContext context) async {
    final initial = value ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (d != null) {
      onChanged(DateTime(d.year, d.month, d.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final display = value != null ? _format(value!) : 'Not set';

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _pick(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined, color: scheme.primary, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      display,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
              if (allowClear && value != null)
                IconButton(
                  tooltip: 'Clear date',
                  onPressed: () => onChanged(null),
                  icon: const Icon(Icons.clear_rounded),
                )
              else
                Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
