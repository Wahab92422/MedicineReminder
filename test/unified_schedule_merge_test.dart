import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/features/appointments/appointment_entry.dart';
import 'package:medicine_app/features/appointments/appointment_statuses.dart';
import 'package:medicine_app/features/meals/meal_entry.dart';
import 'package:medicine_app/features/meals/meal_statuses.dart';
import 'package:medicine_app/features/medicine_logs/medicine_log_entry.dart';
import 'package:medicine_app/features/schedule/schedule_reminder_kind.dart';
import 'package:medicine_app/features/schedule/unified_schedule_item.dart';
import 'package:medicine_app/features/schedule/user_schedule_reminder.dart';

void main() {
  test('mergeScheduleItems sorts by time across sources', () {
    final t0 = DateTime(2025, 6, 15, 9, 0);
    final t1 = DateTime(2025, 6, 15, 10, 0);
    final t15 = DateTime(2025, 6, 15, 10, 30);
    final t2 = DateTime(2025, 6, 15, 11, 0);

    final appointments = [
      AppointmentEntry(
        id: 'a1',
        title: 'Doc',
        scheduledAt: t2,
        status: AppointmentStatuses.scheduled,
        doctor: '',
        createdAt: t0,
        updatedAt: t0,
      ),
    ];
    final meals = [
      MealEntry(
        id: 'm1',
        mealAt: t0,
        mealType: 'Breakfast',
        status: MealStatuses.taken,
        createdAt: t0,
        updatedAt: t0,
      ),
    ];
    final logs = [
      MedicineLogEntry(
        id: 'l1',
        medicineId: 'med',
        medicineName: 'Aspirin',
        loggedAt: t1,
        status: MealStatuses.taken,
        units: 1,
        createdAt: t0,
        updatedAt: t0,
      ),
    ];
    final reminders = [
      UserScheduleReminder(
        id: 'r1',
        userId: 'u',
        title: 'Stretch',
        notes: '',
        scheduledAt: t15,
        kind: ScheduleReminderKind.general,
        createdAt: t0,
        updatedAt: t0,
      ),
    ];

    final merged = mergeScheduleItems(
      appointments: appointments,
      meals: meals,
      medicineLogs: logs,
      userReminders: reminders,
    );

    expect(merged.length, 4);
    expect(merged[0].source, UnifiedScheduleSource.meal);
    expect(merged[1].source, UnifiedScheduleSource.medicineLog);
    expect(merged[2].source, UnifiedScheduleSource.userReminder);
    expect(merged[3].source, UnifiedScheduleSource.appointment);
  });
}
