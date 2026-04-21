import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:medicine_app/app/app_navigator.dart';
import 'package:medicine_app/screens/medicine_inventory_screen.dart';
import 'package:medicine_app/screens/reminder_indicator_screen.dart';
import 'package:medicine_app/services/notification_android_schedule_mode.dart';
import 'package:medicine_app/services/notification_schedule_instant.dart';
import 'package:medicine_app/services/reminder_notification_payload.dart';
import 'package:medicine_app/utils/app_date_time_format.dart';
import 'package:timezone/data/latest.dart' as tzdata;

/// Local notifications (scheduled + immediate) for medicine alerts.
///
/// Android: do not reference `res/raw` sounds unless those files exist; missing
/// resources prevent notifications from appearing.
/// macOS: [InitializationSettings.macOS] and [NotificationDetails.macOS] are
/// required or the plugin never shows notifications on desktop.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Android: exact vs inexact; refreshed in [_requestPermissions].
  AndroidScheduleMode _androidReminderScheduleMode =
      AndroidScheduleMode.inexactAllowWhileIdle;

  /// Default banner/list presentation; no custom `.aiff` (files not bundled).
  static const DarwinNotificationDetails _darwinDefault =
      DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    presentBanner: true,
    presentList: true,
  );

  NotificationDetails _detailsWithDarwin({
    required AndroidNotificationDetails android,
  }) {
    return NotificationDetails(
      android: android,
      iOS: _darwinDefault,
      macOS: _darwinDefault,
    );
  }

  Future<void> initialize() async {
    tzdata.initializeTimeZones();

    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings darwinInitializationSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
      iOS: darwinInitializationSettings,
      macOS: darwinInitializationSettings,
    );

    final bool? initialized = await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    if (initialized == false) {
      debugPrint('Notification plugin reported initialization failure');
    }

    await _createNotificationChannels();
    await _requestPermissions();
  }

  Future<void> _createNotificationChannels() async {
    final AndroidNotificationChannel lowStockChannel =
        AndroidNotificationChannel(
      'medicine_low_stock_channel',
      'Medicine Low Stock',
      description: 'Notifications for medicines running low on stock',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
    );

    final AndroidNotificationChannel expiryChannel = AndroidNotificationChannel(
      'medicine_expiry_channel',
      'Medicine Expiry',
      description: 'Notifications for medicines nearing expiry',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
    );

    final AndroidNotificationChannel reminderChannel =
        AndroidNotificationChannel(
      'medicine_expiry_reminder_channel',
      'Medicine Expiry Reminder',
      description: 'Scheduled reminders for medicines nearing expiry',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: true,
      enableLights: false,
      vibrationPattern: Int64List.fromList([0, 200, 150, 200]),
    );

    final AndroidNotificationChannel appointmentChannel =
        AndroidNotificationChannel(
      'appointment_reminder_channel',
      'Appointment reminders',
      description: 'Scheduled reminders for your logged appointments',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
    );

    final AndroidNotificationChannel agendaChannel = AndroidNotificationChannel(
      'agenda_reminder_channel',
      'Schedule reminders',
      description:
          'Meal, medicine, appointment, and general reminders from Schedule',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
    );

    final AndroidNotificationChannel mealScheduledChannel =
        AndroidNotificationChannel(
      'meal_scheduled_reminder_channel',
      'Meal reminders',
      description: 'Alerts for meals you marked as scheduled',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
    );

    final AndroidNotificationChannel medicineDoseScheduledChannel =
        AndroidNotificationChannel(
      'medicine_dose_scheduled_channel',
      'Medicine dose reminders',
      description: 'Alerts for medicine doses you marked as scheduled',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(lowStockChannel);
      await androidPlugin.createNotificationChannel(expiryChannel);
      await androidPlugin.createNotificationChannel(reminderChannel);
      await androidPlugin.createNotificationChannel(appointmentChannel);
      await androidPlugin.createNotificationChannel(agendaChannel);
      await androidPlugin.createNotificationChannel(mealScheduledChannel);
      await androidPlugin.createNotificationChannel(medicineDoseScheduledChannel);
    }
  }

  Future<void> _requestPermissions() async {
    final IOSFlutterLocalNotificationsPlugin? iosPlugin =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
    }

    final MacOSFlutterLocalNotificationsPlugin? macPlugin =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin>();

    if (macPlugin != null) {
      await macPlugin.requestPermissions(alert: true, badge: true, sound: true);
    }

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      final bool? canExact =
          await androidPlugin.canScheduleExactNotifications();
      _androidReminderScheduleMode =
          androidReminderScheduleModeForExactAlarmPermission(canExact);
      if (kDebugMode && canExact != true) {
        debugPrint(
          'NotificationService: exact alarms not granted; scheduled reminders '
          'use inexact timing. Enable Alarms & reminders (or Alarms only) for '
          'this app in system settings for precise times.',
        );
      }
    }
  }

  /// Re-request OS notification permissions where supported.
  Future<void> ensureNotificationPermissions() => _requestPermissions();

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    final p = response.payload;
    debugPrint('Notification tapped: $p');
    if (p == null || p.isEmpty) return;
    _scheduleRouteFromPayload(p);
  }

  /// Cold start: user opened the app by tapping a notification.
  Future<void> handlePendingLaunchNotification() async {
    final details =
        await _flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return;
    final p = details!.notificationResponse?.payload;
    if (p == null || p.isEmpty) return;
    _scheduleRouteFromPayload(p);
  }

  /// Routes as soon as [appNavigatorKey] is mounted: microtask first (foreground
  /// taps), then post-frame retries (cold start / first frame).
  void _scheduleRouteFromPayload(String payload) {
    const maxFrames = 24;
    void attempt(int frameIndex) {
      final nav = appNavigatorKey.currentState;
      if (nav != null) {
        _routeFromPayload(payload);
        return;
      }
      if (frameIndex >= maxFrames) {
        debugPrint(
          'NotificationService: navigator not ready; dropping route for tap',
        );
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        attempt(frameIndex + 1);
      });
    }

    scheduleMicrotask(() => attempt(0));
  }

  void _routeFromPayload(String payload) {
    final parsed = ReminderNotificationPayload.tryParse(payload);
    if (parsed != null) {
      if (parsed.kind == ReminderPayloadKind.expiry) {
        appNavigatorKey.currentState?.push(
          MaterialPageRoute<void>(
            builder: (_) => const MedicineInventoryScreen(),
          ),
        );
        return;
      }
      appNavigatorKey.currentState?.push(
        MaterialPageRoute<void>(
          builder: (_) => ReminderIndicatorScreen(payload: parsed),
        ),
      );
      return;
    }

    // Immediate [show] notifications use string payloads, not JSON — still route.
    if (isLegacyInventoryBannerPayload(payload)) {
      appNavigatorKey.currentState?.push(
        MaterialPageRoute<void>(
          builder: (_) => const MedicineInventoryScreen(),
        ),
      );
    }
  }

  Future<void> showLowStockNotification({
    required String medicineName,
    required int currentQuantity,
    required int threshold,
  }) async {
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'medicine_low_stock_channel',
      'Medicine Low Stock',
      channelDescription:
          'Notifications for medicines running low on stock',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      icon: '@mipmap/ic_launcher',
      vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
    );

    final notificationDetails = _detailsWithDarwin(
      android: androidNotificationDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    try {
      await _flutterLocalNotificationsPlugin.show(
        id: id,
        title: 'Low stock: $medicineName',
        body:
            'You have $currentQuantity left. We will remind you again if stock reaches $threshold.',
        notificationDetails: notificationDetails,
        payload: 'low_stock_$medicineName',
      );
      debugPrint('Low stock notification shown for $medicineName');
    } catch (e) {
      debugPrint('Failed to show low stock notification: $e');
    }
  }

  Future<void> showExpiryNotification({
    required String medicineName,
    required String expiryDate,
    required int daysUntilExpiry,
  }) async {
    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'medicine_expiry_channel',
      'Medicine Expiry',
      channelDescription: 'Notifications for medicines nearing expiry',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      icon: '@mipmap/ic_launcher',
      vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
    );

    final notificationDetails = _detailsWithDarwin(
      android: androidNotificationDetails,
    );

    late final String title;
    late final String body;

    if (daysUntilExpiry <= 0) {
      title = 'Expired: $medicineName';
      body =
          'This item is past its expiry date ($expiryDate). Check with your clinician before using it.';
    } else if (daysUntilExpiry == 1) {
      title = 'Expires tomorrow: $medicineName';
      body = 'Expiry date on the label: $expiryDate. Plan a refill or replacement.';
    } else {
      title = 'Expiring in $daysUntilExpiry days: $medicineName';
      body =
          'Expiry date on the label: $expiryDate. Consider reordering so you do not run out.';
    }

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    try {
      await _flutterLocalNotificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: 'expiry_$medicineName',
      );
      debugPrint('Expiry notification shown for $medicineName');
    } catch (e) {
      debugPrint('Failed to show expiry notification: $e');
    }
  }

  Future<void> scheduleExpiryReminder({
    required String medicineName,
    required String medicineId,
    required DateTime expiryDate,
    required int notificationId,
  }) async {
    final notificationTime = expiryDate.subtract(const Duration(days: 7));

    if (notificationTime.isBefore(DateTime.now())) {
      debugPrint(
        'Skipping reminder for $medicineName - notification time is in the past',
      );
      return;
    }

    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'medicine_expiry_reminder_channel',
      'Medicine Expiry Reminder',
      channelDescription:
          'Scheduled reminders for medicines nearing expiry',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
      enableVibration: true,
      enableLights: false,
      icon: '@mipmap/ic_launcher',
      vibrationPattern: Int64List.fromList([0, 200, 150, 200]),
    );

    final notificationDetails = _detailsWithDarwin(
      android: androidNotificationDetails,
    );

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: notificationId,
        title: 'Expiry heads-up: $medicineName',
        body:
            'Expires on ${AppDateTimeFormat.formatDate(expiryDate.toLocal())}. '
            'Check your supply and plan a refill if needed.',
        scheduledDate: tzUtcInstantForSchedule(notificationTime),
        notificationDetails: notificationDetails,
        androidScheduleMode: _androidReminderScheduleMode,
        payload: ReminderNotificationPayload.encode(
          kind: ReminderPayloadKind.expiry,
          entityId: medicineId,
          scheduledAt: notificationTime,
        ),
      );
      debugPrint('Scheduled expiry reminder for $medicineName');
    } catch (e) {
      debugPrint('Failed to schedule expiry reminder: $e');
    }
  }

  /// Reminder at [scheduledAt] for a user-logged appointment (not external booking).
  Future<void> scheduleAppointmentReminder({
    required String appointmentId,
    required String visitTitle,
    required DateTime scheduledAt,
    required int notificationId,
    String? doctorName,
    String? location,
  }) async {
    if (!scheduledAt.isAfter(DateTime.now())) {
      debugPrint(
        'Skipping appointment reminder — scheduled time is not in the future',
      );
      return;
    }

    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'appointment_reminder_channel',
      'Appointment reminders',
      channelDescription: 'Scheduled reminders for your logged appointments',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      icon: '@mipmap/ic_launcher',
      vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
    );

    final notificationDetails = _detailsWithDarwin(
      android: androidNotificationDetails,
    );

    try {
      final when = _formatUserDateTime(scheduledAt);
      final buffer = StringBuffer()
        ..writeln('Time: $when');
      if (doctorName != null && doctorName.trim().isNotEmpty) {
        buffer.writeln('Provider: ${doctorName.trim()}');
      }
      if (location != null && location.trim().isNotEmpty) {
        buffer.writeln('Place: ${location.trim()}');
      }
      buffer.writeln();
      buffer.write('Tap to open the app and review this visit.');

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: notificationId,
        title: 'Appointment: $visitTitle',
        body: buffer.toString(),
        scheduledDate: tzUtcInstantForSchedule(scheduledAt),
        notificationDetails: notificationDetails,
        androidScheduleMode: _androidReminderScheduleMode,
        payload: ReminderNotificationPayload.encode(
          kind: ReminderPayloadKind.appointment,
          entityId: appointmentId,
          scheduledAt: scheduledAt,
        ),
      );
      debugPrint('Scheduled appointment reminder for $visitTitle');
    } catch (e) {
      debugPrint('Failed to schedule appointment reminder: $e');
    }
  }

  /// Scheduled [mealAt] when meal status is “Scheduled” (planned meal reminder).
  Future<void> scheduleMealScheduledReminder({
    required String mealId,
    required String mealTypeLabel,
    required DateTime mealAt,
    required int notificationId,
    String? extraDetail,
  }) async {
    if (!mealAt.isAfter(DateTime.now())) {
      debugPrint('Skipping meal reminder — time is not in the future');
      return;
    }

    final android = AndroidNotificationDetails(
      'meal_scheduled_reminder_channel',
      'Meal reminders',
      channelDescription: 'Alerts for meals you marked as scheduled',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      icon: '@mipmap/ic_launcher',
      vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
    );

    final when = _formatUserDateTime(mealAt);
    final detail = extraDetail != null && extraDetail.trim().isNotEmpty
        ? '\n\nNote: ${extraDetail.trim()}'
        : '';

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: notificationId,
        title: 'Meal: $mealTypeLabel',
        body:
            'Planned for $when.$detail\n\nOpen the app to log the meal or adjust the time.',
        scheduledDate: tzUtcInstantForSchedule(mealAt),
        notificationDetails: _detailsWithDarwin(android: android),
        androidScheduleMode: _androidReminderScheduleMode,
        payload: ReminderNotificationPayload.encode(
          kind: ReminderPayloadKind.meal,
          entityId: mealId,
          scheduledAt: mealAt,
        ),
      );
      debugPrint('Scheduled meal reminder for $mealTypeLabel');
    } catch (e) {
      debugPrint('Failed to schedule meal reminder: $e');
    }
  }

  /// Scheduled [loggedAt] when dose log status is “Scheduled”.
  Future<void> scheduleMedicineDoseScheduledReminder({
    required String logId,
    required String medicineName,
    required DateTime loggedAt,
    required int notificationId,
    String? extraDetail,
  }) async {
    if (!loggedAt.isAfter(DateTime.now())) {
      debugPrint('Skipping medicine dose reminder — time is not in the future');
      return;
    }

    final android = AndroidNotificationDetails(
      'medicine_dose_scheduled_channel',
      'Medicine dose reminders',
      channelDescription: 'Alerts for medicine doses you marked as scheduled',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      icon: '@mipmap/ic_launcher',
      vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
    );

    final when = _formatUserDateTime(loggedAt);
    final detail = extraDetail != null && extraDetail.trim().isNotEmpty
        ? '\n\nNote: ${extraDetail.trim()}'
        : '';

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: notificationId,
        title: 'Dose: $medicineName',
        body:
            'Scheduled around $when.$detail\n\nOpen the app to mark the dose as taken when you are ready.',
        scheduledDate: tzUtcInstantForSchedule(loggedAt),
        notificationDetails: _detailsWithDarwin(android: android),
        androidScheduleMode: _androidReminderScheduleMode,
        payload: ReminderNotificationPayload.encode(
          kind: ReminderPayloadKind.medicineLog,
          entityId: logId,
          scheduledAt: loggedAt,
        ),
      );
      debugPrint('Scheduled medicine dose reminder for $medicineName');
    } catch (e) {
      debugPrint('Failed to schedule medicine dose reminder: $e');
    }
  }

  String _formatUserDateTime(DateTime d) =>
      AppDateTimeFormat.formatDateTime(d);

  /// User-created reminders from the Schedule screen (general type only in UI).
  Future<void> scheduleAgendaReminder({
    required String reminderId,
    required String title,
    required String kindLabel,
    required DateTime scheduledAt,
    required int notificationId,
    String? notes,
  }) async {
    if (!scheduledAt.isAfter(DateTime.now())) {
      debugPrint(
        'Skipping agenda reminder — scheduled time is not in the future',
      );
      return;
    }

    final AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'agenda_reminder_channel',
      'Schedule reminders',
      channelDescription:
          'Meal, medicine, appointment, and general reminders from Schedule',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      icon: '@mipmap/ic_launcher',
      vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
    );

    final notificationDetails = _detailsWithDarwin(
      android: androidNotificationDetails,
    );

    try {
      final when = _formatUserDateTime(scheduledAt);
      final noteLine = notes != null && notes.trim().isNotEmpty
          ? '\n\nNote: ${notes.trim()}'
          : '';
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: notificationId,
        title: title,
        body:
            '$kindLabel · $when$noteLine\n\nOpen the app to view or change this reminder.',
        scheduledDate: tzUtcInstantForSchedule(scheduledAt),
        notificationDetails: notificationDetails,
        androidScheduleMode: _androidReminderScheduleMode,
        payload: ReminderNotificationPayload.encode(
          kind: ReminderPayloadKind.agenda,
          entityId: reminderId,
          scheduledAt: scheduledAt,
        ),
      );
      debugPrint('Scheduled agenda reminder: $title');
    } catch (e) {
      debugPrint('Failed to schedule agenda reminder: $e');
    }
  }

  Future<void> cancelNotification(int notificationId) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id: notificationId);
      debugPrint('Cancelled notification $notificationId');
    } catch (e) {
      debugPrint('Failed to cancel notification $notificationId: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('Cancelled all notifications');
    } catch (e) {
      debugPrint('Failed to cancel all notifications: $e');
    }
  }
}
