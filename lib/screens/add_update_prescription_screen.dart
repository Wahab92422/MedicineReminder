import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/labs/lab_report.dart' show LabAttachment;
import '../features/prescriptions/prescription.dart';
import '../features/prescriptions/prescription_providers.dart';
import '../features/prescriptions/prescription_types.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/date_picker_field.dart';
import '../widgets/lab_attachment_picker.dart';
import '../widgets/primary_button.dart';
import '../widgets/speech_text_field.dart';

/// Create or edit a prescription record (Firestore + Storage).
class AddUpdatePrescriptionScreen extends ConsumerStatefulWidget {
  const AddUpdatePrescriptionScreen({super.key, this.existing});

  final Prescription? existing;

  @override
  ConsumerState<AddUpdatePrescriptionScreen> createState() =>
      _AddUpdatePrescriptionScreenState();
}

class _AddUpdatePrescriptionScreenState
    extends ConsumerState<AddUpdatePrescriptionScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _prescriptionType;
  DateTime? _prescribedDate;
  DateTime? _validUntil;
  final List<PickedAttachment> _newAttachments = [];
  late List<LabAttachment> _keptRemoteAttachments;
  final Set<String> _removedRemoteUrls = {};

  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleController.text = e.title;
      _descriptionController.text = e.description;
      _prescriptionType = e.prescriptionType;
      _prescribedDate = e.prescribedDate;
      _validUntil = e.validUntil;
      _keptRemoteAttachments = List.from(e.attachments);
    } else {
      _prescriptionType = PrescriptionTypes.all.first;
      final n = DateTime.now();
      _prescribedDate = n;
      _validUntil = n;
      _keptRemoteAttachments = const [];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a title (e.g. medication name).')),
      );
      return;
    }
    if (_prescriptionType == null || _prescriptionType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a prescription type.')),
      );
      return;
    }
    if (_prescribedDate == null || _validUntil == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select prescribed date and valid-until date.'),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(prescriptionRepositoryProvider);
      final uid = user.uid;

      final prescriptionId =
          widget.existing?.id ?? repo.allocatePrescriptionId(uid);

      final remoteKept = _keptRemoteAttachments
          .where((a) => !_removedRemoteUrls.contains(a.url))
          .toList();

      final uploaded = <LabAttachment>[];
      for (final p in _newAttachments) {
        final url = await repo.uploadAttachment(
          userId: uid,
          prescriptionId: prescriptionId,
          originalFileName: p.displayName,
          bytes: p.bytes,
          contentType: p.mimeType,
        );
        uploaded.add(LabAttachment(url: url, type: p.mimeType));
      }

      final attachments = [...remoteKept, ...uploaded];
      final now = DateTime.now();

      final prescription = Prescription(
        id: prescriptionId,
        prescriptionType: _prescriptionType!,
        title: title,
        description: _descriptionController.text.trim(),
        prescribedDate: _prescribedDate!,
        validUntil: _validUntil!,
        attachments: attachments,
        createdAt: widget.existing?.createdAt ?? now,
        updatedAt: now,
      );

      for (final url in _removedRemoteUrls) {
        await repo.deleteStoredFile(url);
      }
      final result = _isEdit
          ? await repo.updatePrescription(
              userId: uid,
              prescription: prescription,
            )
          : await repo.createPrescription(
              userId: uid,
              prescription: prescription,
            );

      if (!result.success) {
        _showSaveFailure(
          result.errorMessage ??
              (_isEdit
                  ? 'Could not update prescription.'
                  : 'Could not save prescription.'),
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
                : (_isEdit ? 'Prescription updated.' : 'Prescription saved.'),
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

  void _showSaveFailure(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppScreenHeader(
        title: _isEdit ? 'Edit prescription' : 'Add prescription',
        subtitle: _isEdit
            ? 'Update details, dates, or attachments.'
            : 'Store a prescription with dates and optional files.',
        icon: _isEdit ? Icons.edit_document : Icons.note_add_outlined,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              CustomDropdown<String>(
                label: 'Prescription type',
                value: _prescriptionType,
                items: PrescriptionTypes.all
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _prescriptionType = v),
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                controller: _titleController,
                label: 'Title',
                hint: 'Medication or label',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              SpeechTextField(
                controller: _descriptionController,
                label: 'Notes',
                maxLines: 4,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: AppSpacing.md),
              DatePickerField(
                label: 'Prescribed date',
                value: _prescribedDate,
                includeTime: true,
                onDateSelected: (d) => setState(() => _prescribedDate = d),
              ),
              const SizedBox(height: AppSpacing.md),
              DatePickerField(
                label: 'Valid until',
                value: _validUntil,
                includeTime: true,
                onDateSelected: (d) => setState(() => _validUntil = d),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Attachments',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_keptRemoteAttachments.any(
                (a) => !_removedRemoteUrls.contains(a.url),
              ))
                ..._keptRemoteAttachments
                    .where((a) => !_removedRemoteUrls.contains(a.url))
                    .map(
                      (a) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.cloud_done_outlined),
                        title: Text(
                          a.url.split('%2F').last.split('?').first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          a.type,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () =>
                              setState(() => _removedRemoteUrls.add(a.url)),
                        ),
                      ),
                    ),
              LabAttachmentPicker(
                attachments: _newAttachments,
                onChanged: (list) => setState(() {
                  _newAttachments
                    ..clear()
                    ..addAll(list);
                }),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: _isEdit ? 'Update prescription' : 'Save prescription',
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
