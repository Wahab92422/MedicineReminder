import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

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
    tz.setLocalLocation(tz.UTC);

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

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(lowStockChannel);
      await androidPlugin.createNotificationChannel(expiryChannel);
      await androidPlugin.createNotificationChannel(reminderChannel);
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
    }
  }

  /// Re-request OS notification permissions (same as test notification path).
  Future<void> ensureNotificationPermissions() => _requestPermissions();

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
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
        title: 'Medicine Low Stock Alert',
        body:
            '$medicineName is running low. Current stock: $currentQuantity (Threshold: $threshold)',
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
      title = 'Medicine Expired';
      body = '$medicineName has expired (Expired: $expiryDate)';
    } else if (daysUntilExpiry == 1) {
      title = 'Medicine Expires Tomorrow';
      body = '$medicineName expires tomorrow ($expiryDate)';
    } else {
      title = 'Medicine Expiring Soon';
      body = '$medicineName expires in $daysUntilExpiry days ($expiryDate)';
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
        title: 'Medicine Expiry Reminder',
        body:
            '$medicineName expires on ${expiryDate.toString().split(' ')[0]}. Please check and replace if needed.',
        scheduledDate: tz.TZDateTime.from(notificationTime, tz.local),
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint('Scheduled expiry reminder for $medicineName');
    } catch (e) {
      debugPrint('Failed to schedule expiry reminder: $e');
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

  /// Immediate banner on all platforms; re-requests OS permission where needed.
  Future<void> showTestNotification() async {
    await ensureNotificationPermissions();

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

    final id = DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);

    try {
      await _flutterLocalNotificationsPlugin.show(
        id: id,
        title: 'Test notification',
        body: 'If you see this, local notifications are working.',
        notificationDetails: notificationDetails,
        payload: 'test_notification',
      );
      debugPrint('Test notification show() completed (id=$id)');
    } catch (e, st) {
      debugPrint('Failed to show test notification: $e\n$st');
    }
  }
}
