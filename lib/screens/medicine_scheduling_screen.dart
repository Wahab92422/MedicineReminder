import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/medicines/medicine_controller.dart';
import '../features/medicines/medicine_reminder_time.dart';
import '../theme/app_spacing.dart';
import '../widgets/empty_state.dart';
import 'edit_medicine_screen.dart';

/// Lists all medicines with their reminder schedule (daily clock time).
class MedicineSchedulingScreen extends ConsumerWidget {
  const MedicineSchedulingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(medicineStreamProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheduling'),
      ),
      body: async.when(
        data: (medicines) {
          if (medicines.isEmpty) {
            return const EmptyState(
              icon: Icons.calendar_month_rounded,
              title: 'No schedules yet',
              subtitle:
                  'Add medicines from the Medicines tab to see reminder times here.',
            );
          }
          final sorted = [...medicines]..sort((a, b) {
              final ta = MedicineReminderTime.decodeToLocal(a.time);
              final tb = MedicineReminderTime.decodeToLocal(b.time);
              if (ta == null && tb == null) return a.name.compareTo(b.name);
              if (ta == null) return 1;
              if (tb == null) return -1;
              final ca = a.time.contains('T')
                  ? ta
                  : DateTime(2000, 1, 1, ta.hour, ta.minute);
              final cb = b.time.contains('T')
                  ? tb
                  : DateTime(2000, 1, 1, tb.hour, tb.minute);
              final c = ca.compareTo(cb);
              if (c != 0) return c;
              return a.name.compareTo(b.name);
            });

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final med = sorted[index];
              final clock = MedicineReminderTime.formatClockHm(med.time);
              final fullWhen = med.time.contains('T')
                  ? MedicineReminderTime.formatDateAndTime(
                      MedicineReminderTime.decodeToLocal(med.time)!,
                    )
                  : null;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Material(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    side: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => EditMedicineScreen(
                            id: med.id,
                            name: med.name,
                            dose: med.dose,
                            time: med.time,
                            quantityOnHand: med.quantityOnHand,
                            lowStockThreshold: med.lowStockThreshold,
                            inventoryUnit: med.inventoryUnit,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: Icon(
                              Icons.schedule_rounded,
                              color: scheme.onPrimaryContainer,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  med.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                if (med.dose.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    med.dose,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.sm),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.xs,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.alarm_rounded,
                                      size: 18,
                                      color: scheme.primary,
                                    ),
                                    Text(
                                      clock,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: scheme.primary,
                                            fontFeatures: const [
                                              FontFeature.tabularFigures(),
                                            ],
                                          ),
                                    ),
                                    if (med.repeatDaily)
                                      Chip(
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        label: const Text('Daily'),
                                        labelStyle: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                  ],
                                ),
                                if (fullWhen != null) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    fullWhen,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: scheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Could not load schedules',
          subtitle: e.toString(),
        ),
      ),
    );
  }
}
