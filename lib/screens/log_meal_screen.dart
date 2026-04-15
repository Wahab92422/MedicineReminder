import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../features/meals/meal_model.dart';
import '../features/meals/meal_providers.dart';
import '../theme/app_spacing.dart';
import '../widgets/meal_datetime_picker_tile.dart';
import '../widgets/meal_photo_picker_field.dart';
import '../widgets/meal_status_selector.dart';
import '../widgets/meal_type_selector.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_header.dart';

class LogMealScreen extends ConsumerStatefulWidget {
  const LogMealScreen({super.key, this.existing});

  final MealLog? existing;

  @override
  ConsumerState<LogMealScreen> createState() => _LogMealScreenState();
}

class _LogMealScreenState extends ConsumerState<LogMealScreen> {
  final _mealNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  late DateTime _loggedAt;
  late MealType _mealType;
  late MealStatus _status;

  XFile? _newImage;
  Uint8List? _newImageBytes;
  bool _removeImage = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _mealNameController.text = e.mealName;
      _descriptionController.text = e.description;
      _loggedAt = e.loggedAt;
      _mealType = e.mealType;
      _status = e.status;
    } else {
      _loggedAt = DateTime.now();
      _mealType = MealType.breakfast;
      _status = MealStatus.taken;
    }
  }

  @override
  void dispose() {
    _mealNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  InputDecoration _dec(BuildContext context, {String? label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
    ).applyDefaults(Theme.of(context).inputDecorationTheme);
  }

  Future<void> _onImagePicked(XFile file) async {
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _newImage = file;
      _newImageBytes = bytes;
      _removeImage = false;
    });
  }

  void _onImageClear() {
    setState(() {
      _newImage = null;
      _newImageBytes = null;
      _removeImage = true;
    });
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final name = _mealNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a meal name.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final ctrl = ref.read(mealControllerProvider);
      final existing = widget.existing;

      String? imageUrl = existing?.imageUrl;
      String? imagePath = existing?.imageStoragePath;

      if (_removeImage) {
        if (imagePath != null && imagePath.isNotEmpty) {
          await ctrl.deleteStorageAtPath(imagePath);
        }
        imageUrl = null;
        imagePath = null;
      }

      if (_newImage != null) {
        if (imagePath != null && imagePath.isNotEmpty) {
          await ctrl.deleteStorageAtPath(imagePath);
        }
        final upload = await ctrl.uploadPhoto(userId: user.uid, file: _newImage!);
        imageUrl = upload.downloadUrl;
        imagePath = upload.storagePath;
      }

      final meal = MealLog(
        id: existing?.id ?? '',
        userId: user.uid,
        mealName: name,
        loggedAt: _loggedAt,
        mealType: _mealType,
        status: _status,
        description: _descriptionController.text.trim(),
        imageUrl: imageUrl,
        imageStoragePath: imagePath,
        createdAt: existing?.createdAt ?? DateTime.now(),
      );

      if (existing == null) {
        await ctrl.addMeal(meal);
      } else {
        await ctrl.updateMeal(meal);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final showExistingPhoto =
        !_removeImage && (widget.existing?.imageUrl != null && widget.existing!.imageUrl!.isNotEmpty);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit meal' : 'Log meal'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SectionHeader(title: 'Status'),
          MealStatusSelector(
            value: _status,
            onChanged: (s) => setState(() => _status = s),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Meal name'),
          TextField(
            controller: _mealNameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec(context, label: 'Name', hint: 'e.g. Grilled salmon & rice'),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Meal type'),
          MealTypeSelector(
            value: _mealType,
            onChanged: (t) => setState(() => _mealType = t),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'When'),
          MealDateTimePickerTile(
            value: _loggedAt,
            onChanged: (d) => setState(() => _loggedAt = d),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Photo'),
          MealPhotoPickerField(
            existingImageUrl: showExistingPhoto ? widget.existing!.imageUrl : null,
            previewBytes: _newImageBytes,
            onPick: _onImagePicked,
            onClear: _onImageClear,
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Description'),
          TextField(
            controller: _descriptionController,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec(
              context,
              label: 'Notes (optional)',
              hint: 'Ingredients, portion, how you felt…',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: isEdit ? 'Save changes' : 'Save meal',
            isLoading: _saving,
            icon: Icons.check_rounded,
            onPressed: _saving ? null : _submit,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
