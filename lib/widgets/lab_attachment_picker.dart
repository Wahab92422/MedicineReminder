import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../theme/app_spacing.dart';

/// Local file picked for upload (not yet on Storage).
class PickedAttachment {
  PickedAttachment({
    required this.id,
    required this.displayName,
    required this.mimeType,
    required this.bytes,
  });

  final String id;
  final String displayName;
  final String mimeType;
  final Uint8List bytes;
}

/// Camera / gallery / documents picker; supports multiple files from documents.
class LabAttachmentPicker extends StatelessWidget {
  const LabAttachmentPicker({
    super.key,
    required this.attachments,
    required this.onChanged,
  });

  final List<PickedAttachment> attachments;
  final ValueChanged<List<PickedAttachment>> onChanged;

  Future<void> _addFromCamera(BuildContext context) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (x == null) return;
    final bytes = await x.readAsBytes();
    final mime = lookupMimeType(x.path, headerBytes: bytes) ?? 'image/jpeg';
    _append(
      PickedAttachment(
        id: UniqueKey().toString(),
        displayName: x.name,
        mimeType: mime,
        bytes: bytes,
      ),
    );
  }

  Future<void> _addFromGallery(BuildContext context) async {
    final picker = ImagePicker();
    final list = await picker.pickMultiImage(imageQuality: 85);
    if (list.isEmpty) return;
    final next = List<PickedAttachment>.from(attachments);
    for (final x in list) {
      final bytes = await x.readAsBytes();
      final mime = lookupMimeType(x.path, headerBytes: bytes) ?? 'image/jpeg';
      next.add(
        PickedAttachment(
          id: UniqueKey().toString(),
          displayName: x.name,
          mimeType: mime,
          bytes: bytes,
        ),
      );
    }
    onChanged(next);
  }

  Future<void> _addFromFiles() async {
    final res = await FilePicker.pickFiles(allowMultiple: true, withData: true);
    if (res == null || res.files.isEmpty) return;
    final next = List<PickedAttachment>.from(attachments);
    for (final f in res.files) {
      final bytes = f.bytes;
      if (bytes == null || bytes.isEmpty) continue;
      final name = f.name;
      final mime =
          lookupMimeType(name, headerBytes: bytes) ??
          'application/octet-stream';
      next.add(
        PickedAttachment(
          id: UniqueKey().toString(),
          displayName: name,
          mimeType: mime,
          bytes: bytes,
        ),
      );
    }
    onChanged(next);
  }

  void _append(PickedAttachment p) {
    onChanged([...attachments, p]);
  }

  void _removeAt(int index) {
    final next = List<PickedAttachment>.from(attachments)..removeAt(index);
    onChanged(next);
  }

  Future<void> _showSourceSheet(BuildContext context) async {
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
                _addFromCamera(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _addFromGallery(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file_rounded),
              title: const Text('Documents'),
              onTap: () {
                Navigator.pop(ctx);
                _addFromFiles();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () => _showSourceSheet(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add attachment'),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (attachments.isEmpty)
          Text(
            'No attachments yet.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: attachments.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
            itemBuilder: (context, i) {
              final a = attachments[i];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text(
                  a.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  a.mimeType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => _removeAt(i),
                ),
              );
            },
          ),
      ],
    );
  }
}
