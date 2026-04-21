import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'vital_entry.dart';

class VitalWriteResponse {
  const VitalWriteResponse.success(this.entryId, {this.isQueuedForSync = false})
    : success = true,
      errorMessage = null;

  const VitalWriteResponse.failure(this.entryId, this.errorMessage)
    : success = false,
      isQueuedForSync = false;

  final bool success;
  final String entryId;
  final String? errorMessage;
  final bool isQueuedForSync;
}

class VitalPage {
  const VitalPage({required this.items, this.nextPageCursor});

  final List<VitalEntry> items;
  final DocumentSnapshot<Map<String, dynamic>>? nextPageCursor;
}

/// Firestore `users/{uid}/vitals`.
class VitalRepository {
  VitalRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const Duration _writeTimeout = Duration(seconds: 20);
  static const Duration _verifyTimeout = Duration(seconds: 5);
  static const Duration _readTimeout = Duration(seconds: 20);

  CollectionReference<Map<String, dynamic>> _vitals(String userId) {
    return _firestore.collection('users').doc(userId).collection('vitals');
  }

  String allocateEntryId(String userId) => _vitals(userId).doc().id;

  Future<VitalPage> getVitalsPage({
    required String userId,
    int limit = 20,
    Object? pageCursor,
  }) async {
    final startAfter = pageCursor is DocumentSnapshot<Map<String, dynamic>>
        ? pageCursor
        : null;

    Query<Map<String, dynamic>> q = _vitals(
      userId,
    ).orderBy('recordedAt', descending: true);

    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }

    final snap = await q.limit(limit).get().timeout(_readTimeout);
    final docs = snap.docs;
    final items = docs.map(VitalEntry.fromFirestore).toList();
    final lastDoc = docs.isEmpty ? null : docs.last;
    final hasMore = docs.length == limit;

    return VitalPage(items: items, nextPageCursor: hasMore ? lastDoc : null);
  }

  Future<VitalWriteResponse> createEntry({
    required String userId,
    required VitalEntry entry,
  }) async {
    final payload = entry.toCreateMapClientTs(DateTime.now());
    return _runWrite(
      entryId: entry.id,
      action: 'create',
      operation: () async {
        await _vitals(userId).doc(entry.id).set(payload).timeout(_writeTimeout);
      },
      verifyOnServer: () => _exists(userId: userId, entryId: entry.id),
      verifyInCache: () =>
          _exists(userId: userId, entryId: entry.id, source: Source.cache),
    );
  }

  Future<VitalWriteResponse> updateEntry({
    required String userId,
    required VitalEntry entry,
  }) async {
    final payload = entry.toUpdateMap();
    return _runWrite(
      entryId: entry.id,
      action: 'update',
      operation: () async {
        await _vitals(userId)
            .doc(entry.id)
            .set(payload, SetOptions(merge: true))
            .timeout(_writeTimeout);
      },
      verifyOnServer: () =>
          _matches(userId: userId, expected: entry, source: Source.server),
      verifyInCache: () =>
          _matches(userId: userId, expected: entry, source: Source.cache),
    );
  }

  Future<VitalWriteResponse> deleteEntry({
    required String userId,
    required String entryId,
  }) async {
    return _runWrite(
      entryId: entryId,
      action: 'delete',
      operation: () async {
        await _vitals(userId).doc(entryId).delete().timeout(_writeTimeout);
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

  Future<VitalWriteResponse> _runWrite({
    required String entryId,
    required String action,
    required Future<void> Function() operation,
    required Future<bool> Function() verifyOnServer,
    required Future<bool> Function() verifyInCache,
  }) async {
    try {
      await operation();
      return VitalWriteResponse.success(entryId);
    } on TimeoutException catch (error) {
      final cacheOk = await verifyInCache();
      final serverOk = cacheOk ? false : await verifyOnServer();
      if (cacheOk) {
        return VitalWriteResponse.success(entryId, isQueuedForSync: true);
      }
      if (serverOk) {
        return VitalWriteResponse.success(entryId);
      }
      return VitalWriteResponse.failure(
        entryId,
        error.message ?? error.toString(),
      );
    } on FirebaseException catch (error) {
      return VitalWriteResponse.failure(
        entryId,
        error.message ?? 'Firestore $action failed.',
      );
    } catch (error) {
      return VitalWriteResponse.failure(entryId, error.toString());
    }
  }

  Future<bool> _exists({
    required String userId,
    required String entryId,
    Source source = Source.server,
  }) async {
    try {
      final snap = await _vitals(
        userId,
      ).doc(entryId).get(GetOptions(source: source)).timeout(_verifyTimeout);
      return snap.exists;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _matches({
    required String userId,
    required VitalEntry expected,
    Source source = Source.server,
  }) async {
    try {
      final snap = await _vitals(userId)
          .doc(expected.id)
          .get(GetOptions(source: source))
          .timeout(_verifyTimeout);
      final data = snap.data();
      if (!snap.exists || data == null) return false;
      final actual = VitalEntry.fromMap(expected.id, data);
      return _sameEntry(expected, actual);
    } catch (_) {
      return false;
    }
  }

  bool _sameEntry(VitalEntry a, VitalEntry b) {
    if (!_sameMinute(a.recordedAt, b.recordedAt)) return false;
    if (a.systolicMmHg != b.systolicMmHg) return false;
    if (a.diastolicMmHg != b.diastolicMmHg) return false;
    if (a.heartRateBpm != b.heartRateBpm) return false;
    if (!_sameDouble(a.temperatureCelsius, b.temperatureCelsius)) {
      return false;
    }
    if (!_sameDouble(a.weightKg, b.weightKg)) return false;
    if (!_sameDouble(a.heightCm, b.heightCm)) return false;
    if (!_sameDouble(a.glucoseMgDl, b.glucoseMgDl)) return false;
    if (a.spo2Percent != b.spo2Percent) return false;
    if (a.notes != b.notes) return false;
    // Ignore createdAt/updatedAt — server timestamps may differ from client payload.
    return true;
  }

  bool _sameMinute(DateTime x, DateTime y) {
    return x.year == y.year &&
        x.month == y.month &&
        x.day == y.day &&
        x.hour == y.hour &&
        x.minute == y.minute;
  }

  bool _sameDouble(double? a, double? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return (a - b).abs() < 1e-9;
  }
}
