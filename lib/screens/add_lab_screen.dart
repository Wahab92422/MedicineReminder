import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/labs/lab_controller.dart';
import '../features/labs/lab_model.dart';
import '../features/labs/lab_repository.dart';
import '../theme/app_spacing.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_header.dart';

class AddLabScreen extends ConsumerStatefulWidget {
  const AddLabScreen({super.key, this.existing});

  final LabReport? existing;

  @override
  ConsumerState<AddLabScreen> createState() => _AddLabScreenState();
}

class _AddLabScreenState extends ConsumerState<AddLabScreen> {
  final _reportNameController = TextEditingController();
  final _testNameController = TextEditingController();

  String? _reportType;
  DateTime? _testDate;
  DateTime? _resultDate;
  PickedLabFile? _picked;
  bool _saving = false;

  static const _reportTypes = <String>[
    'Blood',
    'MRI',
    'CT-Scan',
    'X-Ray',
    'Diabetes',
    'Urine',
    'Pathology',
    'Ultrasound',
    'ECG',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _reportNameController.text = e.reportName;
      _testNameController.text = e.testName;
      _reportType = e.reportType.isNotEmpty ? e.reportType : null;
      _testDate = e.testDate;
      _resultDate = e.resultDate;
    }
  }

  @override
  void dispose() {
    _reportNameController.dispose();
    _testNameController.dispose();
    super.dispose();
  }

  InputDecoration _dec(BuildContext context, {String? label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
    ).applyDefaults(Theme.of(context).inputDecorationTheme);
  }

  Future<void> _pickFile() async {
    final picked = await ref.read(labRepositoryProvider).pickFile();
    if (!mounted) return;
    setState(() => _picked = picked);
  }

  Future<void> _pickTestDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _testDate ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (d != null) setState(() => _testDate = d);
  }

  Future<void> _pickResultDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _resultDate ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (d != null) setState(() => _resultDate = d);
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final reportName = _reportNameController.text.trim();
    final testName = _testNameController.text.trim();
    if (reportName.isEmpty || testName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report name and test name are required.')),
      );
      return;
    }
    if (_reportType == null || _reportType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a report type.')),
      );
      return;
    }

    final existing = widget.existing;
    if (existing == null && _picked == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a file to upload.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(labRepositoryProvider);
      final ctrl = ref.read(labControllerProvider);

      if (existing != null) {
        if (_picked != null) {
          final upload = await repo.uploadFileToStorage(
            userId: user.uid,
            file: _picked!.file,
            originalFileName: _picked!.fileName,
            mimeType: _picked!.mimeType,
          );
          final oldUrl = existing.fileUrl;
          final updated = existing.copyWith(
            reportName: reportName,
            testName: testName,
            reportType: _reportType!,
            fileUrl: upload.downloadUrl,
            fileName: upload.fileName,
            fileExtension: upload.fileExtension,
            mimeType: upload.mimeType,
            fileSize: upload.fileSize,
            testDate: _testDate,
            resultDate: _resultDate,
          );
          await ctrl.updateLabReport(updated);
          await repo.deleteFileByUrl(oldUrl);
        } else {
          await ctrl.updateLabReport(
            existing.copyWith(
              reportName: reportName,
              testName: testName,
              reportType: _reportType!,
              testDate: _testDate,
              resultDate: _resultDate,
            ),
          );
        }
      } else {
        final p = _picked!;
        final upload = await repo.uploadFileToStorage(
          userId: user.uid,
          file: p.file,
          originalFileName: p.fileName,
          mimeType: p.mimeType,
        );
        final report = LabReport(
          id: '',
          userId: user.uid,
          reportName: reportName,
          testName: testName,
          reportType: _reportType!,
          fileUrl: upload.downloadUrl,
          fileName: upload.fileName,
          fileExtension: upload.fileExtension,
          mimeType: upload.mimeType,
          fileSize: upload.fileSize,
          testDate: _testDate,
          resultDate: _resultDate,
          createdAt: DateTime.now(),
        );
        await ctrl.addLabReport(report);
      }

      if (mounted) Navigator.of(context).pop();
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
    final scheme = Theme.of(context).colorScheme;
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit lab report' : 'Add lab report'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SectionHeader(title: 'Details'),
          TextField(
            controller: _reportNameController,
            decoration: _dec(context, label: 'Report name'),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _testNameController,
            decoration: _dec(context, label: 'Test name'),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppSpacing.md),
          InputDecorator(
            decoration: _dec(context, label: 'Report type'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Select type'),
                value: _reportType != null && _reportTypes.contains(_reportType)
                    ? _reportType
                    : null,
                items: _reportTypes
                    .map(
                      (t) => DropdownMenuItem(value: t, child: Text(t)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _reportType = v),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Dates'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Test date'),
            subtitle: Text(
              _testDate == null
                  ? 'Optional'
                  : '${_testDate!.year}-${_testDate!.month.toString().padLeft(2, '0')}-${_testDate!.day.toString().padLeft(2, '0')}',
            ),
            trailing: const Icon(Icons.calendar_today_rounded),
            onTap: _pickTestDate,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Result date'),
            subtitle: Text(
              _resultDate == null
                  ? 'Optional'
                  : '${_resultDate!.year}-${_resultDate!.month.toString().padLeft(2, '0')}-${_resultDate!.day.toString().padLeft(2, '0')}',
            ),
            trailing: const Icon(Icons.event_rounded),
            onTap: _pickResultDate,
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'File'),
          OutlinedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.attach_file_rounded),
            label: Text(
              _picked == null
                  ? (isEdit ? 'Replace file (optional)' : 'Choose file')
                  : _picked!.fileName,
            ),
          ),
          if (isEdit && _picked == null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'Current: ${widget.existing!.fileName}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: isEdit ? 'Update report' : 'Save report',
            icon: Icons.check_rounded,
            isLoading: _saving,
            onPressed: _saving ? null : _submit,
          ),
        ],
      ),
    );
  }
}
