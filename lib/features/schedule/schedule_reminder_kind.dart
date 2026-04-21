/// User-created schedule reminder category (stored as string in Firestore).
enum ScheduleReminderKind {
  meal,
  medicine,
  appointment,
  general,
}

extension ScheduleReminderKindX on ScheduleReminderKind {
  String get wireValue {
    switch (this) {
      case ScheduleReminderKind.meal:
        return 'meal';
      case ScheduleReminderKind.medicine:
        return 'medicine';
      case ScheduleReminderKind.appointment:
        return 'appointment';
      case ScheduleReminderKind.general:
        return 'general';
    }
  }

  String get label {
    switch (this) {
      case ScheduleReminderKind.meal:
        return 'Meal';
      case ScheduleReminderKind.medicine:
        return 'Medicine';
      case ScheduleReminderKind.appointment:
        return 'Appointment';
      case ScheduleReminderKind.general:
        return 'General';
    }
  }
}

ScheduleReminderKind? parseScheduleReminderKind(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  for (final v in ScheduleReminderKind.values) {
    if (v.wireValue == raw) return v;
  }
  return null;
}
