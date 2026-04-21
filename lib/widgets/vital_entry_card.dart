import 'package:flutter/material.dart';

import '../features/vitals/vital_entry.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// How many readings to show on the list card; the rest open on the detail screen.
const int _kVitalsCardPreviewMetricCount = 2;

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

    final hasNotes = entry.notes.trim().isNotEmpty;
    var metrics = _buildMetricTiles(entry);
    if (_isPlaceholderNotesOnly(metrics) && hasNotes) {
      metrics = <_MetricSpec>[];
    }
    final previewMetrics = metrics.take(_kVitalsCardPreviewMetricCount).toList();
    final extraMetrics = metrics.length > _kVitalsCardPreviewMetricCount
        ? metrics.skip(_kVitalsCardPreviewMetricCount).toList()
        : const <_MetricSpec>[];
    final recordedLine =
        '${loc.formatMediumDate(entry.recordedAt)} • ${loc.formatTimeOfDay(TimeOfDay.fromDateTime(entry.recordedAt))}';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      elevation: 0,
      color: Colors.transparent,
      child: InkWell(
        onTap: isDeleting ? null : onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          decoration: BoxDecoration(
            color: Color.lerp(scheme.surface, scheme.primary, 0.02),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 28,
                      width: 28,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withValues(
                          alpha: 0.45,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: scheme.primary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        recordedLine,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ),
                    if (onDelete != null)
                      PopupMenuButton<_EntryAction>(
                        tooltip: 'More',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        enabled: !isDeleting,
                        onSelected: (action) {
                          switch (action) {
                            case _EntryAction.edit:
                              onTap();
                            case _EntryAction.delete:
                              onDelete?.call();
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem<_EntryAction>(
                            value: _EntryAction.edit,
                            child: Text('Edit'),
                          ),
                          PopupMenuItem<_EntryAction>(
                            value: _EntryAction.delete,
                            child: Text('Delete'),
                          ),
                        ],
                        child: isDeleting
                            ? const SizedBox(
                                height: 32,
                                width: 32,
                                child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.more_horiz_rounded,
                                size: 22,
                                color: scheme.onSurfaceVariant,
                              ),
                      ),
                  ],
                ),
                if (previewMetrics.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.35,
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < previewMetrics.length; i++)
                          Padding(
                            padding: EdgeInsets.only(
                              top: i > 0 ? 6 : 0,
                            ),
                            child: _CompactMetricRow(metric: previewMetrics[i]),
                          ),
                        if (extraMetrics.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 5,
                            runSpacing: 5,
                            children: [
                              for (final m in extraMetrics)
                                Icon(
                                  m.icon,
                                  size: 15,
                                  color: m.color.withValues(alpha: 0.9),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (hasNotes) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(
                        Icons.notes_rounded,
                        size: 15,
                        color: scheme.primary.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Has notes',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_MetricSpec> _buildMetricTiles(VitalEntry entry) {
    final metrics = <_MetricSpec>[];

    if (entry.systolicMmHg != null || entry.diastolicMmHg != null) {
      metrics.add(
        _MetricSpec(
          label: 'BP',
          value:
              '${entry.systolicMmHg?.toStringAsFixed(0) ?? '—'}/${entry.diastolicMmHg?.toStringAsFixed(0) ?? '—'}',
          unit: 'mmHg',
          icon: Icons.favorite_border_rounded,
          color: AppColors.statRed,
        ),
      );
    }
    if (entry.heartRateBpm != null) {
      metrics.add(
        _MetricSpec(
          label: 'HR',
          value: entry.heartRateBpm?.toStringAsFixed(0) ?? '—',
          unit: 'bpm',
          icon: Icons.monitor_heart_outlined,
          color: AppColors.seed,
        ),
      );
    }
    if (entry.glucoseMgDl != null) {
      metrics.add(
        _MetricSpec(
          label: 'Glucose',
          value: _formatNumber(entry.glucoseMgDl!),
          unit: 'mg/dL',
          icon: Icons.science_outlined,
          color: AppColors.statBlue,
        ),
      );
    }
    if (entry.spo2Percent != null) {
      metrics.add(
        _MetricSpec(
          label: 'SpO₂',
          value: entry.spo2Percent?.toStringAsFixed(0) ?? '—',
          unit: '%',
          icon: Icons.air_rounded,
          color: AppColors.premium,
        ),
      );
    }
    if (entry.temperatureCelsius != null) {
      metrics.add(
        _MetricSpec(
          label: 'Temp',
          value: entry.temperatureCelsius!.toStringAsFixed(1),
          unit: '°C',
          icon: Icons.thermostat_outlined,
          color: AppColors.freePlan,
        ),
      );
    }
    if (entry.weightKg != null) {
      metrics.add(
        _MetricSpec(
          label: 'Weight',
          value: _formatNumber(entry.weightKg!),
          unit: 'kg',
          icon: Icons.monitor_weight_outlined,
          color: AppColors.seed,
        ),
      );
    }
    if (entry.heightCm != null) {
      metrics.add(
        _MetricSpec(
          label: 'Height',
          value: _formatNumber(entry.heightCm!),
          unit: 'cm',
          icon: Icons.height_rounded,
          color: AppColors.statBlue,
        ),
      );
    }

    if (metrics.isEmpty) {
      metrics.add(
        const _MetricSpec(
          label: 'Notes',
          value: '—',
          unit: '',
          icon: Icons.notes_rounded,
          color: Colors.grey,
        ),
      );
    }

    return metrics;
  }

  String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  bool _isPlaceholderNotesOnly(List<_MetricSpec> metrics) {
    return metrics.length == 1 &&
        metrics.first.label == 'Notes' &&
        metrics.first.value == '—';
  }
}

enum _EntryAction { edit, delete }

class _MetricSpec {
  const _MetricSpec({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
}

class _CompactMetricRow extends StatelessWidget {
  const _CompactMetricRow({required this.metric});

  final _MetricSpec metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final valueText = metric.unit.isEmpty
        ? metric.value
        : '${metric.value} ${metric.unit}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(metric.icon, size: 14, color: metric.color),
        const SizedBox(width: 6),
        Expanded(
          flex: 5,
          child: Text(
            metric.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 7,
          child: Text(
            valueText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodySmall?.copyWith(
              color: metric.color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
