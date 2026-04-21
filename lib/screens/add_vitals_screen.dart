import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/primary_button.dart';
import 'add_update_vitals_screen.dart';

/// Hosts the add form (no existing entry). For edit, use [AddUpdateVitalsScreen] with [VitalEntry].
class AddVitalsScreen extends StatelessWidget {
  const AddVitalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const AppScreenHeader(
        title: 'Add Vitals',
        subtitle: 'Create a new reading with time, values, and notes.',
        icon: Icons.playlist_add_check_circle_outlined,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                gradient: LinearGradient(
                  colors: [
                    AppColors.seed.withValues(alpha: 0.18),
                    AppColors.statBlue.withValues(alpha: 0.10),
                    scheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: Icon(
                      Icons.monitor_heart_outlined,
                      color: scheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Log today\'s health snapshot',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Capture the numbers that matter now, then add notes so future you can spot patterns faster.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: const [
                      _VitalsChip(
                        icon: Icons.favorite_border,
                        label: 'Blood pressure',
                      ),
                      _VitalsChip(
                        icon: Icons.monitor_heart_outlined,
                        label: 'Heart rate',
                      ),
                      _VitalsChip(
                        icon: Icons.thermostat_outlined,
                        label: 'Temperature',
                      ),
                      _VitalsChip(icon: Icons.air_rounded, label: 'SpO₂'),
                      _VitalsChip(
                        icon: Icons.monitor_weight_outlined,
                        label: 'Weight',
                      ),
                      _VitalsChip(
                        icon: Icons.science_outlined,
                        label: 'Glucose',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Before you start',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _ChecklistRow(
                    icon: Icons.schedule_rounded,
                    title: 'Pick the recorded time',
                    subtitle:
                        'Save the exact moment or backfill a reading from earlier.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _ChecklistRow(
                    icon: Icons.notes_rounded,
                    title: 'Add context if something feels off',
                    subtitle:
                        'Notes help explain medications, meals, or symptoms around a reading.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _ChecklistRow(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'One value is enough',
                    subtitle:
                        'You can save a single measurement or a complete vitals set.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Start entry',
              icon: Icons.arrow_forward_rounded,
              onPressed: () async {
                final created = await Navigator.of(context)
                    .pushReplacement<bool, bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => const AddUpdateVitalsScreen(),
                      ),
                      result: false,
                    );
                if (created == true && context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'You can edit or delete entries later from the vitals list.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _VitalsChip extends StatelessWidget {
  const _VitalsChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(icon, color: scheme.primary, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
