import 'package:flutter/material.dart';

/// Form dropdown with label and items.
class CustomDropdown<T> extends StatelessWidget {
  const CustomDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      // ignore: deprecated_member_use
      value: value,
      decoration: InputDecoration(
        labelText: label,
      ).applyDefaults(Theme.of(context).inputDecorationTheme),
      items: items,
      onChanged: enabled ? onChanged : null,
    );
  }
}
