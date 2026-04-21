import '../features/meals/meal_statuses.dart';
import '../features/medicine_logs/medicine_log_entry.dart';
import 'notification_service.dart';

/// Local notification when a dose log has status [MealStatuses.scheduled].
class MedicineLogReminderNotificationHelper {
  static final MedicineLogReminderNotificationHelper _instance =
      MedicineLogReminderNotificationHelper._internal();
  factory MedicineLogReminderNotificationHelper() => _instance;
  MedicineLogReminderNotificationHelper._internal();

  final NotificationService _notificationService = NotificationService();

  static int stableNotificationId(String logId) {
    return logId.hashCode & 0x7fffffff;
  }

  Future<void> syncReminderForEntry(MedicineLogEntry entry) async {
    final notificationId = stableNotificationId(entry.id);
    await _notificationService.cancelNotification(notificationId);

    if (entry.status != MealStatuses.scheduled) return;
    if (!entry.loggedAt.isAfter(DateTime.now())) return;

    final name = entry.medicineName.trim().isEmpty
        ? 'medicine'
        : entry.medicineName.trim();
    await _notificationService.ensureNotificationPermissions();
    await _notificationService.scheduleMedicineDoseScheduledReminder(
      logId: entry.id,
      medicineName: name,
      loggedAt: entry.loggedAt,
      notificationId: notificationId,
      extraDetail: entry.notes.trim().isEmpty ? null : entry.notes.trim(),
    );
  }

  Future<void> cancelReminder(String logId) async {
    await _notificationService.cancelNotification(stableNotificationId(logId));
  }
}
