import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/history_screen.dart';
import '../screens/lab_history_screen.dart';
import '../screens/medicine_scheduling_screen.dart';
import '../screens/quick_action_placeholder_screen.dart';
import '../screens/vitals_list_screen.dart';
import '../theme/app_spacing.dart';
import 'section_header.dart';

class _QuickActionItem {
  const _QuickActionItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final void Function(BuildContext context, WidgetRef ref) onTap;
}

class DashboardQuickActions extends ConsumerWidget {
  const DashboardQuickActions({super.key});

  static final List<_QuickActionItem> _items = [
    _QuickActionItem(
      label: 'Vitals',
      icon: Icons.monitor_heart_outlined,
      onTap: (context, ref) {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const VitalsListScreen(),
          ),
        );
      },
    ),
    _QuickActionItem(
      label: 'Medications',
      icon: Icons.medication_liquid_rounded,
      onTap: (context, ref) {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const HistoryScreen(),
          ),
        );
      },
    ),
    _QuickActionItem(
      label: 'Scheduling',
      icon: Icons.calendar_month_rounded,
      onTap: (context, ref) {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const MedicineSchedulingScreen(),
          ),
        );
      },
    ),
    _QuickActionItem(
      label: 'Meals',
      icon: Icons.restaurant_rounded,
      onTap: (context, ref) {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const QuickActionPlaceholderScreen(
              title: 'Meals',
              icon: Icons.restaurant_rounded,
            ),
          ),
        );
      },
    ),
    _QuickActionItem(
      label: 'Clinical Notes',
      icon: Icons.note_alt_outlined,
      onTap: (context, ref) {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const QuickActionPlaceholderScreen(
              title: 'Clinical Notes',
              icon: Icons.note_alt_outlined,
            ),
          ),
        );
      },
    ),
    _QuickActionItem(
      label: 'Appointments',
      icon: Icons.event_available_outlined,
      onTap: (context, ref) {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const QuickActionPlaceholderScreen(
              title: 'Appointments',
              icon: Icons.event_available_outlined,
            ),
          ),
        );
      },
    ),
    _QuickActionItem(
      label: 'Lab Reports',
      icon: Icons.science_outlined,
      onTap: (context, ref) {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const LabHistoryScreen(),
          ),
        );
      },
    ),
    _QuickActionItem(
      label: 'Medical History',
      icon: Icons.history_edu_outlined,
      onTap: (context, ref) {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const QuickActionPlaceholderScreen(
              title: 'Medical History',
              icon: Icons.history_edu_outlined,
            ),
          ),
        );
      },
    ),
    _QuickActionItem(
      label: 'Surgical History',
      icon: Icons.local_hospital_outlined,
      onTap: (context, ref) {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const QuickActionPlaceholderScreen(
              title: 'Surgical History',
              icon: Icons.local_hospital_outlined,
            ),
          ),
        );
      },
    ),
    _QuickActionItem(
      label: 'Family History',
      icon: Icons.groups_outlined,
      onTap: (context, ref) {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const QuickActionPlaceholderScreen(
              title: 'Family History',
              icon: Icons.groups_outlined,
            ),
          ),
        );
      },
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Quick Actions'),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.35,
          ),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final item = _items[index];
            return Material(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => item.onTap(context, ref),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm + 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, size: 28, color: scheme.primary),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
