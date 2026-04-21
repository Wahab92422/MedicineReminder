import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../features/medicine_inventory/medicine_categories.dart';
import '../features/medicine_inventory/medicine_entry.dart';
import '../features/medicine_inventory/medicine_providers.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/date_picker_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/speech_text_field.dart';

class AddUpdateMedicineScreen extends ConsumerStatefulWidget {
  const AddUpdateMedicineScreen({super.key, this.existing});

  final MedicineEntry? existing;

  @override
  ConsumerState<AddUpdateMedicineScreen> createState() =>
      _AddUpdateMedicineScreenState();
}

class _AddUpdateMedicineScreenState
    extends ConsumerState<AddUpdateMedicineScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _quantityController;
  late final TextEditingController _thresholdController;
  late final TextEditingController _notesController;

  String? _category;
  String? _unit;
  DateTime? _expiryDate;
  bool _saving = false;

  Uint8List? _selectedAttachmentBytes;
  String? _selectedAttachmentName;
  String? _selectedAttachmentMimeType;
  String? _existingAttachmentUrl;
  bool _removeExistingAttachment = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _dosageController = TextEditingController();
    _quantityController = TextEditingController();
    _thresholdController = TextEditingController();
    _notesController = TextEditingController();

    final e = widget.existing;
    if (e != null) {
      _nameController.text = e.name;
      _dosageController.text = e.dosage;
      _quantityController.text = '${e.quantity}';
      _thresholdController.text = '${e.lowStockThreshold}';
      _notesController.text = e.notes;
      _category = e.category;
      _unit = e.unit;
      _expiryDate = e.expiryDate;
      _existingAttachmentUrl = e.attachmentUrl;
    } else {
      _category = MedicineCategories.other;
      _unit = 'tablets';
      _expiryDate = DateTime.now().add(const Duration(days: 365));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _quantityController.dispose();
    _thresholdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int? _parseInt(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  Future<void> _pickAttachment(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _selectedAttachmentBytes = bytes;
      _selectedAttachmentName = picked.name;
      _selectedAttachmentMimeType =
          lookupMimeType(picked.path, headerBytes: bytes) ?? 'image/jpeg';
      _removeExistingAttachment = true;
    });
  }

  Future<void> _showAttachmentSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAttachment(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAttachment(ImageSource.gallery);
              },
            ),
            if (_selectedAttachmentBytes != null ||
                (_existingAttachmentUrl != null && !_removeExistingAttachment))
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('Remove attachment'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _selectedAttachmentBytes = null;
                    _selectedAttachmentName = null;
                    _selectedAttachmentMimeType = null;
                    _removeExistingAttachment = true;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter medicine name.')));
      return;
    }

    if (_category == null || _category!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a category.')));
      return;
    }

    final quantity = _parseInt(_quantityController.text);
    if (quantity == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter quantity.')));
      return;
    }

    final threshold = _parseInt(_thresholdController.text);
    if (threshold == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter low stock threshold.')),
      );
      return;
    }

    if (_expiryDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select expiry date.')));
      return;
    }

    if (_unit == null || _unit!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select unit.')));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);

    try {
      final repo = ref.read(medicineRepositoryProvider);
      final now = DateTime.now();
      final entryId = widget.existing?.id ?? repo.allocateEntryId(user.uid);

      String? attachmentUrl = _existingAttachmentUrl;
      if (_removeExistingAttachment && _existingAttachmentUrl != null) {
        await repo.deleteStoredFile(_existingAttachmentUrl!);
        attachmentUrl = null;
        _existingAttachmentUrl = null;
      }
      if (_selectedAttachmentBytes != null &&
          _selectedAttachmentName != null &&
          _selectedAttachmentMimeType != null) {
        attachmentUrl = await repo.uploadMedicineAttachment(
          userId: user.uid,
          entryId: entryId,
          originalFileName: _selectedAttachmentName!,
          bytes: _selectedAttachmentBytes!,
          contentType: _selectedAttachmentMimeType!,
        );
      }

      final entry = MedicineEntry(
        id: entryId,
        name: name,
        category: _category!,
        dosage: _dosageController.text.trim(),
        quantity: quantity,
        unit: _unit!,
        expiryDate: _expiryDate!,
        lowStockThreshold: threshold,
        notes: _notesController.text.trim(),
        attachmentUrl: attachmentUrl,
        createdAt: widget.existing?.createdAt ?? now,
        updatedAt: now,
      );

      final result = _isEdit
          ? await repo.updateEntry(userId: user.uid, entry: entry)
          : await repo.createEntry(userId: user.uid, entry: entry);

      if (!result.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.errorMessage ??
                  (_isEdit
                      ? 'Could not update medicine.'
                      : 'Could not save medicine.'),
            ),
          ),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Medicine updated.' : 'Medicine saved.'),
        ),
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
    return Scaffold(
      appBar: AppScreenHeader(
        title: _isEdit ? 'Edit Medicine' : 'Add Medicine',
        subtitle: _isEdit
            ? 'Update medicine details and inventory. For dose reminders, add or edit a log with status Scheduled.'
            : 'Add a new medicine to your inventory. After saving, use Medicine logs with status Scheduled to get dose reminders.',
        icon: _isEdit ? Icons.edit_note_outlined : Icons.add_rounded,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              CustomTextField(
                controller: _nameController,
                label: 'Medicine name',
                hint: 'e.g. Aspirin, Amoxicillin',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              CustomDropdown<String>(
                label: 'Category',
                value: _category,
                items: MedicineCategories.all
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _category = v),
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                controller: _dosageController,
                label: 'Dosage',
                hint: 'e.g. 500mg, 10ml',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _quantityController,
                      label: 'Quantity',
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: CustomDropdown<String>(
                      label: 'Unit',
                      value: _unit,
                      items:
                          [
                                'tablets',
                                'capsules',
                                'ml',
                                'grams',
                                'pieces',
                                'strips',
                                'bottles',
                              ]
                              .map(
                                (u) =>
                                    DropdownMenuItem(value: u, child: Text(u)),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => _unit = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                controller: _thresholdController,
                label: 'Low stock threshold',
                hint: 'Alert when quantity falls below this',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              DatePickerField(
                label: 'Expiry date',
                value: _expiryDate,
                onDateSelected: (d) => setState(() => _expiryDate = d),
              ),
              const SizedBox(height: AppSpacing.md),
              SpeechTextField(
                controller: _notesController,
                label: 'Notes',
                hint: 'Any additional information',
                maxLines: 3,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Attachment (optional)',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: _showAttachmentSourceSheet,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(
                  _selectedAttachmentBytes != null ||
                          (_existingAttachmentUrl != null &&
                              !_removeExistingAttachment)
                      ? 'Change attachment'
                      : 'Add attachment',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_selectedAttachmentBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Image.memory(
                    _selectedAttachmentBytes!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else if (_existingAttachmentUrl != null &&
                  !_removeExistingAttachment)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Image.network(
                    _existingAttachmentUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                Text(
                  'No attachment selected.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: _isEdit ? 'Update Medicine' : 'Save Medicine',
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
          if (_saving)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
