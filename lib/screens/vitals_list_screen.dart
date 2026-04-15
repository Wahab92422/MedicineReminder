import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/vitals/vital_entry_model.dart';
import '../features/vitals/vital_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/empty_state.dart';
import 'add_vital_screen.dart';

class VitalsListScreen extends ConsumerWidget {
  const VitalsListScreen({super.key});

  static String _formatWhen(DateTime dt) {
    final l = dt.toLocal();
    final mo = l.month.toString().padLeft(2, '0');
    final day = l.day.toString().padLeft(2, '0');
    final h = l.hour.toString().padLeft(2, '0');
    final m = l.minute.toString().padLeft(2, '0');
    return '${l.year}-$mo-$day  $h:$m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(vitalStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vitals'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(builder: (_) => const AddVitalScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add vitals'),
      ),
      body: async.when(
        data: (vitals) {
          if (vitals.isEmpty) {
            return EmptyState(
              icon: Icons.monitor_heart_outlined,
              title: 'No vitals yet',
              subtitle: 'Record blood pressure, heart rate, weight, and more.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              88,
            ),
            itemCount: vitals.length,
            itemBuilder: (context, index) {
              return _VitalHistoryCard(entry: vitals[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Could not load vitals',
          subtitle: e.toString(),
        ),
      ),
    );
  }
}

class _VitalHistoryCard extends ConsumerWidget {
  const _VitalHistoryCard({required this.entry});

  final VitalEntry entry;

  static List<_VitalMetric> _metrics(VitalEntry e) {
    final list = <_VitalMetric>[];
    final bp = e.bloodPressureLabel;
    if (bp != null) {
      list.add(_VitalMetric(
        icon: Icons.monitor_heart_outlined,
        label: 'Blood pressure',
        value: bp,
        tint: AppColors.statRed,
      ));
    }
    if (e.heartRate != null) {
      list.add(_VitalMetric(
        icon: Icons.favorite_rounded,
        label: 'Heart rate',
        value: '${e.heartRate} bpm',
        tint: AppColors.missed,
      ));
    }
    if (e.temperatureC != null) {
      list.add(_VitalMetric(
        icon: Icons.thermostat_rounded,
        label: 'Temperature',
        value: '${e.temperatureC!.toStringAsFixed(1)} °C',
        tint: AppColors.statBlue,
      ));
    }
    if (e.respiratoryRate != null) {
      list.add(_VitalMetric(
        icon: Icons.air_rounded,
        label: 'Resp. rate',
        value: '${e.respiratoryRate} /min',
        tint: AppColors.statBlue,
      ));
    }
    if (e.oxygenSaturation != null) {
      list.add(_VitalMetric(
        icon: Icons.bubble_chart_outlined,
        label: 'SpO₂',
        value: '${e.oxygenSaturation}%',
        tint: AppColors.statGreen,
      ));
    }
    if (e.heightCm != null) {
      list.add(_VitalMetric(
        icon: Icons.height_rounded,
        label: 'Height',
        value: '${e.heightCm!.toStringAsFixed(1)} cm',
        tint: AppColors.seed,
      ));
    }
    if (e.weightKg != null) {
      list.add(_VitalMetric(
        icon: Icons.monitor_weight_outlined,
        label: 'Weight',
        value: '${e.weightKg!.toStringAsFixed(1)} kg',
        tint: AppColors.seed,
      ));
    }
    if (e.bmi != null) {
      list.add(_VitalMetric(
        icon: Icons.straighten_rounded,
        label: 'BMI',
        value: e.bmi!.toStringAsFixed(1),
        tint: AppColors.premium,
      ));
    }
    if (e.bloodGlucose != null) {
      list.add(_VitalMetric(
        icon: Icons.water_drop_outlined,
        label: 'Glucose',
        value: '${e.bloodGlucose!.toStringAsFixed(0)} mg/dL',
        tint: AppColors.freePlan,
      ));
    }
    return list;
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this record?'),
        content: const Text(
          'This vital entry will be removed permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return r ?? false;
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    if (!await _confirmDelete(context) || !context.mounted) return;
    try {
      await ref.read(vitalControllerProvider).deleteVital(entry.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete: $e')),
        );
      }
    }
  }

  void _view(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _VitalDetailSheet(
        entry: entry,
        formatWhen: VitalsListScreen._formatWhen,
        metrics: _metrics(entry),
      ),
    );
  }

  void _edit(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AddVitalScreen(existing: entry),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final metrics = _metrics(entry);

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        if (!context.mounted) return false;
        return _confirmDelete(context);
      },
      onDismissed: (_) async {
        try {
          await ref.read(vitalControllerProvider).deleteVital(entry.id);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not delete: $e')),
            );
          }
        }
      },
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
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Material(
          elevation: 0,
          color: scheme.surface,
          shadowColor: scheme.shadow.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scheme.primary,
                      scheme.primary.withValues(alpha: 0.82),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: const Icon(
                          Icons.monitor_heart_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vitals record',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              VitalsListScreen._formatWhen(entry.recordedAt),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      _VitalCardIconAction(
                        icon: Icons.visibility_rounded,
                        tooltip: 'View',
                        onPressed: () => _view(context),
                      ),
                      _VitalCardIconAction(
                        icon: Icons.edit_rounded,
                        tooltip: 'Edit',
                        onPressed: () => _edit(context),
                      ),
                      _VitalCardIconAction(
                        icon: Icons.delete_outline_rounded,
                        tooltip: 'Delete',
                        onPressed: () => _delete(context, ref),
                      ),
                    ],
                  ),
                ),
              ),
              if (metrics.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: metrics
                        .map((m) => _VitalMetricPill(metric: m))
                        .toList(),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Text(
                    'No measurements — open view or edit to add details.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
              if (entry.notes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest
                          .withValues(alpha: 0.35),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.notes_rounded,
                          size: 20,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            entry.notes,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  0,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => _view(context),
                        icon: const Icon(Icons.visibility_outlined, size: 20),
                        label: const Text('View'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _edit(context),
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        label: const Text('Edit'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VitalCardIconAction extends StatelessWidget {
  const _VitalCardIconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white.withValues(alpha: 0.18),
        visualDensity: VisualDensity.compact,
      ),
      icon: Icon(icon, size: 20),
    );
  }
}

class _VitalMetric {
  const _VitalMetric({
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

class _VitalMetricPill extends StatelessWidget {
  const _VitalMetricPill({required this.metric});

  final _VitalMetric metric;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: metric.tint.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: metric.tint.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          children: [
            Icon(metric.icon, size: 22, color: metric.tint),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    metric.value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VitalDetailSheet extends StatelessWidget {
  const _VitalDetailSheet({
    required this.entry,
    required this.formatWhen,
    required this.metrics,
  });

  final VitalEntry entry;
  final String Function(DateTime) formatWhen;
  final List<_VitalMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            bottom + AppSpacing.lg,
          ),
          children: [
            Text(
              'Vitals detail',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              formatWhen(entry.recordedAt),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (metrics.isEmpty)
              Text(
                'No numeric vitals on this entry.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              )
            else
              ...metrics.map(
                (m) => ListTile(
                  contentPadding: EdgeInsets.zero,
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
            if (entry.notes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Notes',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                entry.notes,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.4,
                    ),
              ),
            ],
          ],
        );
      },
    );
  }
}
