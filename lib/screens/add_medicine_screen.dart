import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/medicines/medicine_controller.dart';
import '../features/medicines/medicine_reminder_time.dart';
import '../features/subscription/medicine_entitlement.dart';
import '../providers/subscription_provider.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/reminder_datetime_picker_tile.dart';
import '../widgets/section_header.dart';
import 'upgrade_plan_screen.dart';

class AddMedicineScreen extends ConsumerStatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  ConsumerState<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends ConsumerState<AddMedicineScreen> {
  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  final _quantityController = TextEditingController(text: '0');
  final _lowStockController = TextEditingController();
  final _unitController = TextEditingController(text: 'tablets');
  DateTime? _reminderAt;

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _quantityController.dispose();
    _lowStockController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty || _reminderAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a name and choose reminder date & time.'),
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
    final name = _nameController.text.trim();
    final dose = _doseController.text.trim();
    final medicineController = ref.read(medicineControllerProvider);

    final existing = ref.read(medicineStreamProvider).value ?? [];
    final isPremium = ref.read(subscriptionProvider).asData?.value ?? false;
    if (!MedicineEntitlement.canAddMore(
      isPremium: isPremium,
      medicineCount: existing.length,
    )) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Free plan allows ${MedicineEntitlement.freeMaxMedicines} medicines. Upgrade for unlimited.',
          ),
          action: SnackBarAction(
            label: 'Upgrade',
            onPressed: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(builder: (_) => const UpgradePlanScreen()),
              );
            },
          ),
        ),
      );
      return;
    }

    final id = await medicineController.addMedicine(
      name: name,
      dose: dose,
      time: timeStored,
      quantityOnHand: qty,
      lowStockThreshold: lowParsed,
      inventoryUnit: unit,
    );

    if (id != null) {
      await medicineController.scheduleMedicineReminder(
        medicineId: id,
        name: name,
        time: timeStored,
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add medicine'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SectionHeader(title: 'Details'),
          AppTextField(
            controller: _nameController,
            label: 'Medicine name',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _doseController,
            label: 'Dose (e.g. 1 tablet)',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Inventory'),
          AppTextField(
            controller: _quantityController,
            label: 'Quantity on hand',
            hint: 'e.g. 30',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _lowStockController,
            label: 'Low-stock alert (optional)',
            hint: 'e.g. 5 — warn when at or below',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _unitController,
            label: 'Unit label',
            hint: 'tablets, capsules, ml…',
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Reminder date & time'),
          ReminderDateTimeFormFields(
            value: _reminderAt,
            onChanged: (dt) => setState(() => _reminderAt = dt),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Save medicine',
            icon: Icons.check_rounded,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
