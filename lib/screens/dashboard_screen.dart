import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth_controller.dart';
import '../theme/app_spacing.dart';
import '../widgets/primary_button.dart';
import '../widgets/quick_action_button.dart';
import 'lab_reports_screen.dart';

/// Main screen after sign-in: shortcuts and account actions.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Signed in';

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
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
            QuickActionButton(
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
