import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'medical_history_entry.dart';

class MedicalHistoryWriteResponse {
  const MedicalHistoryWriteResponse.success(
    this.entryId, {
    this.isQueuedForSync = false,
  }) : success = true,
       errorMessage = null;

  const MedicalHistoryWriteResponse.failure(this.entryId, this.errorMessage)
    : success = false,
      isQueuedForSync = false;

  final bool success;
  final String entryId;
  final String? errorMessage;
  final bool isQueuedForSync;
}

class MedicalHistoryPage {
  const MedicalHistoryPage({required this.items, this.nextPageCursor});

  final List<MedicalHistoryEntry> items;
  final DocumentSnapshot<Map<String, dynamic>>? nextPageCursor;
}

class MedicalHistoryRepository {
  MedicalHistoryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const Duration _writeTimeout = Duration(seconds: 20);
  static const Duration _verifyTimeout = Duration(seconds: 5);
  static const Duration _readTimeout = Duration(seconds: 20);

  CollectionReference<Map<String, dynamic>> _entries(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('medicalHistory');
  }

  String allocateEntryId(String userId) => _entries(userId).doc().id;

  Future<MedicalHistoryPage> getEntriesPage({
    required String userId,
    int limit = 20,
    Object? pageCursor,
  }) async {
    final startAfter = pageCursor is DocumentSnapshot<Map<String, dynamic>>
        ? pageCursor
        : null;

    Query<Map<String, dynamic>> query = _entries(
      userId,
    ).orderBy('recordedAt', descending: true);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snap = await query.limit(limit).get().timeout(_readTimeout);
    final docs = snap.docs;
    final items = docs.map(MedicalHistoryEntry.fromFirestore).toList();
    final lastDoc = docs.isEmpty ? null : docs.last;
    final hasMore = docs.length == limit;

    return MedicalHistoryPage(
      items: items,
      nextPageCursor: hasMore ? lastDoc : null,
    );
  }

  Future<MedicalHistoryWriteResponse> createEntry({
    required String userId,
    required MedicalHistoryEntry entry,
  }) async {
    final payload = entry.toCreateMapClientTs(DateTime.now());
    return _runWrite(
      entryId: entry.id,
      action: 'create',
      operation: () async {
        await _entries(
          userId,
        ).doc(entry.id).set(payload).timeout(_writeTimeout);
      },
      verifyOnServer: () => _exists(userId: userId, entryId: entry.id),
      verifyInCache: () =>
          _exists(userId: userId, entryId: entry.id, source: Source.cache),
    );
  }

  Future<MedicalHistoryWriteResponse> updateEntry({
    required String userId,
    required MedicalHistoryEntry entry,
  }) async {
    final payload = entry.toUpdateMap();
    return _runWrite(
      entryId: entry.id,
      action: 'update',
      operation: () async {
        await _entries(userId)
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

  Future<MedicalHistoryWriteResponse> deleteEntry({
    required String userId,
    required String entryId,
  }) async {
    return _runWrite(
      entryId: entryId,
      action: 'delete',
      operation: () async {
        await _entries(userId).doc(entryId).delete().timeout(_writeTimeout);
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

  Future<MedicalHistoryWriteResponse> _runWrite({
    required String entryId,
    required String action,
    required Future<void> Function() operation,
    required Future<bool> Function() verifyOnServer,
    required Future<bool> Function() verifyInCache,
  }) async {
    try {
      await operation();
      return MedicalHistoryWriteResponse.success(entryId);
    } on TimeoutException catch (error) {
      final cacheOk = await verifyInCache();
      final serverOk = cacheOk ? false : await verifyOnServer();
      if (cacheOk) {
        return MedicalHistoryWriteResponse.success(
          entryId,
          isQueuedForSync: true,
        );
      }
      if (serverOk) {
        return MedicalHistoryWriteResponse.success(entryId);
      }
      return MedicalHistoryWriteResponse.failure(
        entryId,
        error.message ?? error.toString(),
      );
    } on FirebaseException catch (error) {
      return MedicalHistoryWriteResponse.failure(
        entryId,
        error.message ?? 'Firestore $action failed.',
      );
    } catch (error) {
      return MedicalHistoryWriteResponse.failure(entryId, error.toString());
    }
  }

  Future<bool> _exists({
    required String userId,
    required String entryId,
    Source source = Source.server,
  }) async {
    try {
      final snap = await _entries(
        userId,
      ).doc(entryId).get(GetOptions(source: source)).timeout(_verifyTimeout);
      return snap.exists;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _matches({
    required String userId,
    required MedicalHistoryEntry expected,
    Source source = Source.server,
  }) async {
    try {
      final snap = await _entries(userId)
          .doc(expected.id)
          .get(GetOptions(source: source))
          .timeout(_verifyTimeout);
      final data = snap.data();
      if (!snap.exists || data == null) return false;
      final actual = MedicalHistoryEntry.fromMap(expected.id, data);
      return _sameEntry(expected, actual);
    } catch (_) {
      return false;
    }
  }

  bool _sameEntry(MedicalHistoryEntry a, MedicalHistoryEntry b) {
    if (a.category != b.category) return false;
    if (a.title != b.title) return false;
    if (a.details != b.details) return false;
    if (a.notes != b.notes) return false;
    if (a.recordedAt != b.recordedAt) return false;
    return true;
  }
}
