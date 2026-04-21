import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../labs/lab_report.dart' show LabAttachment;
import 'prescription.dart';

DateTime _endOfLocalDay(DateTime d) {
  return DateTime(d.year, d.month, d.day, 23, 59, 59, 999);
}

class PrescriptionWriteResponse {
  const PrescriptionWriteResponse.success(
    this.prescriptionId, {
    this.isQueuedForSync = false,
  }) : success = true,
       errorMessage = null;

  const PrescriptionWriteResponse.failure(
    this.prescriptionId,
    this.errorMessage,
  ) : success = false,
      isQueuedForSync = false;

  final bool success;
  final String prescriptionId;
  final String? errorMessage;
  final bool isQueuedForSync;

  @override
  String toString() {
    return 'PrescriptionWriteResponse(success: $success, prescriptionId: $prescriptionId, errorMessage: $errorMessage, isQueuedForSync: $isQueuedForSync)';
  }
}

class PrescriptionPage {
  const PrescriptionPage({required this.items, this.nextPageCursor});

  final List<Prescription> items;
  final DocumentSnapshot<Map<String, dynamic>>? nextPageCursor;
}

/// Firestore `users/{uid}/prescriptions` + Storage `prescriptions/{uid}/{id}/…`.
class PrescriptionRepository {
  PrescriptionRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static const Duration _writeTimeout = Duration(seconds: 20);
  static const Duration _verifyTimeout = Duration(seconds: 5);
  static const Duration _readTimeout = Duration(seconds: 20);

  CollectionReference<Map<String, dynamic>> _items(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('prescriptions');
  }

  String allocatePrescriptionId(String userId) => _items(userId).doc().id;

  Future<PrescriptionPage> getPrescriptionsPage({
    required String userId,
    int limit = 20,
    Object? pageCursor,
    String? prescriptionType,
    DateTime? prescribedDateFrom,
    DateTime? prescribedDateTo,
    String? titleSearch,
  }) async {
    final startAfter = pageCursor is DocumentSnapshot<Map<String, dynamic>>
        ? pageCursor
        : null;

    final trimmedSearch = titleSearch?.trim() ?? '';
    final useTitlePrefix = trimmedSearch.isNotEmpty;

    Query<Map<String, dynamic>> q = _items(userId);

    if (prescriptionType != null && prescriptionType.isNotEmpty) {
      q = q.where('prescriptionType', isEqualTo: prescriptionType);
    }

    if (useTitlePrefix) {
      final prefix = trimmedSearch.toLowerCase();
      q = q.orderBy('titleLower').startAt([prefix]).endAt(['$prefix\uf8ff']);
    } else {
      if (prescribedDateFrom != null) {
        q = q.where(
          'prescribedDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(prescribedDateFrom),
        );
      }
      if (prescribedDateTo != null) {
        q = q.where(
          'prescribedDate',
          isLessThanOrEqualTo: Timestamp.fromDate(
            _endOfLocalDay(prescribedDateTo),
          ),
        );
      }
      q = q.orderBy('createdAt', descending: true);
    }

    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }

    final snap = await q.limit(limit).get().timeout(_readTimeout);
    final docs = snap.docs;
    var items = docs.map(Prescription.fromFirestore).toList();

    if (useTitlePrefix &&
        (prescribedDateFrom != null || prescribedDateTo != null)) {
      items = items.where((m) {
        if (prescribedDateFrom != null &&
            m.prescribedDate.isBefore(prescribedDateFrom)) {
          return false;
        }
        if (prescribedDateTo != null &&
            m.prescribedDate.isAfter(_endOfLocalDay(prescribedDateTo))) {
          return false;
        }
        return true;
      }).toList();
    }

    final lastDoc = docs.isEmpty ? null : docs.last;
    final hasMore = docs.length == limit;

    return PrescriptionPage(
      items: items,
      nextPageCursor: hasMore ? lastDoc : null,
    );
  }

  Future<PrescriptionWriteResponse> createPrescription({
    required String userId,
    required Prescription prescription,
  }) async {
    final createPayload = prescription.toCreateMapClientTs(DateTime.now());
    return _runWriteOperation(
      action: 'create',
      prescriptionId: prescription.id,
      operation: () async {
        await _items(
          userId,
        ).doc(prescription.id).set(createPayload).timeout(_writeTimeout);
      },
      verifyOnServer: () =>
          _verifyExists(userId: userId, prescriptionId: prescription.id),
      verifyInCache: () => _verifyExists(
        userId: userId,
        prescriptionId: prescription.id,
        source: Source.cache,
      ),
      onAfterSuccess: () => _logServerDocumentState(
        userId: userId,
        prescriptionId: prescription.id,
        action: 'create',
      ),
      onAfterTimeout: () => _logServerDocumentState(
        userId: userId,
        prescriptionId: prescription.id,
        action: 'create-timeout',
      ),
    );
  }

  Future<PrescriptionWriteResponse> updatePrescription({
    required String userId,
    required Prescription prescription,
  }) async {
    final updatePayload = {
      'prescriptionType': prescription.prescriptionType,
      'title': prescription.title,
      'titleLower': prescription.title.toLowerCase(),
      'description': prescription.description,
      'prescribedDate': Timestamp.fromDate(prescription.prescribedDate),
      'validUntil': Timestamp.fromDate(prescription.validUntil),
      'attachments': prescription.attachments.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    return _runWriteOperation(
      action: 'update',
      prescriptionId: prescription.id,
      operation: () async {
        await _items(userId)
            .doc(prescription.id)
            .set(updatePayload, SetOptions(merge: true))
            .timeout(_writeTimeout);
      },
      verifyOnServer: () =>
          _verifyUpdated(userId: userId, prescription: prescription),
      verifyInCache: () => _verifyUpdated(
        userId: userId,
        prescription: prescription,
        source: Source.cache,
      ),
      onAfterSuccess: () => _logServerDocumentState(
        userId: userId,
        prescriptionId: prescription.id,
        action: 'update',
      ),
      onAfterTimeout: () => _logServerDocumentState(
        userId: userId,
        prescriptionId: prescription.id,
        action: 'update-timeout',
      ),
    );
  }

  Future<PrescriptionWriteResponse> deletePrescription({
    required String userId,
    required String prescriptionId,
    required List<String> attachmentUrls,
  }) async {
    return _runWriteOperation(
      action: 'delete',
      prescriptionId: prescriptionId,
      operation: () async {
        for (final url in attachmentUrls) {
          await deleteStoredFile(url);
        }
        await _items(
          userId,
        ).doc(prescriptionId).delete().timeout(_writeTimeout);
      },
      verifyOnServer: () =>
          _verifyNotExists(userId: userId, prescriptionId: prescriptionId),
      verifyInCache: () => _verifyNotExists(
        userId: userId,
        prescriptionId: prescriptionId,
        source: Source.cache,
      ),
      onAfterSuccess: () => _logServerDocumentState(
        userId: userId,
        prescriptionId: prescriptionId,
        action: 'delete',
      ),
      onAfterTimeout: () => _logServerDocumentState(
        userId: userId,
        prescriptionId: prescriptionId,
        action: 'delete-timeout',
      ),
    );
  }

  Future<PrescriptionWriteResponse> _runWriteOperation({
    required String action,
    required String prescriptionId,
    required Future<void> Function() operation,
    required Future<bool> Function() verifyOnServer,
    required Future<bool> Function() verifyInCache,
    Future<void> Function()? onAfterSuccess,
    Future<void> Function()? onAfterTimeout,
  }) async {
    try {
      await operation();
      await onAfterSuccess?.call();
      return PrescriptionWriteResponse.success(prescriptionId);
    } on TimeoutException catch (error) {
      final cacheVerified = await verifyInCache();
      final serverVerified = cacheVerified ? false : await verifyOnServer();
      await onAfterTimeout?.call();
      if (cacheVerified) {
        return PrescriptionWriteResponse.success(
          prescriptionId,
          isQueuedForSync: true,
        );
      }
      if (serverVerified) {
        return PrescriptionWriteResponse.success(prescriptionId);
      }
      return PrescriptionWriteResponse.failure(
        prescriptionId,
        error.message ?? error.toString(),
      );
    } on FirebaseException catch (error) {
      return PrescriptionWriteResponse.failure(
        prescriptionId,
        error.message ?? 'Firestore $action failed.',
      );
    } catch (error) {
      return PrescriptionWriteResponse.failure(
        prescriptionId,
        error.toString(),
      );
    }
  }

  Future<bool> _verifyExists({
    required String userId,
    required String prescriptionId,
    Source source = Source.server,
  }) async {
    try {
      final snap = await _items(userId)
          .doc(prescriptionId)
          .get(GetOptions(source: source))
          .timeout(_verifyTimeout);
      return snap.exists;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _verifyNotExists({
    required String userId,
    required String prescriptionId,
    Source source = Source.server,
  }) async {
    try {
      final snap = await _items(userId)
          .doc(prescriptionId)
          .get(GetOptions(source: source))
          .timeout(_verifyTimeout);
      return !snap.exists;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _verifyUpdated({
    required String userId,
    required Prescription prescription,
    Source source = Source.server,
  }) async {
    try {
      final snap = await _items(userId)
          .doc(prescription.id)
          .get(GetOptions(source: source))
          .timeout(_verifyTimeout);
      final data = snap.data();
      if (!snap.exists || data == null) return false;

      final server = Prescription.fromMap(prescription.id, data);
      return _matches(expected: prescription, actual: server);
    } catch (_) {
      return false;
    }
  }

  bool _matches({
    required Prescription expected,
    required Prescription actual,
  }) {
    if (expected.prescriptionType != actual.prescriptionType) return false;
    if (expected.title != actual.title) return false;
    if (expected.description != actual.description) return false;
    if (!_sameMinute(expected.prescribedDate, actual.prescribedDate)) {
      return false;
    }
    if (!_sameMinute(expected.validUntil, actual.validUntil)) return false;
    if (!_sameAttachments(expected.attachments, actual.attachments)) {
      return false;
    }
    return true;
  }

  bool _sameMinute(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
  }

  bool _sameAttachments(List<LabAttachment> a, List<LabAttachment> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index].url != b[index].url) return false;
      if (a[index].type != b[index].type) return false;
    }
    return true;
  }

  Future<void> _logServerDocumentState({
    required String userId,
    required String prescriptionId,
    required String action,
  }) async {}

  Future<String> uploadAttachment({
    required String userId,
    required String prescriptionId,
    required String originalFileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final safe = _safeFileName(originalFileName);
    final unique = '${DateTime.now().millisecondsSinceEpoch}_$safe';
    final ref = _storage.ref('prescriptions/$userId/$prescriptionId/$unique');
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }

  Future<void> deleteStoredFile(String downloadUrl) async {
    try {
      await _storage.refFromURL(downloadUrl).delete();
    } catch (_) {}
  }

  static String _safeFileName(String name) {
    final base = p.basename(name).replaceAll(RegExp(r'[^\w.\-]+'), '_');
    return base.isEmpty ? 'file' : base;
  }
}
