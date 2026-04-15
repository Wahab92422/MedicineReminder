import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/vitals/vital_entry_model.dart';
import '../features/vitals/vital_providers.dart';
import '../features/vitals/vital_recorded_at_format.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/empty_state.dart';
import 'add_vital_screen.dart';
import 'vital_detail_screen.dart';

class VitalsListScreen extends ConsumerWidget {
  const VitalsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(vitalStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Vitals')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddVitalScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add vitals'),
      ),
      body: async.when(
        data: (vitals) {
          if (vitals.isEmpty) {
            return const EmptyState(
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

  // ---------------- METRICS ----------------

  static List<_VitalMetric> _metrics(VitalEntry e) {
    final list = <_VitalMetric>[];

    final bp = e.bloodPressureLabel;
    if (bp != null) {
      list.add(
        _VitalMetric(
          icon: Icons.monitor_heart_outlined,
          label: 'Blood pressure',
          value: bp,
          tint: AppColors.statRed,
        ),
      );
    }

    if (e.heartRate != null) {
      list.add(
        _VitalMetric(
          icon: Icons.favorite_rounded,
          label: 'Heart rate',
          value: '${e.heartRate} bpm',
          tint: AppColors.missed,
        ),
      );
    }

    if (e.temperatureC != null) {
      list.add(
        _VitalMetric(
          icon: Icons.thermostat_rounded,
          label: 'Temperature',
          value: '${e.temperatureC!.toStringAsFixed(1)} °C',
          tint: AppColors.statBlue,
        ),
      );
    }

    if (e.respiratoryRate != null) {
      list.add(
        _VitalMetric(
          icon: Icons.air_rounded,
          label: 'Resp. rate',
          value: '${e.respiratoryRate} /min',
          tint: AppColors.statBlue,
        ),
      );
    }

    if (e.oxygenSaturation != null) {
      list.add(
        _VitalMetric(
          icon: Icons.bubble_chart_outlined,
          label: 'SpO₂',
          value: '${e.oxygenSaturation}%',
          tint: AppColors.statGreen,
        ),
      );
    }

    if (e.bloodGlucose != null) {
      list.add(
        _VitalMetric(
          icon: Icons.water_drop_outlined,
          label: 'Glucose',
          value: '${e.bloodGlucose!.toStringAsFixed(0)} mg/dL',
          tint: AppColors.freePlan,
        ),
      );
    }

    return list;
  }

  // ---------------- UI ACTIONS (unchanged) ----------------

  Future<bool> _confirmDelete(BuildContext context) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this record?'),
        content: const Text('This vital entry will be removed permanently.'),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not delete: $e')));
      }
    }
  }

  void _view(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VitalDetailScreen(entry: entry)),
    );
  }

  void _edit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddVitalScreen(existing: entry)),
    );
  }

  Widget _actionsRow(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
    );
  }

  // ---------------- BUILD ----------------

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final metrics = _metrics(entry);

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => _confirmDelete(context),
      onDismissed: (_) async {
        try {
          await ref.read(vitalControllerProvider).deleteVital(entry.id);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Could not delete: $e')));
          }
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: scheme.error,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Icon(Icons.delete_outline_rounded, color: scheme.onError),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Material(
          color: scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---------------- HEADER ----------------
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scheme.primary,
                      scheme.primary.withValues(alpha: 0.82),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.monitor_heart_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),

                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Vitals record',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatVitalRecordedAt(entry.recordedAt),
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: AppSpacing.xs),
                      _actionsRow(context, ref),
                    ],
                  ),
                ),
              ),

              // ---------------- METRICS (FIXED GRID) ----------------
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  right: AppSpacing.sm,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 420;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: metrics.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWide ? 3 : 2,
                        mainAxisSpacing: AppSpacing.sm,
                        crossAxisSpacing: AppSpacing.sm,
                        mainAxisExtent: 64,
                      ),
                      itemBuilder: (context, index) {
                        return _VitalMetricTile(metric: metrics[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- ICON ACTION ----------------

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
        minimumSize: const Size(36, 36),
        padding: EdgeInsets.zero,
      ),
      icon: Icon(icon, size: 18),
    );
  }
}

// ---------------- MODEL ----------------

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

// ---------------- TILE (NEW PRODUCTION UI) ----------------

class _VitalMetricTile extends StatelessWidget {
  const _VitalMetricTile({required this.metric});

  final _VitalMetric metric;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: metric.tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: metric.tint.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: metric.tint.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(metric.icon, size: 18, color: metric.tint),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
