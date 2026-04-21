import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../features/medicine_inventory/medicine_entry.dart';
import '../features/notifications/notification_model.dart';
import '../features/notifications/notification_repository.dart';
import '../services/notification_service.dart';

class MedicineNotificationHelper {
  static final MedicineNotificationHelper _instance =
      MedicineNotificationHelper._internal();
  factory MedicineNotificationHelper() => _instance;
  MedicineNotificationHelper._internal();

  final NotificationService _notificationService = NotificationService();
  final NotificationRepository _notificationRepository =
      NotificationRepository();

  static int _stableNotificationId(String medicineId) {
    return medicineId.hashCode & 0x7fffffff;
  }

  Future<void> checkAndCreateNotifications(
    List<MedicineEntry> medicines,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    debugPrint('Checking notifications for ${medicines.length} medicines');

    for (final medicine in medicines) {
      await _checkLowStockNotification(medicine, user.uid);
      await _checkExpiryNotification(medicine, user.uid);
    }
  }

  Future<void> _checkLowStockNotification(
    MedicineEntry medicine,
    String userId,
  ) async {
    if (!medicine.isLowStock) return;

    // Check if we already have a low stock notification for this medicine
    final existingNotifications = await _notificationRepository
        .getNotifications(userId: userId);

    final hasExistingLowStockNotification = existingNotifications.any(
      (n) =>
          n.medicineId == medicine.id &&
          n.type == NotificationType.lowStock &&
          n.isRead == false,
    );

    if (!hasExistingLowStockNotification) {
      debugPrint('Low stock alert for ${medicine.name}: showing OS notification');
      await _notificationService.ensureNotificationPermissions();
      await _notificationService.showLowStockNotification(
        medicineName: medicine.name,
        currentQuantity: medicine.quantity,
        threshold: medicine.lowStockThreshold,
      );

      try {
        final notificationId = _notificationRepository.allocateNotificationId(
          userId,
        );
        final notification = AppNotification(
          id: notificationId,
          userId: userId,
          type: NotificationType.lowStock,
          title: 'Medicine Low Stock Alert',
          message:
              '${medicine.name} is running low. Current stock: ${medicine.quantity} (Threshold: ${medicine.lowStockThreshold})',
          medicineId: medicine.id,
          medicineName: medicine.name,
          createdAt: DateTime.now(),
        );

        await _notificationRepository.createNotification(
          userId: userId,
          notification: notification,
        );
      } catch (e, st) {
        debugPrint(
          'Firestore createNotification (low stock) failed for ${medicine.name}: $e\n$st',
        );
      }
    }
  }

  Future<void> _checkExpiryNotification(
    MedicineEntry medicine,
    String userId,
  ) async {
    if (!medicine.isExpiringSoon && !medicine.isExpired) return;

    NotificationType notificationType;
    String title;
    String message;
    int daysUntilExpiry;

    if (medicine.isExpired) {
      notificationType = NotificationType.expired;
      title = 'Medicine Expired';
      message =
          '${medicine.name} has expired (${_formatDate(medicine.expiryDate)})';
      daysUntilExpiry = 0;
    } else {
      notificationType = NotificationType.expiringSoon;
      daysUntilExpiry = medicine.expiryDate.difference(DateTime.now()).inDays;
      if (daysUntilExpiry == 1) {
        title = 'Medicine Expires Tomorrow';
        message =
            '${medicine.name} expires tomorrow (${_formatDate(medicine.expiryDate)})';
      } else {
        title = 'Medicine Expiring Soon';
        message =
            '${medicine.name} expires in $daysUntilExpiry days (${_formatDate(medicine.expiryDate)})';
      }
    }

    // Check if we already have an expiry notification for this medicine
    final existingNotifications = await _notificationRepository
        .getNotifications(userId: userId);

    final hasExistingExpiryNotification = existingNotifications.any(
      (n) =>
          n.medicineId == medicine.id &&
          (n.type == NotificationType.expiringSoon ||
              n.type == NotificationType.expired) &&
          n.isRead == false,
    );

    if (!hasExistingExpiryNotification) {
      debugPrint('Expiry alert for ${medicine.name}: showing OS notification');
      await _notificationService.ensureNotificationPermissions();
      await _notificationService.showExpiryNotification(
        medicineName: medicine.name,
        expiryDate: _formatDate(medicine.expiryDate),
        daysUntilExpiry: daysUntilExpiry,
      );

      try {
        final notificationId = _notificationRepository.allocateNotificationId(
          userId,
        );
        final notification = AppNotification(
          id: notificationId,
          userId: userId,
          type: notificationType,
          title: title,
          message: message,
          medicineId: medicine.id,
          medicineName: medicine.name,
          createdAt: DateTime.now(),
        );

        await _notificationRepository.createNotification(
          userId: userId,
          notification: notification,
        );
      } catch (e, st) {
        debugPrint(
          'Firestore createNotification (expiry) failed for ${medicine.name}: $e\n$st',
        );
      }
    }
  }

  Future<void> scheduleExpiryReminder(MedicineEntry medicine) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final notificationId = _stableNotificationId(medicine.id);

    await _notificationService.scheduleExpiryReminder(
      medicineName: medicine.name,
      expiryDate: medicine.expiryDate,
      notificationId: notificationId,
    );
  }

  Future<void> cancelExpiryReminder(String medicineId) async {
    final notificationId = _stableNotificationId(medicineId);
    await _notificationService.cancelNotification(notificationId);
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
