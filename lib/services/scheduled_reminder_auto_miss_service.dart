import '../features/appointments/appointment_entry.dart';
import '../features/appointments/appointment_repository.dart';
import '../features/appointments/appointment_statuses.dart';
import '../features/meals/meal_entry.dart';
import '../features/meals/meal_repository.dart';
import '../features/meals/meal_statuses.dart';
import '../features/medicine_logs/medicine_log_entry.dart';
import '../features/medicine_logs/medicine_log_repository.dart';
import '../features/schedule/user_schedule_reminder_repository.dart';

/// If a scheduled reminder time is more than [gracePastScheduled] in the past,
/// status is set to missed (or agenda [reminderOutcome] `missed`).
class ScheduledReminderAutoMissService {
  ScheduledReminderAutoMissService({
    MealRepository? mealRepository,
    AppointmentRepository? appointmentRepository,
    MedicineLogRepository? medicineLogRepository,
    UserScheduleReminderRepository? userScheduleReminderRepository,
  }) : _meals = mealRepository ?? MealRepository(),
       _appointments = appointmentRepository ?? AppointmentRepository(),
       _logs = medicineLogRepository ?? MedicineLogRepository(),
       _userReminders =
           userScheduleReminderRepository ?? UserScheduleReminderRepository();

  final MealRepository _meals;
  final AppointmentRepository _appointments;
  final MedicineLogRepository _logs;
  final UserScheduleReminderRepository _userReminders;

  /// Scheduled items older than this relative to [DateTime.now] are marked missed.
  static const Duration gracePastScheduled = Duration(hours: 12);

  /// Applies auto-miss rules for the signed-in user's data. Safe to call often.
  Future<void> applyForUser(String userId) async {
    if (userId.isEmpty) return;
    final cutoff = DateTime.now().subtract(gracePastScheduled);

    await Future.wait([
      _applyMeals(userId, cutoff),
      _applyAppointments(userId, cutoff),
      _applyMedicineLogs(userId, cutoff),
      _applyAgendaReminders(userId, cutoff),
    ]);
  }

  Future<void> _applyMeals(String userId, DateTime cutoff) async {
    final list = await _meals.listScheduledEntries(userId: userId);
    for (final e in list) {
      if (!e.mealAt.isBefore(cutoff)) continue;
      final updated = MealEntry(
        id: e.id,
        mealAt: e.mealAt,
        mealType: e.mealType,
        status: MealStatuses.missed,
        notes: e.notes,
        imageUrl: e.imageUrl,
        createdAt: e.createdAt,
        updatedAt: DateTime.now(),
      );
      await _meals.updateEntry(userId: userId, entry: updated);
    }
  }

  Future<void> _applyAppointments(String userId, DateTime cutoff) async {
    final list = await _appointments.listScheduledEntries(userId: userId);
    for (final e in list) {
      if (!e.scheduledAt.isBefore(cutoff)) continue;
      final updated = AppointmentEntry(
        id: e.id,
        title: e.title,
        scheduledAt: e.scheduledAt,
        status: AppointmentStatuses.missed,
        notes: e.notes,
        location: e.location,
        doctor: e.doctor,
        createdAt: e.createdAt,
        updatedAt: DateTime.now(),
      );
      await _appointments.updateEntry(userId: userId, entry: updated);
    }
  }

  Future<void> _applyMedicineLogs(String userId, DateTime cutoff) async {
    final list = await _logs.listScheduledEntries(userId: userId);
    for (final e in list) {
      if (!e.loggedAt.isBefore(cutoff)) continue;
      final updated = MedicineLogEntry(
        id: e.id,
        medicineId: e.medicineId,
        medicineName: e.medicineName,
        loggedAt: e.loggedAt,
        status: MealStatuses.missed,
        units: e.units,
        notes: e.notes,
        createdAt: e.createdAt,
        updatedAt: DateTime.now(),
      );
      await _logs.updateEntry(userId: userId, entry: updated, previous: e);
    }
  }

  Future<void> _applyAgendaReminders(String userId, DateTime cutoff) async {
    final list = await _userReminders.listOpenReminders(userId: userId);
    for (final r in list) {
      if (!r.scheduledAt.isBefore(cutoff)) continue;
      await _userReminders.setReminderOutcome(
        userId: userId,
        reminderId: r.id,
        outcome: 'missed',
      );
    }
  }
}
