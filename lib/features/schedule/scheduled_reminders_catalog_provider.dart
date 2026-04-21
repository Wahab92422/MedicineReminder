import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/scheduled_reminder_auto_miss_service.dart'
    show ScheduledReminderAutoMissService;
import '../appointments/appointment_providers.dart';
import '../meals/meal_providers.dart';
import '../medicine_logs/medicine_log_providers.dart';
import 'schedule_providers.dart';

enum ScheduledReminderRowKind { meal, appointment, medicineLog, agenda }

class ScheduledReminderRow {
  const ScheduledReminderRow({
    required this.kind,
    required this.id,
    required this.title,
    required this.at,
    required this.statusLabel,
  });

  final ScheduledReminderRowKind kind;
  final String id;
  final String title;
  final DateTime at;
  final String statusLabel;
}

/// Scheduled (incomplete) meal, appointment, dose, and agenda reminders for the list UI.
final scheduledRemindersCatalogProvider =
    FutureProvider.autoDispose<List<ScheduledReminderRow>>((ref) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return [];

      await ScheduledReminderAutoMissService(
        mealRepository: ref.read(mealRepositoryProvider),
        appointmentRepository: ref.read(appointmentRepositoryProvider),
        medicineLogRepository: ref.read(medicineLogRepositoryProvider),
        userScheduleReminderRepository: ref.read(
          userScheduleReminderRepositoryProvider,
        ),
      ).applyForUser(uid);

      final meals = await ref
          .read(mealRepositoryProvider)
          .listScheduledEntries(userId: uid);
      final appts = await ref
          .read(appointmentRepositoryProvider)
          .listScheduledEntries(userId: uid);
      final logs = await ref
          .read(medicineLogRepositoryProvider)
          .listScheduledEntries(userId: uid);
      final agenda = await ref
          .read(userScheduleReminderRepositoryProvider)
          .listOpenReminders(userId: uid);

      final rows = <ScheduledReminderRow>[
        for (final e in meals)
          ScheduledReminderRow(
            kind: ScheduledReminderRowKind.meal,
            id: e.id,
            title: e.mealType.isEmpty ? 'Meal' : e.mealType,
            at: e.mealAt,
            statusLabel: e.status,
          ),
        for (final e in appts)
          ScheduledReminderRow(
            kind: ScheduledReminderRowKind.appointment,
            id: e.id,
            title: e.title.isEmpty ? 'Appointment' : e.title,
            at: e.scheduledAt,
            statusLabel: e.status,
          ),
        for (final e in logs)
          ScheduledReminderRow(
            kind: ScheduledReminderRowKind.medicineLog,
            id: e.id,
            title: e.medicineName.isEmpty ? 'Medicine dose' : e.medicineName,
            at: e.loggedAt,
            statusLabel: e.status,
          ),
        for (final r in agenda)
          ScheduledReminderRow(
            kind: ScheduledReminderRowKind.agenda,
            id: r.id,
            title: r.title.isEmpty ? 'Reminder' : r.title,
            at: r.scheduledAt,
            statusLabel: 'Scheduled',
          ),
      ];

      rows.sort((a, b) => a.at.compareTo(b.at));

      final now = DateTime.now();
      final windowStart = now.subtract(
        ScheduledReminderAutoMissService.gracePastScheduled,
      );
      final inWindow = rows.where((r) => !r.at.isBefore(windowStart)).toList();
      return inWindow;
    });
