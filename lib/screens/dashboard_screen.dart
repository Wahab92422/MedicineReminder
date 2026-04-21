import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_spacing.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/dashboard_navigation_drawer.dart';
import '../widgets/quick_action_button.dart';
import 'dashboard_quick_actions.dart';

/// Main screen after sign-in: shortcuts and account actions.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  double _tileWidth(BuildContext context) {
    return (MediaQuery.sizeOf(context).width -
            AppSpacing.lg * 2 -
            AppSpacing.sm) /
        2;
  }

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
      drawer: const DashboardNavigationDrawer(),
      body: Builder(
        builder: (context) {
          final bottomInset = MediaQuery.paddingOf(context).bottom;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg + bottomInset,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                SelectableText(
                  email,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Quick actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final spec in dashboardPrimaryQuickActions)
                      SizedBox(
                        width: _tileWidth(context),
                        child: QuickActionButton(
                          icon: spec.icon,
                          label: spec.label,
                          onTap: () => spec.navigate(context),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
