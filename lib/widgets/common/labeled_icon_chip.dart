import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Small icon + label row for metadata lines (history, cards, etc.).
class LabeledIconChip extends StatelessWidget {
  const LabeledIconChip({
    super.key,
    required this.icon,
    required this.label,
    this.foreground,
  });

  final IconData icon;
  final String label;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = foreground ?? scheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: fg),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}
