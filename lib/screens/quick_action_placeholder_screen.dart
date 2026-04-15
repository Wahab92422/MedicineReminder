import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../widgets/empty_state.dart';

/// Placeholder for health record areas not implemented yet.
class QuickActionPlaceholderScreen extends StatelessWidget {
  const QuickActionPlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: EmptyState(
          icon: icon,
          title: 'Coming soon',
          subtitle:
              '$title will be available in a future update. You can continue '
              'using reminders and inventory from the other tabs.',
        ),
      ),
    );
  }
}
