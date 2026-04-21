import 'package:flutter/material.dart';

import '../features/vitals/vital_entry.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class VitalEntryCard extends StatelessWidget {
  const VitalEntryCard({
    super.key,
    required this.entry,
    required this.onTap,
    this.onDelete,
    this.isDeleting = false,
  });

  final VitalEntry entry;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = MaterialLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0,
      color: Colors.transparent,
      child: InkWell(
        onTap: isDeleting ? null : onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          decoration: BoxDecoration(
            color: Color.lerp(scheme.surface, scheme.primary, 0.02),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.formatMediumDate(entry.recordedAt),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            loc.formatTimeOfDay(
                              TimeOfDay.fromDateTime(entry.recordedAt),
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onDelete != null)
                      _DeleteButton(
                        isDeleting: isDeleting,
                        color: scheme.error,
                        onPressed: isDeleting ? null : onDelete,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _buildInfoChips(),
                ),
                if (entry.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.30,
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Text(
                      entry.notes.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildInfoChips() {
    final chips = <Widget>[];

    if (entry.systolicMmHg != null || entry.diastolicMmHg != null) {
      chips.add(
        _InfoChip(
          icon: Icons.favorite_border_rounded,
          label:
              'BP ${entry.systolicMmHg ?? '—'}/${entry.diastolicMmHg ?? '—'}',
          color: AppColors.statRed,
        ),
      );
    }
    if (entry.heartRateBpm != null) {
      chips.add(
        _InfoChip(
          icon: Icons.monitor_heart_outlined,
          label: 'HR ${entry.heartRateBpm} bpm',
          color: AppColors.seed,
        ),
      );
    }
    if (entry.glucoseMgDl != null) {
      chips.add(
        _InfoChip(
          icon: Icons.science_outlined,
          label: 'Glucose ${_formatNumber(entry.glucoseMgDl!)} mg/dL',
          color: AppColors.statBlue,
        ),
      );
    }
    if (entry.spo2Percent != null) {
      chips.add(
        _InfoChip(
          icon: Icons.air_rounded,
          label: 'SpO₂ ${entry.spo2Percent}%',
          color: AppColors.premium,
        ),
      );
    }
    if (entry.temperatureCelsius != null) {
      chips.add(
        _InfoChip(
          icon: Icons.thermostat_outlined,
          label: '${entry.temperatureCelsius!.toStringAsFixed(1)}°C',
          color: AppColors.freePlan,
        ),
      );
    }
    if (entry.weightKg != null) {
      chips.add(
        _InfoChip(
          icon: Icons.monitor_weight_outlined,
          label: '${_formatNumber(entry.weightKg!)} kg',
          color: AppColors.seed,
        ),
      );
    }
    if (entry.heightCm != null) {
      chips.add(
        _InfoChip(
          icon: Icons.height_rounded,
          label: '${_formatNumber(entry.heightCm!)} cm',
          color: AppColors.statBlue,
        ),
      );
    }

    if (chips.isEmpty) {
      chips.add(
        const _InfoChip(
          icon: Icons.notes_rounded,
          label: 'Notes only',
          color: Colors.grey,
        ),
      );
    }

    return chips;
  }

  String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({
    required this.isDeleting,
    required this.color,
    required this.onPressed,
  });

  final bool isDeleting;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      width: 36,
      child: IconButton(
        tooltip: 'Delete',
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: isDeleting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.delete_outline_rounded, color: color, size: 20),
      ),
    );
  }
}
