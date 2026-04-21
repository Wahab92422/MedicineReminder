import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/appointments/appointment_entry.dart';
import '../features/appointments/appointment_providers.dart';
import '../features/appointments/appointment_statuses.dart';
import '../features/meals/meal_entry.dart';
import '../features/meals/meal_providers.dart';
import '../features/meals/meal_statuses.dart';
import '../features/medicine_logs/medicine_log_entry.dart';
import '../features/medicine_logs/medicine_log_providers.dart';
import '../features/schedule/schedule_providers.dart';
import '../features/schedule/user_schedule_reminder.dart';
import '../services/appointment_notification_helper.dart';
import '../services/meal_reminder_notification_helper.dart';
import '../services/medicine_log_reminder_notification_helper.dart';
import '../services/reminder_notification_payload.dart';
import '../theme/app_spacing.dart';
import '../utils/app_date_time_format.dart';
import '../utils/reminder_response_window.dart';

/// Shown when the user taps a scheduled meal / appointment / dose / agenda OS notification.
/// Counts down the time left until the end of the post-schedule response window (same 12h
/// grace as auto-miss and the notifications list).
class ReminderIndicatorScreen extends ConsumerStatefulWidget {
  const ReminderIndicatorScreen({super.key, required this.payload});

  final ReminderNotificationPayload payload;

  @override
  ConsumerState<ReminderIndicatorScreen> createState() =>
      _ReminderIndicatorScreenState();
}

class _ReminderIndicatorScreenState
    extends ConsumerState<ReminderIndicatorScreen> {
  Timer? _timer;
  int _secondsLeft = 0;
  bool _busy = false;
  String? _loadError;

  MealEntry? _meal;
  AppointmentEntry? _appointment;
  MedicineLogEntry? _medicineLog;
  UserScheduleReminder? _agenda;

  @override
  void initState() {
    super.initState();
    _secondsLeft = secondsRemainingInReminderResponseWindow(
      scheduledAt: widget.payload.scheduledAt,
      now: DateTime.now(),
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsLeft = secondsRemainingInReminderResponseWindow(
          scheduledAt: widget.payload.scheduledAt,
          now: DateTime.now(),
        );
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loadError = 'Sign in required.');
      return;
    }
    final p = widget.payload;
    try {
      switch (p.kind) {
        case ReminderPayloadKind.meal:
          final e = await ref
              .read(mealRepositoryProvider)
              .getEntry(userId: uid, entryId: p.entityId);
          setState(() => _meal = e);
          break;
        case ReminderPayloadKind.appointment:
          final e = await ref
              .read(appointmentRepositoryProvider)
              .getEntry(userId: uid, entryId: p.entityId);
          setState(() => _appointment = e);
          break;
        case ReminderPayloadKind.medicineLog:
          final e = await ref
              .read(medicineLogRepositoryProvider)
              .getEntry(userId: uid, entryId: p.entityId);
          setState(() => _medicineLog = e);
          break;
        case ReminderPayloadKind.agenda:
          final r = await ref
              .read(userScheduleReminderRepositoryProvider)
              .getReminder(userId: uid, reminderId: p.entityId);
          setState(() => _agenda = r);
          break;
        case ReminderPayloadKind.expiry:
          setState(() {});
          break;
      }
    } catch (e) {
      setState(() => _loadError = e.toString());
    }
  }

  Future<void> _finish({required bool positive}) async {
    if (_busy) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _busy = true);
    try {
      final p = widget.payload;
      switch (p.kind) {
        case ReminderPayloadKind.meal:
          final e = _meal;
          if (e == null) throw StateError('Meal not found');
          final next = MealEntry(
            id: e.id,
            mealAt: e.mealAt,
            mealType: e.mealType,
            status: positive ? MealStatuses.taken : MealStatuses.missed,
            notes: e.notes,
            imageUrl: e.imageUrl,
            createdAt: e.createdAt,
            updatedAt: DateTime.now(),
          );
          await ref
              .read(mealRepositoryProvider)
              .updateEntry(userId: uid, entry: next);
          await MealReminderNotificationHelper().cancelReminder(e.id);
          break;
        case ReminderPayloadKind.appointment:
          final e = _appointment;
          if (e == null) throw StateError('Appointment not found');
          final next = AppointmentEntry(
            id: e.id,
            title: e.title,
            scheduledAt: e.scheduledAt,
            status: positive
                ? AppointmentStatuses.attended
                : AppointmentStatuses.missed,
            notes: e.notes,
            location: e.location,
            doctor: e.doctor,
            createdAt: e.createdAt,
            updatedAt: DateTime.now(),
          );
          await ref
              .read(appointmentRepositoryProvider)
              .updateEntry(userId: uid, entry: next);
          await AppointmentNotificationHelper().cancelReminder(e.id);
          break;
        case ReminderPayloadKind.medicineLog:
          final e = _medicineLog;
          if (e == null) throw StateError('Dose log not found');
          final next = MedicineLogEntry(
            id: e.id,
            medicineId: e.medicineId,
            medicineName: e.medicineName,
            loggedAt: e.loggedAt,
            status: positive ? MealStatuses.taken : MealStatuses.missed,
            units: e.units,
            notes: e.notes,
            createdAt: e.createdAt,
            updatedAt: DateTime.now(),
          );
          await ref
              .read(medicineLogRepositoryProvider)
              .updateEntry(userId: uid, entry: next, previous: e);
          await MedicineLogReminderNotificationHelper().cancelReminder(e.id);
          break;
        case ReminderPayloadKind.agenda:
          final r = _agenda;
          if (r == null) throw StateError('Reminder not found');
          await ref
              .read(userScheduleReminderRepositoryProvider)
              .setReminderOutcome(
                userId: uid,
                reminderId: r.id,
                outcome: positive ? 'completed' : 'missed',
              );
          break;
        case ReminderPayloadKind.expiry:
          break;
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(positive ? 'Saved.' : 'Marked as missed.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payload;
    final theme = Theme.of(context);
    final when = AppDateTimeFormat.formatDateTime(p.scheduledAt);

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reminder')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(_loadError!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final (
      String title,
      String subtitle,
      String posLabel,
      String negLabel,
    ) = switch (p.kind) {
      ReminderPayloadKind.meal => (
        'Meal reminder',
        _meal != null
            ? '${_meal!.mealType.isEmpty ? 'Meal' : _meal!.mealType} · $when'
            : 'Loading…',
        'Logged',
        'Missed',
      ),
      ReminderPayloadKind.appointment => (
        'Appointment reminder',
        _appointment != null
            ? '${_appointment!.title.isEmpty ? 'Visit' : _appointment!.title} · $when'
            : 'Loading…',
        'Attended',
        'Missed',
      ),
      ReminderPayloadKind.medicineLog => (
        'Medicine dose',
        _medicineLog != null
            ? '${_medicineLog!.medicineName} · $when'
            : 'Loading…',
        'Taken',
        'Missed',
      ),
      ReminderPayloadKind.agenda => (
        'Reminder',
        _agenda != null ? '${_agenda!.title} · $when' : 'Loading…',
        'Done',
        'Missed',
      ),
      ReminderPayloadKind.expiry => ('Reminder', when, '', ''),
    };

    if (p.kind == ReminderPayloadKind.expiry) {
      return const Scaffold(
        body: Center(child: Text('Use Inventory for expiry items.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reminder')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(subtitle, style: theme.textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Time left in response window',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                formatReminderResponseCountdown(_secondsLeft),
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Time left until the end of the 12-hour window after the scheduled time '
                '(matches auto-miss). Tap an action when ready.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: _busy ? null : () => _finish(positive: false),
                      child: Text(negLabel),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy ? null : () => _finish(positive: true),
                      child: Text(posLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
