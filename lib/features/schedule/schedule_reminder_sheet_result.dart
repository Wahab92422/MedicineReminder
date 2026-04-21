/// Result of [AddScheduleReminderSheet]: either a saved general reminder or
/// instructions to open a module screen with prefilled data.
sealed class ScheduleReminderSheetResult {}

/// General reminder was persisted (Firestore + notification).
final class ScheduleReminderGeneralSaved extends ScheduleReminderSheetResult {}

/// Navigate to add meal with scheduled status locked.
final class ScheduleReminderOpenMeal extends ScheduleReminderSheetResult {
  ScheduleReminderOpenMeal({
    required this.mealAt,
    required this.prefilledNotes,
  });

  final DateTime mealAt;
  final String prefilledNotes;
}

/// Navigate to add appointment with scheduled status locked.
final class ScheduleReminderOpenAppointment
    extends ScheduleReminderSheetResult {
  ScheduleReminderOpenAppointment({
    required this.scheduledAt,
    required this.prefilledNotes,
  });

  final DateTime scheduledAt;
  final String prefilledNotes;
}

/// Navigate to log medicine with scheduled status locked.
final class ScheduleReminderOpenMedicineLog
    extends ScheduleReminderSheetResult {
  ScheduleReminderOpenMedicineLog({
    required this.loggedAt,
    required this.prefilledNotes,
  });

  final DateTime loggedAt;
  final String prefilledNotes;
}
