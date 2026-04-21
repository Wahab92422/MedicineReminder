import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../appointments/appointment_entry.dart';
import '../appointments/appointment_repository.dart';
import '../meals/meal_entry.dart';
import '../meals/meal_repository.dart';
import '../medicine_logs/medicine_log_entry.dart';
import '../medicine_logs/medicine_log_repository.dart';
import 'unified_schedule_item.dart';
import 'user_schedule_reminder.dart';
import 'user_schedule_reminder_repository.dart';

final _appointmentRepositoryProvider = Provider<AppointmentRepository>(
  (_) => AppointmentRepository(),
);

final _mealRepositoryProvider = Provider<MealRepository>(
  (_) => MealRepository(),
);

final _medicineLogRepositoryProvider = Provider<MedicineLogRepository>(
  (_) => MedicineLogRepository(),
);

final userScheduleReminderRepositoryProvider =
    Provider<UserScheduleReminderRepository>(
  (_) => UserScheduleReminderRepository(),
);

/// First day of month \[year-month-01\] as key; loads all agenda data for that month.
final scheduleMonthDataProvider =
    FutureProvider.autoDispose.family<List<UnifiedScheduleItem>, DateTime>((
      ref,
      monthFirst,
    ) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return [];

      final start = DateTime(monthFirst.year, monthFirst.month, 1);
      final end = DateTime(
        monthFirst.year,
        monthFirst.month + 1,
        0,
        23,
        59,
        59,
        999,
      );

      final appointments = ref.read(_appointmentRepositoryProvider);
      final meals = ref.read(_mealRepositoryProvider);
      final logs = ref.read(_medicineLogRepositoryProvider);
      final reminders = ref.read(userScheduleReminderRepositoryProvider);

      final results = await Future.wait([
        appointments.getAppointmentsScheduledBetween(
          userId: uid,
          start: start,
          end: end,
        ),
        meals.getMealsBetween(userId: uid, start: start, end: end),
        logs.getLogsBetween(userId: uid, start: start, end: end),
        reminders.getRemindersBetween(userId: uid, start: start, end: end),
      ]);

      return mergeScheduleItems(
        appointments: results[0] as List<AppointmentEntry>,
        meals: results[1] as List<MealEntry>,
        medicineLogs: results[2] as List<MedicineLogEntry>,
        userReminders: results[3] as List<UserScheduleReminder>,
      );
    });
