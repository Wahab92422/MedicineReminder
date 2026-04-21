import '../features/appointments/appointment_entry.dart';
import '../features/appointments/appointment_statuses.dart';
import 'notification_service.dart';

class AppointmentNotificationHelper {
  static final AppointmentNotificationHelper _instance =
      AppointmentNotificationHelper._internal();
  factory AppointmentNotificationHelper() => _instance;
  AppointmentNotificationHelper._internal();

  final NotificationService _notificationService = NotificationService();

  static int stableNotificationId(String appointmentId) {
    return appointmentId.hashCode & 0x7fffffff;
  }

  /// Cancels any scheduled reminder, then schedules if status is scheduled and in the future.
  Future<void> syncReminderForEntry(AppointmentEntry entry) async {
    final notificationId = stableNotificationId(entry.id);
    await _notificationService.cancelNotification(notificationId);

    if (entry.status != AppointmentStatuses.scheduled) return;
    if (!entry.scheduledAt.isAfter(DateTime.now())) return;

    await _notificationService.ensureNotificationPermissions();
    await _notificationService.scheduleAppointmentReminder(
      appointmentId: entry.id,
      visitTitle: entry.title,
      scheduledAt: entry.scheduledAt,
      notificationId: notificationId,
      doctorName: entry.doctor,
      location: entry.location,
    );
  }

  Future<void> cancelReminder(String appointmentId) async {
    await _notificationService.cancelNotification(
      stableNotificationId(appointmentId),
    );
  }
}
