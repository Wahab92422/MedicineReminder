import 'package:flutter/material.dart';

import '../features/clinical_notes/clinical_note_model.dart';
import '../features/vitals/vital_recorded_at_format.dart';
import '../theme/app_spacing.dart';
import 'clinical_note_category_selector.dart';

/// Clinical note summary for history lists (EHR-style card with edit/delete actions).
class ClinicalNoteCard extends StatelessWidget {
  const ClinicalNoteCard({
    super.key,
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  final ClinicalNote note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final catColor = scheme.primary;

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
                color: catColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppSpacing.radiusXl - 1),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        Icon(
                          ClinicalNoteCategorySelector.iconFor(note.category),
                          size: 18,
                          color: catColor,
                        ),
                        Chip(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          side: BorderSide(
                            color: catColor.withValues(alpha: 0.35),
                          ),
                          backgroundColor: catColor.withValues(alpha: 0.08),
                          label: Text(
                            note.category.label,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: catColor,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      note.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            letterSpacing: -0.2,
                          ),
                    ),
                    if (note.body.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.sm + 2),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Text(
                          note.body.trim(),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                height: 1.4,
                                color: scheme.onSurface,
                              ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _MetaPill(
                          icon: Icons.event_available_outlined,
                          label: 'Encounter',
                          value: formatVitalRecordedAt(note.encounterAt),
                        ),
                        _MetaPill(
                          icon: Icons.update_rounded,
                          label: 'Updated',
                          value: formatVitalRecordedAt(note.updatedAt),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit_note_rounded, size: 20),
                            label: const Text('Update'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onDelete,
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: scheme.error,
                              size: 20,
                            ),
                            label: Text(
                              'Delete',
                              style: TextStyle(color: scheme.error),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: scheme.error,
                            ),
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

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
