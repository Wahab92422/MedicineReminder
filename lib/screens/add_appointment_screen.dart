import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/appointments/appointment_model.dart';
import '../features/appointments/appointment_providers.dart';
import '../theme/app_spacing.dart';
import '../widgets/meal_datetime_picker_tile.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_header.dart';

class AddAppointmentScreen extends ConsumerStatefulWidget {
  const AddAppointmentScreen({super.key, this.existing});

  final AppointmentRecord? existing;

  @override
  ConsumerState<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends ConsumerState<AddAppointmentScreen> {
  final _titleController = TextEditingController();
  final _doctorController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _scheduledAt;
  late AppointmentStatus _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleController.text = e.title;
      _doctorController.text = e.doctorName;
      _locationController.text = e.location;
      _notesController.text = e.notes;
      _scheduledAt = e.scheduledAt;
      _status = e.status;
    } else {
      _scheduledAt = DateTime.now().add(const Duration(hours: 1));
      _status = AppointmentStatus.scheduled;
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

  InputDecoration _dec(BuildContext context, {String? label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
    ).applyDefaults(Theme.of(context).inputDecorationTheme);
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final title = _titleController.text.trim();
    final doctor = _doctorController.text.trim();
    final location = _locationController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a title or reason for the visit.')),
      );
      return;
    }
    if (doctor.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the doctor or provider name.')),
      );
      return;
    }
    if (location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter where the appointment takes place.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final ctrl = ref.read(appointmentControllerProvider);
      final existing = widget.existing;
      final now = DateTime.now();

      final rec = AppointmentRecord(
        id: existing?.id ?? '',
        userId: user.uid,
        title: title,
        doctorName: doctor,
        location: location,
        scheduledAt: _scheduledAt,
        status: widget.existing == null ? AppointmentStatus.scheduled : _status,
        notes: _notesController.text.trim(),
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );

      if (existing == null) {
        await ctrl.add(rec);
      } else {
        await ctrl.update(rec);
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
    final isEdit = widget.existing != null;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit appointment' : 'Schedule appointment'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SectionHeader(title: 'Visit'),
          TextField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec(
              context,
              label: 'Title / reason',
              hint: 'e.g. Annual physical, cardiology follow-up',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'When'),
          MealDateTimePickerTile(
            value: _scheduledAt,
            title: 'Date & time',
            onChanged: (d) => setState(() => _scheduledAt = d),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Provider & location'),
          TextField(
            controller: _doctorController,
            textCapitalization: TextCapitalization.words,
            decoration: _dec(
              context,
              label: 'Doctor or provider',
              hint: 'e.g. Dr. Jane Lee',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _locationController,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec(
              context,
              label: 'Where',
              hint: 'Clinic name, floor, or address',
            ),
          ),
          if (isEdit) ...[
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader(title: 'Status'),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<AppointmentStatus>(
                segments: const [
                  ButtonSegment(
                    value: AppointmentStatus.scheduled,
                    label: Text('Scheduled'),
                    icon: Icon(Icons.event_note_outlined),
                  ),
                  ButtonSegment(
                    value: AppointmentStatus.attended,
                    label: Text('Attended'),
                    icon: Icon(Icons.check_circle_outline_rounded),
                  ),
                  ButtonSegment(
                    value: AppointmentStatus.missed,
                    label: Text('Missed'),
                    icon: Icon(Icons.event_busy_rounded),
                  ),
                ],
                selected: {_status},
                onSelectionChanged: (s) {
                  if (s.isNotEmpty) setState(() => _status = s.first);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Adjust if you marked the wrong outcome from the list.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Notes (optional)'),
          TextField(
            controller: _notesController,
            minLines: 3,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec(
              context,
              label: 'Reminder details',
              hint: 'Parking, documents to bring, telehealth link…',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: isEdit ? 'Save changes' : 'Save appointment',
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
