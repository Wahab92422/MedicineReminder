import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/labs/lab_report.dart';
import '../features/labs/lab_report_providers.dart';
import '../features/labs/lab_report_types.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/date_picker_field.dart';
import '../widgets/lab_attachment_picker.dart';
import '../widgets/primary_button.dart';

/// Create or edit a lab report (Firestore + Storage).
class AddUpdateLabReportScreen extends ConsumerStatefulWidget {
  const AddUpdateLabReportScreen({super.key, this.existing});

  final LabReport? existing;

  @override
  ConsumerState<AddUpdateLabReportScreen> createState() =>
      _AddUpdateLabReportScreenState();
}

class _AddUpdateLabReportScreenState
    extends ConsumerState<AddUpdateLabReportScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _reportType;
  DateTime? _testDate;
  DateTime? _reportDate;
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
      _reportType = e.reportType;
      _testDate = e.testDate;
      _reportDate = e.reportDate;
      _keptRemoteAttachments = List.from(e.attachments);
    } else {
      _reportType = LabReportTypes.all.first;
      final n = DateTime.now();
      _testDate = n;
      _reportDate = n;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a report title.')));
      return;
    }
    if (_reportType == null || _reportType!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a report type.')));
      return;
    }
    if (_testDate == null || _reportDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select test and report dates.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(labReportRepositoryProvider);
      final uid = user.uid;

      final reportId = widget.existing?.id ?? repo.allocateReportId(uid);

      final remoteKept = _keptRemoteAttachments
          .where((a) => !_removedRemoteUrls.contains(a.url))
          .toList();

      final uploaded = <LabAttachment>[];
      for (final p in _newAttachments) {
        final url = await repo.uploadAttachment(
          userId: uid,
          reportId: reportId,
          originalFileName: p.displayName,
          bytes: p.bytes,
          contentType: p.mimeType,
        );
        uploaded.add(LabAttachment(url: url, type: p.mimeType));
      }

      final attachments = [...remoteKept, ...uploaded];
      final now = DateTime.now();

      final report = LabReport(
        id: reportId,
        reportType: _reportType!,
        title: title,
        description: _descriptionController.text.trim(),
        testDate: _testDate!,
        reportDate: _reportDate!,
        attachments: attachments,
        createdAt: widget.existing?.createdAt ?? now,
        updatedAt: now,
      );

      for (final url in _removedRemoteUrls) {
        await repo.deleteStoredFile(url);
      }
      final result = _isEdit
          ? await repo.updateReport(userId: uid, report: report)
          : await repo.createReport(userId: uid, report: report);

      if (!result.success) {
        _showSaveFailure(
          result.errorMessage ??
              (_isEdit ? 'Could not update report.' : 'Could not save report.'),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isQueuedForSync
                ? (_isEdit
                      ? 'Report updated locally. Sync will complete when connection recovers.'
                      : 'Report saved locally. Sync will complete when connection recovers.')
                : (_isEdit ? 'Report updated.' : 'Report saved.'),
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
        title: _isEdit ? 'Edit Lab Report' : 'Add Lab Report',
        subtitle: _isEdit
            ? 'Update report details, dates, or attachments.'
            : 'Store a new report with dates and supporting files.',
        icon: _isEdit ? Icons.edit_document : Icons.note_add_outlined,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              CustomDropdown<String>(
                label: 'Report type',
                value: _reportType,
                items: LabReportTypes.all
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _reportType = v),
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                controller: _titleController,
                label: 'Report title',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                controller: _descriptionController,
                label: 'Description',
                maxLines: 4,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: AppSpacing.md),
              DatePickerField(
                label: 'Test date',
                value: _testDate,
                includeTime: true,
                onDateSelected: (d) => setState(() => _testDate = d),
              ),
              const SizedBox(height: AppSpacing.md),
              DatePickerField(
                label: 'Report date',
                value: _reportDate,
                includeTime: true,
                onDateSelected: (d) => setState(() => _reportDate = d),
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
                label: _isEdit ? 'Update report' : 'Save report',
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
