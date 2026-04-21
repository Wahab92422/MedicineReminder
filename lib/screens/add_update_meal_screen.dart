import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../features/meals/meal_entry.dart';
import '../features/meals/meal_providers.dart';
import '../features/meals/meal_repository.dart';
import '../features/meals/meal_statuses.dart';
import '../features/meals/meal_types.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/date_picker_field.dart';
import '../widgets/primary_button.dart';

class AddUpdateMealScreen extends ConsumerStatefulWidget {
  const AddUpdateMealScreen({
    super.key,
    this.existing,
    this.initialMealAt,
    this.initialNotes,
    this.lockStatusToScheduled = false,
  });

  final MealEntry? existing;
  final DateTime? initialMealAt;
  final String? initialNotes;
  final bool lockStatusToScheduled;

  @override
  ConsumerState<AddUpdateMealScreen> createState() =>
      _AddUpdateMealScreenState();
}

class _AddUpdateMealScreenState extends ConsumerState<AddUpdateMealScreen> {
  final _notesController = TextEditingController();

  String? _mealType;
  String? _status;
  DateTime? _mealAt;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _selectedImageMimeType;
  String? _existingImageUrl;
  bool _removeExistingImage = false;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _mealType = e.mealType;
      _status = e.status;
      _mealAt = e.mealAt;
      _notesController.text = e.notes;
      _existingImageUrl = e.imageUrl;
    } else {
      _mealType = MealTypes.breakfast;
      _status = MealStatuses.scheduled;
      _mealAt = widget.initialMealAt ?? DateTime.now();
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
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _selectedImageBytes = bytes;
      _selectedImageName = picked.name;
      _selectedImageMimeType =
          lookupMimeType(picked.path, headerBytes: bytes) ?? 'image/jpeg';
      _removeExistingImage = true;
    });
  }

  Future<void> _showImageSourceSheet() async {
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
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_selectedImageBytes != null || _existingImageUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('Remove image'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _selectedImageBytes = null;
                    _selectedImageName = null;
                    _selectedImageMimeType = null;
                    _removeExistingImage = true;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_mealType == null || _mealType!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a meal type.')));
      return;
    }
    if (_status == null || _status!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a meal status.')));
      return;
    }
    if (_mealAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select the meal date and time.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(mealRepositoryProvider);
      final uid = user.uid;
      final mealId = widget.existing?.id ?? repo.allocateMealId(uid);

      String? imageUrl = _existingImageUrl;
      if (_removeExistingImage && _existingImageUrl != null) {
        await repo.deleteStoredFile(_existingImageUrl!);
        imageUrl = null;
        _existingImageUrl = null;
      }
      if (_selectedImageBytes != null &&
          _selectedImageName != null &&
          _selectedImageMimeType != null) {
        imageUrl = await repo.uploadMealImage(
          userId: uid,
          mealId: mealId,
          originalFileName: _selectedImageName!,
          bytes: _selectedImageBytes!,
          contentType: _selectedImageMimeType!,
        );
      }

      final now = DateTime.now();
      final entry = MealEntry(
        id: mealId,
        mealAt: _mealAt!,
        mealType: _mealType!,
        status: _status!,
        notes: _notesController.text.trim(),
        imageUrl: imageUrl,
        createdAt: widget.existing?.createdAt ?? now,
        updatedAt: now,
      );

      final MealWriteResponse result = _isEdit
          ? await repo.updateEntry(userId: uid, entry: entry)
          : await repo.createEntry(userId: uid, entry: entry);

      if (!result.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.errorMessage ??
                  (_isEdit ? 'Could not update meal.' : 'Could not save meal.'),
            ),
          ),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isQueuedForSync
                ? (_isEdit
                      ? 'Updated locally. Sync will complete when connection recovers.'
                      : 'Saved locally. Sync will complete when connection recovers.')
                : (_isEdit ? 'Meal updated.' : 'Meal saved.'),
          ),
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
        title: _isEdit ? 'Edit Meal' : 'Add Meal',
        subtitle: _isEdit
            ? 'Update meal type, status, notes, or image.'
            : 'Track a meal with status and an optional image.',
        icon: _isEdit
            ? Icons.edit_note_outlined
            : Icons.restaurant_menu_outlined,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              CustomDropdown<String>(
                label: 'Meal type',
                value: _mealType,
                items: MealTypes.all
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _mealType = v),
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
              DatePickerField(
                label: 'Meal date & time',
                value: _mealAt,
                includeTime: true,
                onDateSelected: (d) => setState(() => _mealAt = d),
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                controller: _notesController,
                label: 'Notes',
                maxLines: 3,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Photo',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: _showImageSourceSheet,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(
                  _selectedImageBytes != null || _existingImageUrl != null
                      ? 'Change image'
                      : 'Add image',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_selectedImageBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Image.memory(
                    _selectedImageBytes!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else if (_existingImageUrl != null && !_removeExistingImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Image.network(
                    _existingImageUrl!,
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
                  'No image selected.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: _isEdit ? 'Update meal' : 'Save meal',
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
