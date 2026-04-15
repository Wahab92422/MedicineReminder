import 'package:flutter/material.dart';

import '../features/clinical_notes/clinical_note_model.dart';
import '../theme/app_spacing.dart';

/// Single-select documentation category for a clinical note.
class ClinicalNoteCategorySelector extends StatelessWidget {
  const ClinicalNoteCategorySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ClinicalNoteCategory value;
  final ValueChanged<ClinicalNoteCategory> onChanged;

  static IconData iconFor(ClinicalNoteCategory c) => switch (c) {
        ClinicalNoteCategory.progress => Icons.edit_note_outlined,
        ClinicalNoteCategory.assessmentPlan => Icons.assignment_outlined,
        ClinicalNoteCategory.phoneMessage => Icons.phone_callback_outlined,
        ClinicalNoteCategory.consultationSummary =>
          Icons.medical_information_outlined,
        ClinicalNoteCategory.general => Icons.notes_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: ClinicalNoteCategory.values.map((cat) {
        final selected = value == cat;
        return FilterChip(
          avatar: Icon(
            iconFor(cat),
            size: 18,
            color: selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
          ),
          label: Text(cat.label),
          selected: selected,
          onSelected: (_) => onChanged(cat),
          showCheckmark: false,
        );
      }).toList(),
    );
  }
}
