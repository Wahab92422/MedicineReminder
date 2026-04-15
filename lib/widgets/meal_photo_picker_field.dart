import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_spacing.dart';

/// Optional meal photo: pick from camera or gallery, preview, clear.
class MealPhotoPickerField extends StatefulWidget {
  const MealPhotoPickerField({
    super.key,
    this.existingImageUrl,
    this.previewBytes,
    this.onPick,
    this.onClear,
  });

  /// Shown when no new [previewBytes] are set (e.g. editing an existing log).
  final String? existingImageUrl;

  /// In-memory preview after user picks a new image.
  final Uint8List? previewBytes;

  /// Called with the picked file after bytes are read (upload in parent).
  final ValueChanged<XFile>? onPick;

  /// User removed the image (new pick or existing).
  final VoidCallback? onClear;

  @override
  State<MealPhotoPickerField> createState() => _MealPhotoPickerFieldState();
}

class _MealPhotoPickerFieldState extends State<MealPhotoPickerField> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pick(ImageSource source) async {
    final x = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 88,
    );
    if (x == null || !mounted) return;
    widget.onPick?.call(x);
  }

  Future<void> _showSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pick(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasNew = widget.previewBytes != null && widget.previewBytes!.isNotEmpty;
    final hasExisting =
        !hasNew && widget.existingImageUrl != null && widget.existingImageUrl!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Material(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.45)),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _showSourceSheet,
              child: hasNew
                  ? Image.memory(
                      widget.previewBytes!,
                      fit: BoxFit.cover,
                    )
                  : hasExisting
                      ? Image.network(
                          widget.existingImageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (_, _, _) => _placeholder(context),
                        )
                      : _placeholder(context),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showSourceSheet,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                label: Text(hasNew || hasExisting ? 'Change photo' : 'Add photo (optional)'),
              ),
            ),
            if (hasNew || hasExisting) ...[
              const SizedBox(width: AppSpacing.sm),
              IconButton.filledTonal(
                tooltip: 'Remove photo',
                onPressed: widget.onClear,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _placeholder(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_rounded,
            size: 40,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tap to add a meal photo',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
