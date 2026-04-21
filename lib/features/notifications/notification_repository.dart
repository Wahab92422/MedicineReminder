import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'firestore_batch_limits.dart';
import 'notification_model.dart';

class NotificationRepository {
  NotificationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _readTimeout = const Duration(seconds: 10);
  final _writeTimeout = const Duration(seconds: 15);

  CollectionReference<Map<String, dynamic>> _notifications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications');
  }

  String allocateNotificationId(String userId) {
    return _notifications(userId).doc().id;
  }

  Future<List<AppNotification>> getNotifications({
    required String userId,
    int limit = 50,
  }) async {
    final snap = await _notifications(userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get()
        .timeout(_readTimeout);

    return snap.docs.map(_parseNotificationDoc).whereType<AppNotification>().toList();
  }

  /// Live updates when documents are added, updated, or removed.
  Stream<List<AppNotification>> watchNotifications({
    required String userId,
    int limit = 50,
  }) {
    return _notifications(userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(_parseNotificationDoc).whereType<AppNotification>().toList(),
        );
  }

  AppNotification? _parseNotificationDoc(DocumentSnapshot doc) {
    try {
      return AppNotification.fromFirestore(doc);
    } catch (e, st) {
      debugPrint('Skipping notification doc ${doc.id}: $e\n$st');
      return null;
    }
  }

  Future<List<AppNotification>> getUnreadNotifications({
    required String userId,
  }) async {
    // Equality-only filter (no orderBy) so no composite index is required.
    final snap = await _notifications(userId)
        .where('isRead', isEqualTo: false)
        .get()
        .timeout(_readTimeout);

    return snap.docs.map(_parseNotificationDoc).whereType<AppNotification>().toList();
  }

  Future<AppNotification> createNotification({
    required String userId,
    required AppNotification notification,
  }) async {
    final docRef = _notifications(userId).doc(notification.id);
    await docRef.set(notification.toFirestore()).timeout(_writeTimeout);
    return notification;
  }

  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  }) async {
    await _notifications(
      userId,
    ).doc(notificationId).update({'isRead': true}).timeout(_writeTimeout);
  }

  Future<void> markAllAsRead({required String userId}) async {
    final snap = await _notifications(userId)
        .where('isRead', isEqualTo: false)
        .get()
        .timeout(_readTimeout);

    if (snap.docs.isEmpty) {
      return;
    }

    final docs = snap.docs;
    for (var i = 0; i < docs.length; i += kFirestoreMaxBatchWrites) {
      final batch = _firestore.batch();
      final end = (i + kFirestoreMaxBatchWrites > docs.length)
          ? docs.length
          : i + kFirestoreMaxBatchWrites;
      for (var j = i; j < end; j++) {
        batch.update(docs[j].reference, {'isRead': true});
      }
      await batch.commit().timeout(_writeTimeout);
    }
  }

  Future<void> deleteNotification({
    required String userId,
    required String notificationId,
  }) async {
    await _notifications(
      userId,
    ).doc(notificationId).delete().timeout(_writeTimeout);
  }

  Future<void> deleteAllNotifications({required String userId}) async {
    final batch = _firestore.batch();
    final notifications = await getNotifications(userId: userId);

    for (final notification in notifications) {
      batch.delete(_notifications(userId).doc(notification.id));
    }

    await batch.commit().timeout(_writeTimeout);
  }

  // Clean up old notifications (older than 30 days)
  Future<void> cleanupOldNotifications({required String userId}) async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final batch = _firestore.batch();

    final oldNotifications = await _notifications(userId)
        .where('createdAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
        .get()
        .timeout(_readTimeout);

    for (final doc in oldNotifications.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit().timeout(_writeTimeout);
  }
}
