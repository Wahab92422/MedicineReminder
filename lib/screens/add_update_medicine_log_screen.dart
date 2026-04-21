import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/meals/meal_statuses.dart';
import '../features/medicine_logs/medicine_log_entry.dart';
import '../features/medicine_logs/medicine_log_providers.dart';
import '../features/medicine_logs/medicine_log_repository.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/date_picker_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/speech_text_field.dart';
import '../widgets/skeleton_placeholders.dart';

class AddUpdateMedicineLogScreen extends ConsumerStatefulWidget {
  const AddUpdateMedicineLogScreen({
    super.key,
    this.existing,
    this.initialLoggedAt,
    this.initialNotes,
    this.lockStatusToScheduled = false,
  });

  final MedicineLogEntry? existing;
  final DateTime? initialLoggedAt;
  final String? initialNotes;
  final bool lockStatusToScheduled;

  @override
  ConsumerState<AddUpdateMedicineLogScreen> createState() =>
      _AddUpdateMedicineLogScreenState();
}

MedicineEntryForPicker? _findPicker(
  List<MedicineEntryForPicker>? list,
  String? medicineId,
) {
  if (list == null || medicineId == null) return null;
  for (final p in list) {
    if (p.id == medicineId) return p;
  }
  return null;
}

class _AddUpdateMedicineLogScreenState
    extends ConsumerState<AddUpdateMedicineLogScreen> {
  final _notesController = TextEditingController();
  final _unitsController = TextEditingController(text: '1');

  String? _medicineId;
  String? _status;
  DateTime? _loggedAt;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _medicineId = e.medicineId;
      _status = e.status;
      _loggedAt = e.loggedAt;
      _unitsController.text = '${e.units}';
      _notesController.text = e.notes;
    } else {
      _status = MealStatuses.scheduled;
      _loggedAt = widget.initialLoggedAt ?? DateTime.now();
      if (widget.initialNotes != null && widget.initialNotes!.isNotEmpty) {
        _notesController.text = widget.initialNotes!;
      }
      if (widget.lockStatusToScheduled) {
        _status = MealStatuses.scheduled;
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _unitsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_medicineId == null || _medicineId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a medicine from your inventory.')),
      );
      return;
    }
    if (_status == null || _status!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a status.')));
      return;
    }
    if (_loggedAt == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select date and time.')));
      return;
    }

    final units = int.tryParse(_unitsController.text.trim()) ?? 0;
    if (units < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Units must be at least 1.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_status == MealStatuses.taken) {
      final pickers = ref
          .read(inventoryMedicinesForPickerProvider(user.uid))
          .asData
          ?.value;
      final med = _findPicker(pickers, _medicineId);
      if (med != null && units > med.quantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Only ${med.quantity} ${med.unit} available in inventory.',
            ),
          ),
        );
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(medicineLogRepositoryProvider);
      final uid = user.uid;
      final logId = widget.existing?.id ?? repo.allocateLogId(uid);

      final pickers = ref
          .read(inventoryMedicinesForPickerProvider(uid))
          .asData
          ?.value;
      final picked = _findPicker(pickers, _medicineId);
      final medicineName =
          picked?.name ?? widget.existing?.medicineName ?? 'Medicine';

      final now = DateTime.now();
      final entry = MedicineLogEntry(
        id: logId,
        medicineId: _medicineId!,
        medicineName: medicineName,
        loggedAt: _loggedAt!,
        status: _status!,
        units: units,
        notes: _notesController.text.trim(),
        createdAt: widget.existing?.createdAt ?? now,
        updatedAt: now,
      );

      final MedicineLogWriteResponse result;
      if (_isEdit) {
        result = await repo.updateEntry(
          userId: uid,
          entry: entry,
          previous: widget.existing!,
        );
      } else {
        result = await repo.createEntry(userId: uid, entry: entry);
      }

      if (!result.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.errorMessage ??
                  (_isEdit ? 'Could not update log.' : 'Could not save log.'),
            ),
          ),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Log updated.' : 'Log saved.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final pickerAsync = ref.watch(inventoryMedicinesForPickerProvider(uid));

    return Scaffold(
      appBar: AppScreenHeader(
        title: _isEdit ? 'Edit medicine log' : 'Log medicine dose',
        subtitle: _isEdit
            ? 'Update status, time, or units. Inventory adjusts when status is Taken.'
            : 'Choose a medicine from inventory. Taken doses reduce stock.',
        icon: _isEdit ? Icons.edit_note_outlined : Icons.medication_outlined,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (_isEdit && widget.existing != null)
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Medicine (from inventory)',
                  ),
                  child: Text(
                    widget.existing!.medicineName,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                )
              else
                pickerAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return Text(
                        'Add medicines in Inventory before logging doses.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                    return CustomDropdown<String>(
                      label: 'Medicine (from inventory)',
                      value:
                          _medicineId != null &&
                              items.any((e) => e.id == _medicineId)
                          ? _medicineId
                          : null,
                      items: items
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e.id,
                              child: Text(
                                '${e.name} (${e.quantity} ${e.unit})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _medicineId = v),
                    );
                  },
                  loading: () => const InlineFormSkeleton(lines: 3),
                  error: (e, _) => Text('Could not load inventory: $e'),
                ),
              const SizedBox(height: AppSpacing.md),
              CustomDropdown<String>(
                label: 'Status',
                value: _status,
                items: MealStatuses.all
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                enabled: !(widget.lockStatusToScheduled && !_isEdit),
                onChanged: (v) => setState(() => _status = v),
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                controller: _unitsController,
                label: 'Units (tablets/doses)',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'When status is Taken, this many units are subtracted from inventory.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DatePickerField(
                label: 'Scheduled / logged time',
                value: _loggedAt,
                includeTime: true,
                onDateSelected: (d) => setState(() => _loggedAt = d),
              ),
              const SizedBox(height: AppSpacing.md),
              SpeechTextField(
                controller: _notesController,
                label: 'Notes (optional)',
                maxLines: 3,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: _isEdit ? 'Update log' : 'Save log',
                icon: Icons.check_rounded,
                isLoading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
          if (_saving) const _BlockingLoadingOverlay(message: 'Saving…'),
        ],
      ),
    );
  }
}

class _BlockingLoadingOverlay extends StatelessWidget {
  const _BlockingLoadingOverlay({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const ModalBarrier(dismissible: false, color: Colors.black45),
        Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(message),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
