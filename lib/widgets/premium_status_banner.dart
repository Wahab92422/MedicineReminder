import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class PremiumStatusBanner extends StatelessWidget {
  const PremiumStatusBanner({
    super.key,
    required this.isPremium,
    this.onUpgradeTap,
  });

  final bool isPremium;
  final VoidCallback? onUpgradeTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (isPremium) {
      return Material(
        color: AppColors.premiumContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              Icon(Icons.workspace_premium_rounded, color: AppColors.premium),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Premium active — full reminders & insights',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Material(
      color: AppColors.freePlanContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.freePlan),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Free plan — upgrade anytime for unlimited features',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            if (onUpgradeTap != null)
              TextButton(
                onPressed: onUpgradeTap,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.freePlan,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                ),
                child: const Text('Upgrade'),
              ),
          ],
        ),
      ),
    );
  }
}
