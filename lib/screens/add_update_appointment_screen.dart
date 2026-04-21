import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/appointments/appointment_entry.dart';
import '../features/appointments/appointment_providers.dart';
import '../features/appointments/appointment_statuses.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_screen_header.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/date_picker_field.dart';
import '../widgets/primary_button.dart';

class AddUpdateAppointmentScreen extends ConsumerStatefulWidget {
  const AddUpdateAppointmentScreen({
    super.key,
    this.existing,
    this.initialScheduledAt,
    this.initialTitle,
    this.initialNotes,
    this.lockStatusToScheduled = false,
  });

  final AppointmentEntry? existing;
  final DateTime? initialScheduledAt;
  final String? initialTitle;
  final String? initialNotes;
  final bool lockStatusToScheduled;

  @override
  ConsumerState<AddUpdateAppointmentScreen> createState() =>
      _AddUpdateAppointmentScreenState();
}

class _AddUpdateAppointmentScreenState
    extends ConsumerState<AddUpdateAppointmentScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _doctorController;
  late final TextEditingController _locationController;
  late final TextEditingController _notesController;

  DateTime? _scheduledAt;
  String? _status;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _doctorController = TextEditingController();
    _locationController = TextEditingController();
    _notesController = TextEditingController();

    final e = widget.existing;
    if (e != null) {
      _titleController.text = e.title;
      _doctorController.text = e.doctor;
      _locationController.text = e.location;
      _notesController.text = e.notes;
      _scheduledAt = e.scheduledAt;
      _status = e.status;
    } else {
      _scheduledAt =
          widget.initialScheduledAt ?? DateTime.now().add(const Duration(hours: 1));
      _status = AppointmentStatuses.scheduled;
      if (widget.initialTitle != null && widget.initialTitle!.isNotEmpty) {
        _titleController.text = widget.initialTitle!;
      }
      if (widget.initialNotes != null && widget.initialNotes!.isNotEmpty) {
        _notesController.text = widget.initialNotes!;
      }
      if (widget.lockStatusToScheduled) {
        _status = AppointmentStatuses.scheduled;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _doctorController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a title for this appointment.')),
      );
      return;
    }

    if (_scheduledAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select date and time.')),
      );
      return;
    }

    if (_status == null || _status!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a status.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);

    try {
      final repo = ref.read(appointmentRepositoryProvider);
      final now = DateTime.now();
      final entryId =
          widget.existing?.id ?? repo.allocateAppointmentId(user.uid);

      final entry = AppointmentEntry(
        id: entryId,
        title: title,
        scheduledAt: _scheduledAt!,
        status: _status!,
        notes: _notesController.text.trim(),
        location: _locationController.text.trim(),
        doctor: _doctorController.text.trim(),
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
                      ? 'Could not update appointment.'
                      : 'Could not save appointment.'),
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
                : (_isEdit
                    ? 'Appointment updated.'
                    : 'Appointment saved.'),
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
        title: _isEdit ? 'Edit appointment' : 'Add appointment',
        subtitle: _isEdit
            ? 'Update visit details or status. Scheduled future visits can remind you at the scheduled time.'
            : 'Log a past or upcoming visit for your records—not booking with a provider. Scheduled visits can get a local reminder.',
        icon: _isEdit ? Icons.edit_note_outlined : Icons.event_available_rounded,
      ),
      body: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              CustomTextField(
                controller: _titleController,
                label: 'Title',
                hint: 'e.g. Cardiology follow-up, Annual checkup',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              DatePickerField(
                label: 'Date and time',
                value: _scheduledAt,
                includeTime: true,
                onDateSelected: (d) => setState(() => _scheduledAt = d),
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                controller: _doctorController,
                label: 'Doctor (optional)',
                hint: 'e.g. Dr. Smith',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              CustomDropdown<String>(
                label: 'Status',
                value: _status,
                items: AppointmentStatuses.all
                    .map(
                      (s) => DropdownMenuItem(value: s, child: Text(s)),
                    )
                    .toList(),
                enabled: !(widget.lockStatusToScheduled && !_isEdit),
                onChanged: (v) => setState(() => _status = v),
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                controller: _locationController,
                label: 'Location (optional)',
                hint: 'e.g. City Clinic, Video call',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                controller: _notesController,
                label: 'Notes',
                hint: 'Any details you want to remember',
                maxLines: 3,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: _isEdit ? 'Update appointment' : 'Save appointment',
                icon: Icons.check_rounded,
                isLoading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
    );
  }
}
