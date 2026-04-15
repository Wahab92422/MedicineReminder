import 'package:flutter/material.dart';

import '../features/medical_history/medical_history_model.dart';
import '../features/vitals/vital_recorded_at_format.dart';
import '../theme/app_spacing.dart';

String _formatDateOpt(DateTime? d) {
  if (d == null) return '—';
  final l = d.toLocal();
  final mo = l.month.toString().padLeft(2, '0');
  final day = l.day.toString().padLeft(2, '0');
  return '${l.year}-$mo-$day';
}

class MedicalHistoryCard extends StatelessWidget {
  const MedicalHistoryCard({
    super.key,
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  final MedicalHistoryRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color _statusColor(MedicalConditionStatus s, ColorScheme scheme) => switch (s) {
        MedicalConditionStatus.active => scheme.error,
        MedicalConditionStatus.resolved => scheme.tertiary,
        MedicalConditionStatus.remission => scheme.primary,
        MedicalConditionStatus.unknown => scheme.onSurfaceVariant,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sc = _statusColor(record.status, scheme);

    return Material(
      color: scheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: sc,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppSpacing.radiusXl - 1),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            record.conditionName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: sc.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: Text(
                            record.status.label,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: sc,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Onset: ${_formatDateOpt(record.onsetDate)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    if (record.notes.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Text(
                          record.notes.trim(),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Updated ${formatVitalRecordedAt(record.updatedAt)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit_rounded, size: 20),
                            label: const Text('Update'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onDelete,
                            icon: Icon(Icons.delete_outline_rounded, color: scheme.error, size: 20),
                            label: Text('Delete', style: TextStyle(color: scheme.error)),
                            style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
