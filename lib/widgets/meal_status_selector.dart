import 'package:flutter/material.dart';

import '../features/meals/meal_model.dart';

/// Taken vs missed for a meal log entry.
class MealStatusSelector extends StatelessWidget {
  const MealStatusSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final MealStatus value;
  final ValueChanged<MealStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<MealStatus>(
      segments: const [
        ButtonSegment<MealStatus>(
          value: MealStatus.taken,
          label: Text('Taken'),
          icon: Icon(Icons.check_circle_outline_rounded),
        ),
        ButtonSegment<MealStatus>(
          value: MealStatus.missed,
          label: Text('Missed'),
          icon: Icon(Icons.event_busy_rounded),
        ),
      ],
      selected: {value},
      onSelectionChanged: (set) {
        if (set.isNotEmpty) onChanged(set.first);
      },
    );
  }
}
