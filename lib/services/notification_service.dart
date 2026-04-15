import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Local notifications (daily medicine reminders). Requires [init] from [main].
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _androidChannelId = 'medicine_reminders';
  static const _androidChannelName = 'Medicine reminders';
  static const _androidChannelDescription =
      'Scheduled reminders to take your medicine';

  static Future<void> init() async {
    tz.initializeTimeZones();
    await _syncLocalTimeZone();

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _plugin.initialize(settings: initSettings);

    await _requestAndroidPermissions();
    await _requestIosPermissions();
  }

  static Future<void> _requestIosPermissions() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios == null) return;

    await ios.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> _syncLocalTimeZone() async {
    if (kIsWeb) {
      tz.setLocalLocation(tz.UTC);
      return;
    }
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    }
  }

  static Future<void> _requestAndroidPermissions() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.requestNotificationsPermission();
    await android.requestExactAlarmsPermission();
  }

  static NotificationDetails _details() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription: _androidChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Schedules a notification every day at the same clock as [firstScheduleLocal]
  /// (or [hour]/[minute] if [firstScheduleLocal] is null). The first fire is the
  /// next matching instant on or after [firstScheduleLocal]'s calendar day logic.
  static Future<void> scheduleDailyReminder({
    required int notificationId,
    required String title,
    required String body,
    required int hour,
    required int minute,
    DateTime? firstScheduleLocal,
  }) async {
    if (kIsWeb) return;

    final now = tz.TZDateTime.now(tz.local);
    late tz.TZDateTime scheduled;

    if (firstScheduleLocal != null) {
      final f = firstScheduleLocal;
      scheduled = tz.TZDateTime(
        tz.local,
        f.year,
        f.month,
        f.day,
        f.hour,
        f.minute,
      );
      while (!scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
    } else {
      scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (!scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
    }

    await _plugin.zonedSchedule(
      id: notificationId,
      scheduledDate: scheduled,
      notificationDetails: _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      title: title,
      body: body,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancel(int notificationId) async {
    await _plugin.cancel(id: notificationId);
  }

  /// Clears all pending scheduled notifications (e.g. on sign-out).
  static Future<void> cancelAllPendingNotifications() async {
    if (kIsWeb) return;
    await _plugin.cancelAllPendingNotifications();
  }

  /// Maps a Firestore medicine document id to a stable int notification id.
  static int notificationIdForMedicine(String medicineId) {
    final h = medicineId.hashCode & 0x7fffffff;
    return h == 0 ? 1 : h;
  }
}
