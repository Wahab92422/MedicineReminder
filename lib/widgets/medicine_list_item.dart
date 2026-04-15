import 'package:flutter/material.dart';

import '../features/medicines/medicine_model.dart';
import '../features/medicines/medicine_reminder_time.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class MedicineListItem extends StatelessWidget {
  const MedicineListItem({
    super.key,
    required this.medicine,
    required this.onEdit,
    this.onMarkTaken,
  });

  final Medicine medicine;
  final VoidCallback onEdit;
  final VoidCallback? onMarkTaken;

  static const _gradientStops = [
    Color(0xFF0D9488),
    Color(0xFF0F766E),
    Color(0xFF115E59),
  ];

  @override
  Widget build(BuildContext context) {
    final timeLabel = MedicineReminderTime.formatClockHm(medicine.time);
    const radius = AppSpacing.radiusXl;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: const LinearGradient(
            colors: _gradientStops,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F766E).withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onEdit,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: const Icon(
                        Icons.medication_liquid_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medicine.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            medicine.dose.isEmpty ? 'Dose not set' : medicine.dose,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.92),
                                ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 18,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                timeLabel,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                              ),
                            ],
                          ),
                          if (medicine.isMissed ||
                              medicine.isLowStock ||
                              medicine.isOutOfStock) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.xs,
                              children: [
                                if (medicine.isMissed)
                                  _ChipPill(
                                    label: 'MISSED DOSE',
                                    foreground: Colors.white,
                                    background: AppColors.missed.withValues(alpha: 0.35),
                                  ),
                                if (medicine.isOutOfStock)
                                  const _ChipPill(
                                    label: 'OUT OF STOCK',
                                    foreground: Colors.white,
                                    background: Color(0x66FFFFFF),
                                  )
                                else if (medicine.isLowStock)
                                  _ChipPill(
                                    label: 'LOW STOCK',
                                    foreground: Colors.white,
                                    background: AppColors.freePlan.withValues(alpha: 0.45),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (onMarkTaken != null)
                      IconButton(
                        onPressed: onMarkTaken,
                        tooltip: 'Mark as taken',
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.18),
                        ),
                        icon: const Icon(Icons.check_circle_outline_rounded),
                      ),
                    IconButton(
                      onPressed: onEdit,
                      tooltip: 'Edit',
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                      ),
                      icon: const Icon(Icons.edit_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipPill extends StatelessWidget {
  const _ChipPill({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
      ),
    );
  }
}
