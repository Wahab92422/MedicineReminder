import 'package:flutter/material.dart';

import '../features/medical_history/medical_history_model.dart';
import '../theme/app_spacing.dart';

class MedicalConditionStatusSelector extends StatelessWidget {
  const MedicalConditionStatusSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final MedicalConditionStatus value;
  final ValueChanged<MedicalConditionStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: MedicalConditionStatus.values.map((s) {
        final selected = value == s;
        return FilterChip(
          label: Text(s.label),
          selected: selected,
          onSelected: (_) => onChanged(s),
          showCheckmark: false,
          selectedColor: scheme.primaryContainer,
          checkmarkColor: scheme.onPrimaryContainer,
        );
      }).toList(),
    );
  }
}
