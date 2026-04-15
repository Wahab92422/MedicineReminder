import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/medicines/medicine_controller.dart';
import '../features/medicines/medicine_reminder_time.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/reminder_datetime_picker_tile.dart';
import '../widgets/section_header.dart';

class EditMedicineScreen extends ConsumerStatefulWidget {
  const EditMedicineScreen({
    super.key,
    required this.id,
    required this.name,
    required this.dose,
    required this.time,
    required this.quantityOnHand,
    this.lowStockThreshold,
    required this.inventoryUnit,
  });

  final String id;
  final String name;
  final String dose;
  final String time;
  final int quantityOnHand;
  final int? lowStockThreshold;
  final String inventoryUnit;

  @override
  ConsumerState<EditMedicineScreen> createState() => _EditMedicineScreenState();
}

class _EditMedicineScreenState extends ConsumerState<EditMedicineScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _doseController;
  late final TextEditingController _quantityController;
  late final TextEditingController _lowStockController;
  late final TextEditingController _unitController;
  DateTime? _reminderAt;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _doseController = TextEditingController(text: widget.dose);
    _quantityController = TextEditingController(text: '${widget.quantityOnHand}');
    _lowStockController = TextEditingController(
      text: widget.lowStockThreshold?.toString() ?? '',
    );
    _unitController = TextEditingController(text: widget.inventoryUnit);
    _reminderAt = MedicineReminderTime.decodeToLocal(widget.time);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _quantityController.dispose();
    _lowStockController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    if (_reminderAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose reminder date & time.'),
        ),
      );
      return;
    }

    final qty = int.tryParse(_quantityController.text.trim());
    if (qty == null || qty < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid stock quantity (0 or more).'),
        ),
      );
      return;
    }

    final lowRaw = _lowStockController.text.trim();
    final lowParsed = lowRaw.isEmpty ? null : int.tryParse(lowRaw);
    if (lowRaw.isNotEmpty && lowParsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Low-stock alert must be a whole number or empty.'),
        ),
      );
      return;
    }

    final unit = _unitController.text.trim();
    if (unit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a unit label (e.g. tablets).'),
        ),
      );
      return;
    }

    final timeStored = MedicineReminderTime.encodeLocal(_reminderAt!);

    await ref.read(medicineControllerProvider).updateMedicine(
          id: widget.id,
          name: _nameController.text.trim(),
          dose: _doseController.text.trim(),
          time: timeStored,
          quantityOnHand: qty,
          lowStockThreshold: lowParsed,
          inventoryUnit: unit,
        );
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit medicine'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SectionHeader(title: 'Details'),
          AppTextField(
            controller: _nameController,
            label: 'Name',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _doseController,
            label: 'Dose',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Inventory'),
          AppTextField(
            controller: _quantityController,
            label: 'Quantity on hand',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _lowStockController,
            label: 'Low-stock alert (optional)',
            hint: 'Leave empty to disable',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _unitController,
            label: 'Unit label',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Reminder date & time'),
          ReminderDateTimeFormFields(
            value: _reminderAt,
            onChanged: (dt) => setState(() => _reminderAt = dt),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Save changes',
            icon: Icons.save_rounded,
            onPressed: _update,
          ),
        ],
      ),
    );
  }
}
