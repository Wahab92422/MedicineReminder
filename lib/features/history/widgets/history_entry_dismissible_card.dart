import 'package:flutter/material.dart';

import '../../medicines/medicine_reminder_time.dart';
import '../history_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/common/labeled_icon_chip.dart';

class HistoryEntryDismissibleCard extends StatelessWidget {
  const HistoryEntryDismissibleCard({
    super.key,
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
                            LabeledIconChip(
                              icon: Icons.alarm_rounded,
                              label: 'Scheduled ${record.scheduledTime}',
                            ),
                            if (record.takenTime != null)
                              LabeledIconChip(
                                icon: Icons.event_available_rounded,
                                label:
                                    'Taken ${MedicineReminderTime.formatDateAndTime(record.takenTime!.toLocal())}',
                              ),
                            LabeledIconChip(
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
