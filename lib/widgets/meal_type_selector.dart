import 'package:flutter/material.dart';

import '../features/meals/meal_model.dart';
import '../theme/app_spacing.dart';

/// Single-select meal type (breakfast, lunch, dinner, snack).
class MealTypeSelector extends StatelessWidget {
  const MealTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final MealType value;
  final ValueChanged<MealType> onChanged;

  static IconData iconFor(MealType t) => switch (t) {
        MealType.breakfast => Icons.wb_sunny_outlined,
        MealType.lunch => Icons.lunch_dining_outlined,
        MealType.dinner => Icons.dinner_dining_outlined,
        MealType.snack => Icons.bakery_dining_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: MealType.values.map((type) {
        final selected = value == type;
        return FilterChip(
          avatar: Icon(
            iconFor(type),
            size: 18,
            color: selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
          ),
          label: Text(type.label),
          selected: selected,
          onSelected: (_) => onChanged(type),
          showCheckmark: false,
        );
      }).toList(),
    );
  }
}
