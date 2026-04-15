import 'package:flutter/material.dart';

import '../features/surgical_history/surgical_history_model.dart';
import '../theme/app_spacing.dart';

String _formatDate(DateTime d) {
  final l = d.toLocal();
  final mo = l.month.toString().padLeft(2, '0');
  final day = l.day.toString().padLeft(2, '0');
  return '${l.year}-$mo-$day';
}

class SurgicalHistoryCard extends StatelessWidget {
  const SurgicalHistoryCard({
    super.key,
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  final SurgicalHistoryRecord record;
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
                color: scheme.tertiary,
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
                        Icon(Icons.medical_services_outlined, color: scheme.tertiary, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            record.procedureName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Procedure date: ${_formatDate(record.procedureDate)}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (record.surgeonName.isNotEmpty)
                      Text(
                        'Surgeon: ${record.surgeonName}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (record.facilityName.isNotEmpty)
                      Text(
                        'Facility: ${record.facilityName}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (record.bodySite.isNotEmpty)
                      Text(
                        'Site: ${record.bodySite}',
                        style: Theme.of(context).textTheme.bodySmall,
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
