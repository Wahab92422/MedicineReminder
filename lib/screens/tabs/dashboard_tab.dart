import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/medicines/medicine_controller.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/dashboard_quick_actions.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_card.dart';
import '../upgrade_plan_screen.dart';

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicinesAsync = ref.watch(medicineStreamProvider);
    final isPremiumAsync = ref.watch(subscriptionProvider);

    return medicinesAsync.when(
      data: (medicines) {
        if (medicines.isEmpty) {
          return _DashboardWithUpgrade(
            isPremiumAsync: isPremiumAsync,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const DashboardQuickActions(),
                const SizedBox(height: AppSpacing.lg),
                const EmptyState(
                  icon: Icons.insights_outlined,
                  title: 'No overview data yet',
                  subtitle: 'Add medicines to see adherence and inventory stats here.',
                ),
              ],
            ),
          );
        }

        final total = medicines.length;
        final missed = medicines.where((m) => m.isMissed).length;
        final adherence = total == 0 ? 0.0 : (total - missed) / total * 100;
        final inventoryAlerts =
            medicines.where((m) => m.isLowStock || m.isOutOfStock).length;

        return _DashboardWithUpgrade(
          isPremiumAsync: isPremiumAsync,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const DashboardQuickActions(),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Overview'),
              StatCard(
                title: 'Total medicines',
                value: '$total',
                accentColor: AppColors.statBlue,
                icon: Icons.medication_liquid_rounded,
              ),
              StatCard(
                title: 'Missed doses',
                value: '$missed',
                accentColor: AppColors.statRed,
                icon: Icons.warning_amber_rounded,
              ),
              StatCard(
                title: 'Adherence',
                value: '${adherence.toStringAsFixed(1)}%',
                accentColor: AppColors.statGreen,
                icon: Icons.trending_up_rounded,
              ),
              StatCard(
                title: 'Low or out of stock',
                value: '$inventoryAlerts',
                accentColor: AppColors.freePlan,
                icon: Icons.inventory_2_rounded,
              ),
            ],
          ),
        );
      },
      loading: () => _DashboardWithUpgrade(
        isPremiumAsync: isPremiumAsync,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const DashboardQuickActions(),
            const SizedBox(height: AppSpacing.xl),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
      error: (e, _) => _DashboardWithUpgrade(
        isPremiumAsync: isPremiumAsync,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const DashboardQuickActions(),
            const SizedBox(height: AppSpacing.lg),
            EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Could not load dashboard',
              subtitle: e.toString(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardWithUpgrade extends StatelessWidget {
  const _DashboardWithUpgrade({
    required this.child,
    required this.isPremiumAsync,
  });

  final Widget child;
  final AsyncValue<bool> isPremiumAsync;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        isPremiumAsync.when(
          data: (isPremium) {
            if (isPremium) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              child: Card(
                color: AppColors.premiumContainer,
                child: ListTile(
                  leading: Icon(Icons.workspace_premium_rounded, color: AppColors.premium),
                  title: const Text(
                    'Upgrade to Premium',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Unlock full insights and unlimited reminders'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const UpgradePlanScreen(),
                      ),
                    );
                  },
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        Expanded(child: child),
      ],
    );
  }
}
