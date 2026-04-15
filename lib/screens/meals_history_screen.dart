import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/meals/meal_providers.dart';
import '../theme/app_spacing.dart';
import '../widgets/empty_state.dart';
import '../widgets/meal_log_card.dart';
import 'log_meal_screen.dart';

class MealsHistoryScreen extends ConsumerWidget {
  const MealsHistoryScreen({super.key});

  Future<bool> _confirmDelete(BuildContext context) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this meal?'),
        content: const Text('This entry will be removed permanently, including any photo in storage.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return r ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(mealLogsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meals'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(builder: (_) => const LogMealScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log meal'),
      ),
      body: async.when(
        data: (meals) {
          if (meals.isEmpty) {
            return EmptyState(
              icon: Icons.restaurant_outlined,
              title: 'No meals logged',
              subtitle: 'Track what you ate, when, and whether you had the meal or missed it.',
              actionLabel: 'Log meal',
              onAction: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const LogMealScreen()),
                );
              },
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              88,
            ),
            itemCount: meals.length,
            itemBuilder: (context, index) {
              final meal = meals[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Dismissible(
                  key: ValueKey(meal.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    if (!context.mounted) return false;
                    if (!await _confirmDelete(context) || !context.mounted) {
                      return false;
                    }
                    try {
                      await ref.read(mealControllerProvider).deleteMeal(meal);
                      return true;
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not delete: $e')),
                        );
                      }
                      return false;
                    }
                  },
                  onDismissed: (_) {},
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppSpacing.lg),
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: Theme.of(context).colorScheme.onError,
                    ),
                  ),
                  child: MealLogCard(
                    meal: meal,
                    onTap: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => LogMealScreen(existing: meal),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Could not load meals',
          subtitle: e.toString(),
        ),
      ),
    );
  }
}
