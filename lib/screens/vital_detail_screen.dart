import 'package:flutter/material.dart';

import '../features/vitals/vital_entry_model.dart';
import '../features/vitals/vital_recorded_at_format.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class _DetailMetric {
  const _DetailMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tint;
}

List<_DetailMetric> _detailMetrics(VitalEntry e) {
  final list = <_DetailMetric>[];
  final bp = e.bloodPressureLabel;
  if (bp != null) {
    list.add(_DetailMetric(
      icon: Icons.monitor_heart_outlined,
      label: 'Blood pressure',
      value: bp,
      tint: AppColors.statRed,
    ));
  }
  if (e.heartRate != null) {
    list.add(_DetailMetric(
      icon: Icons.favorite_rounded,
      label: 'Heart rate',
      value: '${e.heartRate} bpm',
      tint: AppColors.missed,
    ));
  }
  if (e.temperatureC != null) {
    list.add(_DetailMetric(
      icon: Icons.thermostat_rounded,
      label: 'Temperature',
      value: '${e.temperatureC!.toStringAsFixed(1)} °C',
      tint: AppColors.statBlue,
    ));
  }
  if (e.respiratoryRate != null) {
    list.add(_DetailMetric(
      icon: Icons.air_rounded,
      label: 'Respiratory rate',
      value: '${e.respiratoryRate} /min',
      tint: AppColors.statBlue,
    ));
  }
  if (e.oxygenSaturation != null) {
    list.add(_DetailMetric(
      icon: Icons.bubble_chart_outlined,
      label: 'SpO₂',
      value: '${e.oxygenSaturation}%',
      tint: AppColors.statGreen,
    ));
  }
  if (e.heightCm != null) {
    list.add(_DetailMetric(
      icon: Icons.height_rounded,
      label: 'Height',
      value: '${e.heightCm!.toStringAsFixed(1)} cm',
      tint: AppColors.seed,
    ));
  }
  if (e.weightKg != null) {
    list.add(_DetailMetric(
      icon: Icons.monitor_weight_outlined,
      label: 'Weight',
      value: '${e.weightKg!.toStringAsFixed(1)} kg',
      tint: AppColors.seed,
    ));
  }
  if (e.bmi != null) {
    list.add(_DetailMetric(
      icon: Icons.straighten_rounded,
      label: 'BMI',
      value: e.bmi!.toStringAsFixed(1),
      tint: AppColors.premium,
    ));
  }
  if (e.bloodGlucose != null) {
    list.add(_DetailMetric(
      icon: Icons.water_drop_outlined,
      label: 'Blood glucose',
      value: '${e.bloodGlucose!.toStringAsFixed(0)} mg/dL',
      tint: AppColors.freePlan,
    ));
  }
  return list;
}

/// Full-screen vitals record (read-only; actions live on list cards).
class VitalDetailScreen extends StatelessWidget {
  const VitalDetailScreen({super.key, required this.entry});

  final VitalEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final metrics = _detailMetrics(entry);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vitals detail'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            formatVitalRecordedAt(entry.recordedAt),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (metrics.isEmpty)
            Text(
              'No numeric vitals on this entry.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            )
          else
            ...metrics.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Material(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    side: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: m.tint.withValues(alpha: 0.15),
                      child: Icon(m.icon, color: m.tint, size: 22),
                    ),
                    title: Text(m.label),
                    subtitle: Text(
                      m.value,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          if (entry.notes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SelectableText(
              entry.notes,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.45,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
