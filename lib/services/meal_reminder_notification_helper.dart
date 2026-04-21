import '../features/meals/meal_entry.dart';
import '../features/meals/meal_statuses.dart';
import 'notification_service.dart';

/// Local notification when a meal has status [MealStatuses.scheduled].
class MealReminderNotificationHelper {
  static final MealReminderNotificationHelper _instance =
      MealReminderNotificationHelper._internal();
  factory MealReminderNotificationHelper() => _instance;
  MealReminderNotificationHelper._internal();

  final NotificationService _notificationService = NotificationService();

  static int stableNotificationId(String mealId) {
    return mealId.hashCode & 0x7fffffff;
  }

  Future<void> syncReminderForEntry(MealEntry entry) async {
    final notificationId = stableNotificationId(entry.id);
    await _notificationService.cancelNotification(notificationId);

    if (entry.status != MealStatuses.scheduled) return;
    if (!entry.mealAt.isAfter(DateTime.now())) return;

    final label = entry.mealType.trim().isEmpty ? 'meal' : entry.mealType.trim();
    await _notificationService.ensureNotificationPermissions();
    await _notificationService.scheduleMealScheduledReminder(
      mealId: entry.id,
      mealTypeLabel: label,
      mealAt: entry.mealAt,
      notificationId: notificationId,
      extraDetail: entry.notes.trim().isEmpty ? null : entry.notes.trim(),
    );
  }

  Future<void> cancelReminder(String mealId) async {
    await _notificationService.cancelNotification(stableNotificationId(mealId));
  }
}
