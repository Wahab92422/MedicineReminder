import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_version.dart';
import '../features/auth/auth_controller.dart';
import '../providers/app_version_label_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../screens/dashboard_quick_actions.dart';

/// Side menu: modules list, sign out, and app version (same app bar styling cues).
class DashboardNavigationDrawer extends ConsumerWidget {
  const DashboardNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;

    final versionAsync = ref.watch(appVersionLabelProvider);

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
      ),
      backgroundColor: scheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DrawerBranding(email: email, theme: theme),
            Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                children: [
                  for (final spec in dashboardDrawerQuickActions)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.seed.withValues(alpha: 0.12),
                        foregroundColor: scheme.primary,
                        child: Icon(spec.icon, size: 22),
                      ),
                      title: Text(
                        spec.label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xs,
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        spec.navigate(context);
                      },
                    ),
                ],
              ),
            ),
            _DrawerFooter(
              scheme: scheme,
              theme: theme,
              versionAsync: versionAsync,
              onSignOut: () {
                Navigator.of(context).pop();
                ref.read(authControllerProvider).logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerBranding extends StatelessWidget {
  const _DrawerBranding({required this.email, required this.theme});

  final String? email;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.seed.withValues(alpha: 0.12),
            AppColors.statBlue.withValues(alpha: 0.06),
            scheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, color: scheme.primary, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'More modules',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Health history and alerts',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (email != null && email!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Signed in',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              email!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  const _DrawerFooter({
    required this.scheme,
    required this.theme,
    required this.versionAsync,
    required this.onSignOut,
  });

  final ColorScheme scheme;
  final ThemeData theme;
  final AsyncValue<String> versionAsync;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
          ListTile(
            leading: Icon(Icons.logout_rounded, color: scheme.error),
            title: Text(
              'Sign out',
              style: TextStyle(
                color: scheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            onTap: onSignOut,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: versionAsync.when(
              data: (label) => _VersionText(label: label, theme: theme),
              loading: () => _VersionText(
                label: 'Loading version…',
                theme: theme,
                muted: true,
              ),
              error: (_, _) => _VersionText(
                label: 'Version $kAppVersionFallback ($kAppBuildFallback)',
                theme: theme,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionText extends StatelessWidget {
  const _VersionText({
    required this.label,
    required this.theme,
    this.muted = false,
  });

  final String label;
  final ThemeData theme;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Semantics(
      label: label,
      child: SizedBox(
        width: double.infinity,
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant.withValues(
              alpha: muted ? 0.65 : 1.0,
            ),
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
