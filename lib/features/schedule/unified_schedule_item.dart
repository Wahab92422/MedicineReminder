import '../appointments/appointment_entry.dart';
import '../meals/meal_entry.dart';
import '../medicine_logs/medicine_log_entry.dart';
import 'schedule_reminder_kind.dart';
import 'user_schedule_reminder.dart';

/// Origin of an item shown on the Schedule calendar.
enum UnifiedScheduleSource { appointment, meal, medicineLog, userReminder }

/// Single row in the schedule list / calendar aggregation.
class UnifiedScheduleItem {
  const UnifiedScheduleItem._({
    required this.source,
    required this.at,
    required this.title,
    required this.subtitle,
    this.appointment,
    this.meal,
    this.medicineLog,
    this.userReminder,
  });

  factory UnifiedScheduleItem.fromAppointment(AppointmentEntry e) {
    return UnifiedScheduleItem._(
      source: UnifiedScheduleSource.appointment,
      at: e.scheduledAt,
      title: e.title.isEmpty ? 'Appointment' : e.title,
      subtitle: e.status.isEmpty ? 'Appointment' : e.status,
      appointment: e,
    );
  }

  factory UnifiedScheduleItem.fromMeal(MealEntry e) {
    return UnifiedScheduleItem._(
      source: UnifiedScheduleSource.meal,
      at: e.mealAt,
      title: e.mealType.isEmpty ? 'Meal' : e.mealType,
      subtitle: e.status.isEmpty ? 'Meal logged' : e.status,
      meal: e,
    );
  }

  factory UnifiedScheduleItem.fromMedicineLog(MedicineLogEntry e) {
    return UnifiedScheduleItem._(
      source: UnifiedScheduleSource.medicineLog,
      at: e.loggedAt,
      title: e.medicineName.isEmpty ? 'Medicine' : e.medicineName,
      subtitle: e.status.isEmpty ? 'Dose log' : e.status,
      medicineLog: e,
    );
  }

  factory UnifiedScheduleItem.fromUserReminder(UserScheduleReminder e) {
    return UnifiedScheduleItem._(
      source: UnifiedScheduleSource.userReminder,
      at: e.scheduledAt,
      title: e.title.isEmpty ? 'Reminder' : e.title,
      subtitle: e.kind.label,
      userReminder: e,
    );
  }

  final UnifiedScheduleSource source;
  final DateTime at;
  final String title;
  final String subtitle;

  final AppointmentEntry? appointment;
  final MealEntry? meal;
  final MedicineLogEntry? medicineLog;
  final UserScheduleReminder? userReminder;
}

/// Calendar date without time (local).
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Merges and sorts all entries for a month view.
List<UnifiedScheduleItem> mergeScheduleItems({
  required List<AppointmentEntry> appointments,
  required List<MealEntry> meals,
  required List<MedicineLogEntry> medicineLogs,
  required List<UserScheduleReminder> userReminders,
}) {
  final out = <UnifiedScheduleItem>[
    ...appointments.map(UnifiedScheduleItem.fromAppointment),
    ...meals.map(UnifiedScheduleItem.fromMeal),
    ...medicineLogs.map(UnifiedScheduleItem.fromMedicineLog),
    ...userReminders.map(UnifiedScheduleItem.fromUserReminder),
  ];
  out.sort((a, b) => a.at.compareTo(b.at));
  return out;
}
