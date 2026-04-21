import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth_controller.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/primary_button.dart';
import '../widgets/quick_action_button.dart';
import 'family_history_screen.dart';
import 'lab_reports_screen.dart';
import 'meals_screen.dart';
import 'medicine_logs_screen.dart';
import 'medical_history_screen.dart';
import 'medicine_inventory_screen.dart';
import 'notifications_screen.dart';
import 'social_history_screen.dart';
import 'surgical_history_screen.dart';
import 'vitals_screen.dart';

/// Main screen after sign-in: shortcuts and account actions.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Signed in';

    return Scaffold(
      appBar: const AppScreenHeader(
        title: 'Dashboard',
        subtitle: 'Jump into the health modules you use most.',
        icon: Icons.dashboard_customize_outlined,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Welcome', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            SelectableText(email, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Quick actions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                SizedBox(
                  width:
                      (MediaQuery.sizeOf(context).width -
                          AppSpacing.lg * 2 -
                          AppSpacing.sm) /
                      2,
                  child: QuickActionButton(
                    icon: Icons.biotech_rounded,
                    label: 'Lab reports',
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const LabReportsScreen(),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width:
                      (MediaQuery.sizeOf(context).width -
                          AppSpacing.lg * 2 -
                          AppSpacing.sm) /
                      2,
                  child: QuickActionButton(
                    icon: Icons.monitor_heart_rounded,
                    label: 'Vitals',
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const VitalsScreen(),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width:
                      (MediaQuery.sizeOf(context).width -
                          AppSpacing.lg * 2 -
                          AppSpacing.sm) /
                      2,
                  child: QuickActionButton(
                    icon: Icons.restaurant_menu_rounded,
                    label: 'Meals',
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const MealsScreen(),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width:
                      (MediaQuery.sizeOf(context).width -
                          AppSpacing.lg * 2 -
                          AppSpacing.sm) /
                      2,
                  child: QuickActionButton(
                    icon: Icons.fact_check_outlined,
                    label: 'Medicines',
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const MedicineLogsScreen(),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width:
                      (MediaQuery.sizeOf(context).width -
                          AppSpacing.lg * 2 -
                          AppSpacing.sm) /
                      2,
                  child: QuickActionButton(
                    icon: Icons.groups_2_rounded,
                    label: 'Social history',
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const SocialHistoryScreen(),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width:
                      (MediaQuery.sizeOf(context).width -
                          AppSpacing.lg * 2 -
                          AppSpacing.sm) /
                      2,
                  child: QuickActionButton(
                    icon: Icons.medical_information_rounded,
                    label: 'Medical history',
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const MedicalHistoryScreen(),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width:
                      (MediaQuery.sizeOf(context).width -
                          AppSpacing.lg * 2 -
                          AppSpacing.sm) /
                      2,
                  child: QuickActionButton(
                    icon: Icons.family_restroom_rounded,
                    label: 'Family history',
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const FamilyHistoryScreen(),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width:
                      (MediaQuery.sizeOf(context).width -
                          AppSpacing.lg * 2 -
                          AppSpacing.sm) /
                      2,
                  child: QuickActionButton(
                    icon: Icons.medical_services_rounded,
                    label: 'Surgical history',
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const SurgicalHistoryScreen(),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width:
                      (MediaQuery.sizeOf(context).width -
                          AppSpacing.lg * 2 -
                          AppSpacing.sm) /
                      2,
                  child: QuickActionButton(
                    icon: Icons.local_pharmacy_rounded,
                    label: 'Inventory',
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const MedicineInventoryScreen(),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width:
                      (MediaQuery.sizeOf(context).width -
                          AppSpacing.lg * 2 -
                          AppSpacing.sm) /
                      2,
                  child: QuickActionButton(
                    icon: Icons.notifications_active_rounded,
                    label: 'Notifications',
                    onTap: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'More modules can be added here as you grow the app.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            PrimaryButton(
              label: 'Sign out',
              icon: Icons.logout_rounded,
              onPressed: () => ref.read(authControllerProvider).logout(),
            ),
          ],
        ),
      ),
    );
  }
}
