import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/user_schedule_reminder_notification_helper.dart';
import 'user_schedule_reminder.dart';

class UserScheduleReminderRepository {
  UserScheduleReminderRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _readTimeout = Duration(seconds: 20);
  static const Duration _writeTimeout = Duration(seconds: 20);

  CollectionReference<Map<String, dynamic>> _col(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('userScheduleReminders');
  }

  String allocateId(String userId) => _col(userId).doc().id;

  Future<List<UserScheduleReminder>> getRemindersBetween({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    final snap = await _col(userId)
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('scheduledAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('scheduledAt')
        .get()
        .timeout(_readTimeout);
    return snap.docs.map(UserScheduleReminder.fromFirestore).toList();
  }

  Future<void> createReminder({
    required String userId,
    required UserScheduleReminder reminder,
  }) async {
    final now = DateTime.now();
    await _col(userId)
        .doc(reminder.id)
        .set(reminder.toCreateMapClientTs(now))
        .timeout(_writeTimeout);
    await UserScheduleReminderNotificationHelper().syncReminder(reminder);
  }

  Future<void> deleteReminder({
    required String userId,
    required String reminderId,
  }) async {
    await UserScheduleReminderNotificationHelper().cancelReminder(reminderId);
    await _col(userId).doc(reminderId).delete().timeout(_writeTimeout);
  }

  Future<UserScheduleReminder?> getReminder({
    required String userId,
    required String reminderId,
  }) async {
    final snap = await _col(userId).doc(reminderId).get().timeout(_readTimeout);
    if (!snap.exists) return null;
    return UserScheduleReminder.fromFirestore(snap);
  }

  /// Recent agenda reminders still open ([reminderOutcome] null), newest [scheduledAt] first.
  Future<List<UserScheduleReminder>> listOpenReminders({
    required String userId,
    int limit = 150,
  }) async {
    final snap = await _col(userId)
        .orderBy('scheduledAt', descending: true)
        .limit(limit)
        .get()
        .timeout(_readTimeout);
    return snap.docs
        .map(UserScheduleReminder.fromFirestore)
        .where((r) => r.reminderOutcome == null)
        .toList();
  }

  Future<void> setReminderOutcome({
    required String userId,
    required String reminderId,
    required String outcome,
  }) async {
    await _col(userId)
        .doc(reminderId)
        .update({
          'reminderOutcome': outcome,
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .timeout(_writeTimeout);
    await UserScheduleReminderNotificationHelper().cancelReminder(reminderId);
  }
}
