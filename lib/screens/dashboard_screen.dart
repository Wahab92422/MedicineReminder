import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notification_service.dart';
import '../services/scheduled_reminder_auto_miss_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/dashboard_navigation_drawer.dart';
import '../widgets/quick_action_button.dart';
import 'dashboard_quick_actions.dart';
import 'scheduled_reminders_screen.dart';

/// Main screen after sign-in: shortcuts and account actions.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  double _tileWidth(BuildContext context) {
    return (MediaQuery.sizeOf(context).width -
            AppSpacing.lg * 2 -
            AppSpacing.sm) /
        2;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) return;
      await NotificationService().handlePendingLaunchNotification();
      await ScheduledReminderAutoMissService().applyForUser(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Signed in';

    return Scaffold(
      appBar: AppScreenHeader(
        title: 'Dashboard',
        subtitle: 'Jump into the health modules you use most.',
        icon: Icons.dashboard_customize_outlined,
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const ScheduledRemindersScreen(),
                ),
              );
            },
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
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
