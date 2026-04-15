import 'package:flutter/material.dart';

import '../features/family_history/family_history_model.dart';
import '../theme/app_spacing.dart';

class FamilyRelationshipSelector extends StatelessWidget {
  const FamilyRelationshipSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final FamilyRelationship value;
  final ValueChanged<FamilyRelationship> onChanged;

  static IconData iconFor(FamilyRelationship r) => switch (r) {
        FamilyRelationship.father => Icons.man_2_outlined,
        FamilyRelationship.mother => Icons.woman_2_outlined,
        FamilyRelationship.sibling => Icons.people_outline,
        FamilyRelationship.child => Icons.child_care_outlined,
        FamilyRelationship.maternalGrandparent => Icons.elderly_outlined,
        FamilyRelationship.paternalGrandparent => Icons.elderly_woman_outlined,
        FamilyRelationship.other => Icons.person_outline,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: FamilyRelationship.values.map((rel) {
        final selected = value == rel;
        return FilterChip(
          avatar: Icon(
            iconFor(rel),
            size: 18,
            color: selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
          ),
          label: Text(rel.label),
          selected: selected,
          onSelected: (_) => onChanged(rel),
          showCheckmark: false,
        );
      }).toList(),
    );
  }
}
