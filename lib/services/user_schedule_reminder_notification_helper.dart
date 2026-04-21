import '../features/schedule/schedule_reminder_kind.dart';
import '../features/schedule/user_schedule_reminder.dart';
import 'notification_service.dart';

class UserScheduleReminderNotificationHelper {
  static final UserScheduleReminderNotificationHelper _instance =
      UserScheduleReminderNotificationHelper._internal();
  factory UserScheduleReminderNotificationHelper() => _instance;
  UserScheduleReminderNotificationHelper._internal();

  final NotificationService _notificationService = NotificationService();

  static int stableNotificationId(String reminderId) {
    return reminderId.hashCode & 0x7fffffff;
  }

  Future<void> syncReminder(UserScheduleReminder reminder) async {
    final notificationId = stableNotificationId(reminder.id);
    await _notificationService.cancelNotification(notificationId);
    if (!reminder.scheduledAt.isAfter(DateTime.now())) return;

    await _notificationService.ensureNotificationPermissions();
    await _notificationService.scheduleAgendaReminder(
      title: reminder.title,
      kindLabel: reminder.kind.label,
      scheduledAt: reminder.scheduledAt,
      notificationId: notificationId,
      notes: reminder.notes.isEmpty ? null : reminder.notes,
    );
  }

  Future<void> cancelReminder(String reminderId) async {
    await _notificationService.cancelNotification(
      stableNotificationId(reminderId),
    );
  }
}
