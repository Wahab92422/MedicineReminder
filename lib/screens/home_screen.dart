import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/medicines/medicine_controller.dart';
import '../features/medicines/medicine_model.dart';
import '../features/subscription/medicine_entitlement.dart';
import '../providers/subscription_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/empty_state.dart';
import '../widgets/medicine_list_item.dart';
import '../widgets/premium_status_banner.dart';
import 'edit_medicine_screen.dart';
import 'history_screen.dart';
import 'upgrade_plan_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    ref.listenManual<AsyncValue<List<Medicine>>>(
      medicineStreamProvider,
      (previous, next) {
        next.whenData((medicines) {
          final c = ref.read(medicineControllerProvider);
          unawaited(c.syncReminderSchedulesForMedicines(medicines));
          unawaited(c.checkMissedDoses(medicines));
        });
      },
      fireImmediately: true,
    );
  }

  void _openUpgrade() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const UpgradePlanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final medicinesAsync = ref.watch(medicineStreamProvider);
    final isPremiumAsync = ref.watch(subscriptionProvider);
    final subscriptionKnownPremium = isPremiumAsync.asData?.value == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        isPremiumAsync.when(
          data: (isPremium) => PremiumStatusBanner(
            isPremium: isPremium,
            onUpgradeTap: isPremium ? null : _openUpgrade,
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
                );
              },
              icon: const Icon(Icons.history_rounded, size: 20),
              label: const Text('Medication history'),
            ),
          ),
        ),
        Expanded(
          child: medicinesAsync.when(
            data: (medicines) {
              final atLimit = MedicineEntitlement.isAtFreeLimit(
                isPremium: isPremiumAsync.asData?.value ?? true,
                medicineCount: medicines.length,
              );

              if (medicines.isEmpty) {
                return EmptyState(
                  icon: Icons.medication_liquid_outlined,
                  title: 'No medicines yet',
                  subtitle: 'Tap Add to create your first reminder.',
                  actionLabel: subscriptionKnownPremium ? null : 'See Premium',
                  onAction: subscriptionKnownPremium ? null : _openUpgrade,
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                itemCount: (atLimit ? 1 : 0) + medicines.length,
                itemBuilder: (context, index) {
                  if (atLimit && index == 0) {
                    return _MedicineLimitBanner(onUpgrade: _openUpgrade);
                  }
                  final medIndex = atLimit ? index - 1 : index;
                  final med = medicines[medIndex];
                  return _DismissibleMedicineTile(
                    medicine: med,
                    onEdit: () {
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
                    onMarkTaken: () async {
                      await ref.read(medicineControllerProvider).markMedicineTaken(med);
                    },
                    onDismissed: () {
                      ref.read(medicineControllerProvider).deleteMedicine(med.id);
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Something went wrong',
              subtitle: e.toString(),
            ),
          ),
        ),
      ],
    );
  }
}

class _MedicineLimitBanner extends StatelessWidget {
  const _MedicineLimitBanner({required this.onUpgrade});

  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: AppColors.freePlanContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onUpgrade,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.lock_open_rounded, color: AppColors.freePlan, size: 32),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Free plan: ${MedicineEntitlement.freeMaxMedicines} medicines max',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Upgrade to Premium for unlimited medicines and reminders.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: onUpgrade,
                  child: const Text('Upgrade'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DismissibleMedicineTile extends StatelessWidget {
  const _DismissibleMedicineTile({
    required this.medicine,
    required this.onEdit,
    required this.onDismissed,
    this.onMarkTaken,
  });

  final Medicine medicine;
  final VoidCallback onEdit;
  final VoidCallback onDismissed;
  final Future<void> Function()? onMarkTaken;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(medicine.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: Theme.of(context).colorScheme.onError,
        ),
      ),
      onDismissed: (_) => onDismissed(),
      child: MedicineListItem(
        medicine: medicine,
        onEdit: onEdit,
        onMarkTaken: onMarkTaken == null ? null : () => onMarkTaken!(),
      ),
    );
  }
}
