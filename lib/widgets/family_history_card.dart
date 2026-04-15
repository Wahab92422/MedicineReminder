import 'package:flutter/material.dart';

import '../features/family_history/family_history_model.dart';
import '../features/vitals/vital_recorded_at_format.dart';
import '../theme/app_spacing.dart';
import 'family_relationship_selector.dart';

class FamilyHistoryCard extends StatelessWidget {
  const FamilyHistoryCard({
    super.key,
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  final FamilyHistoryRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
                color: scheme.secondary,
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
                      children: [
                        Icon(
                          FamilyRelationshipSelector.iconFor(record.relationship),
                          color: scheme.secondary,
                          size: 22,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            record.conditionName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      record.relationship.label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: scheme.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (record.ageAtOnset != null)
                      Text(
                        'Age at onset: ${record.ageAtOnset}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (record.deceased)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Chip(
                          visualDensity: VisualDensity.compact,
                          avatar: Icon(Icons.heart_broken_outlined, size: 16, color: scheme.onSurfaceVariant),
                          label: const Text('Deceased'),
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
