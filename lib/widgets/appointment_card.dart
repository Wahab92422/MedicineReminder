import 'package:flutter/material.dart';

import '../features/appointments/appointment_model.dart';
import '../features/vitals/vital_recorded_at_format.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.record,
    required this.onEdit,
    required this.onDelete,
    required this.onMarkAttended,
    required this.onMarkMissed,
  });

  final AppointmentRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMarkAttended;
  final VoidCallback onMarkMissed;

  Color _statusColor(AppointmentStatus s, ColorScheme scheme) => switch (s) {
        AppointmentStatus.scheduled => scheme.primary,
        AppointmentStatus.attended => AppColors.statGreen,
        AppointmentStatus.missed => AppColors.statRed,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sc = _statusColor(record.status, scheme);
    final canMark = record.status == AppointmentStatus.scheduled;

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
                            record.title.isNotEmpty ? record.title : 'Appointment',
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
                    _InfoRow(
                      icon: Icons.schedule_rounded,
                      text: formatVitalRecordedAt(record.scheduledAt),
                    ),
                    if (record.doctorName.isNotEmpty)
                      _InfoRow(
                        icon: Icons.person_outline_rounded,
                        text: record.doctorName,
                      ),
                    if (record.location.isNotEmpty)
                      _InfoRow(
                        icon: Icons.place_outlined,
                        text: record.location,
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
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35),
                        ),
                      ),
                    ],
                    if (canMark) ...[
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: onMarkAttended,
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                              label: const Text('Attended'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.statGreen,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: onMarkMissed,
                              icon: const Icon(Icons.event_busy_rounded, size: 20),
                              label: const Text('Missed'),
                              style: FilledButton.styleFrom(
                                backgroundColor: scheme.errorContainer,
                                foregroundColor: scheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit_rounded, size: 20),
                            label: const Text('Edit'),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    height: 1.25,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
