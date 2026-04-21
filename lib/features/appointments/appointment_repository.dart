import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/appointment_notification_helper.dart';
import 'appointment_entry.dart';
import 'appointment_statuses.dart';

class AppointmentWriteResponse {
  const AppointmentWriteResponse.success(
    this.entryId, {
    this.isQueuedForSync = false,
  }) : success = true,
       errorMessage = null;

  const AppointmentWriteResponse.failure(this.entryId, this.errorMessage)
    : success = false,
      isQueuedForSync = false;

  final bool success;
  final String entryId;
  final String? errorMessage;
  final bool isQueuedForSync;
}

class AppointmentPage {
  const AppointmentPage({required this.items, this.nextPageCursor});

  final List<AppointmentEntry> items;
  final DocumentSnapshot<Map<String, dynamic>>? nextPageCursor;
}

class AppointmentRepository {
  AppointmentRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const Duration _writeTimeout = Duration(seconds: 20);
  static const Duration _verifyTimeout = Duration(seconds: 5);
  static const Duration _readTimeout = Duration(seconds: 20);

  CollectionReference<Map<String, dynamic>> _appointments(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('appointments');
  }

  String allocateAppointmentId(String userId) =>
      _appointments(userId).doc().id;

  Future<AppointmentPage> getAppointmentsPage({
    required String userId,
    int limit = 20,
    Object? pageCursor,
  }) async {
    final startAfter = pageCursor is DocumentSnapshot<Map<String, dynamic>>
        ? pageCursor
        : null;

    Query<Map<String, dynamic>> q = _appointments(
      userId,
    ).orderBy('scheduledAt', descending: true);

    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }

    final snap = await q.limit(limit).get().timeout(_readTimeout);
    final docs = snap.docs;
    final items = docs.map(AppointmentEntry.fromFirestore).toList();
    final lastDoc = docs.isEmpty ? null : docs.last;
    final hasMore = docs.length == limit;

    return AppointmentPage(
      items: items,
      nextPageCursor: hasMore ? lastDoc : null,
    );
  }

  Future<AppointmentWriteResponse> createEntry({
    required String userId,
    required AppointmentEntry entry,
  }) async {
    final payload = entry.toCreateMapClientTs(DateTime.now());
    final res = await _runWrite(
      entryId: entry.id,
      action: 'create',
      operation: () async {
        await _appointments(userId)
            .doc(entry.id)
            .set(payload)
            .timeout(_writeTimeout);
      },
      verifyOnServer: () => _exists(userId: userId, entryId: entry.id),
      verifyInCache: () =>
          _exists(userId: userId, entryId: entry.id, source: Source.cache),
    );
    if (res.success) {
      await AppointmentNotificationHelper().syncReminderForEntry(entry);
    }
    return res;
  }

  Future<AppointmentWriteResponse> updateEntry({
    required String userId,
    required AppointmentEntry entry,
  }) async {
    final payload = entry.toUpdateMap();
    final res = await _runWrite(
      entryId: entry.id,
      action: 'update',
      operation: () async {
        await _appointments(userId)
            .doc(entry.id)
            .set(payload, SetOptions(merge: true))
            .timeout(_writeTimeout);
      },
      verifyOnServer: () =>
          _matches(userId: userId, expected: entry, source: Source.server),
      verifyInCache: () =>
          _matches(userId: userId, expected: entry, source: Source.cache),
    );
    if (res.success) {
      await AppointmentNotificationHelper().syncReminderForEntry(entry);
    }
    return res;
  }

  Future<AppointmentWriteResponse> deleteEntry({
    required String userId,
    required String entryId,
  }) async {
    await AppointmentNotificationHelper().cancelReminder(entryId);
    return _runWrite(
      entryId: entryId,
      action: 'delete',
      operation: () async {
        await _appointments(userId).doc(entryId).delete().timeout(_writeTimeout);
      },
      verifyOnServer: () async => !(await _exists(
        userId: userId,
        entryId: entryId,
        source: Source.server,
      )),
      verifyInCache: () async => !(await _exists(
        userId: userId,
        entryId: entryId,
        source: Source.cache,
      )),
    );
  }

  Future<AppointmentWriteResponse> _runWrite({
    required String entryId,
    required String action,
    required Future<void> Function() operation,
    required Future<bool> Function() verifyOnServer,
    required Future<bool> Function() verifyInCache,
  }) async {
    try {
      await operation();
      return AppointmentWriteResponse.success(entryId);
    } on TimeoutException catch (error) {
      final cacheOk = await verifyInCache();
      final serverOk = cacheOk ? false : await verifyOnServer();
      if (cacheOk) {
        return AppointmentWriteResponse.success(entryId, isQueuedForSync: true);
      }
      if (serverOk) {
        return AppointmentWriteResponse.success(entryId);
      }
      return AppointmentWriteResponse.failure(
        entryId,
        error.message ?? error.toString(),
      );
    } on FirebaseException catch (error) {
      return AppointmentWriteResponse.failure(
        entryId,
        error.message ?? 'Firestore $action failed.',
      );
    } catch (error) {
      return AppointmentWriteResponse.failure(entryId, error.toString());
    }
  }

  Future<bool> _exists({
    required String userId,
    required String entryId,
    Source source = Source.server,
  }) async {
    try {
      final snap = await _appointments(
        userId,
      ).doc(entryId).get(GetOptions(source: source)).timeout(_verifyTimeout);
      return snap.exists;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _matches({
    required String userId,
    required AppointmentEntry expected,
    Source source = Source.server,
  }) async {
    try {
      final snap = await _appointments(userId)
          .doc(expected.id)
          .get(GetOptions(source: source))
          .timeout(_verifyTimeout);
      final data = snap.data();
      if (!snap.exists || data == null) return false;
      final actual = AppointmentEntry.fromMap(expected.id, data);
      return _sameEntry(expected, actual);
    } catch (_) {
      return false;
    }
  }

  bool _sameEntry(AppointmentEntry a, AppointmentEntry b) {
    if (!_sameMinute(a.scheduledAt, b.scheduledAt)) return false;
    if (a.title != b.title) return false;
    if (a.status != b.status) return false;
    if (a.notes != b.notes) return false;
    if (a.location != b.location) return false;
    if (a.doctor != b.doctor) return false;
    return true;
  }

  bool _sameMinute(DateTime x, DateTime y) {
    return x.year == y.year &&
        x.month == y.month &&
        x.day == y.day &&
        x.hour == y.hour &&
        x.minute == y.minute;
  }

  /// Appointments with [scheduledAt] in \[start, end\] (inclusive), ordered soonest first.
  Future<List<AppointmentEntry>> getAppointmentsScheduledBetween({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    final snap = await _appointments(userId)
        .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('scheduledAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('scheduledAt')
        .get()
        .timeout(_readTimeout);
    return snap.docs.map(AppointmentEntry.fromFirestore).toList();
  }

  Future<AppointmentEntry?> getEntry({
    required String userId,
    required String entryId,
  }) async {
    final snap =
        await _appointments(userId).doc(entryId).get().timeout(_readTimeout);
    if (!snap.exists) return null;
    return AppointmentEntry.fromFirestore(snap);
  }

  /// Status [AppointmentStatuses.scheduled] only; sorted by [scheduledAt] soonest first.
  Future<List<AppointmentEntry>> listScheduledEntries({
    required String userId,
    int limit = 200,
  }) async {
    final snap = await _appointments(userId)
        .where('status', isEqualTo: AppointmentStatuses.scheduled)
        .get()
        .timeout(_readTimeout);
    final list = snap.docs.map(AppointmentEntry.fromFirestore).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    if (list.length <= limit) return list;
    return list.take(limit).toList();
  }
}
