import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'lab_report.dart';

DateTime _endOfLocalDay(DateTime d) {
  return DateTime(d.year, d.month, d.day, 23, 59, 59, 999);
}

class LabReportWriteResponse {
  const LabReportWriteResponse.success(
    this.reportId, {
    this.isQueuedForSync = false,
  }) : success = true,
       errorMessage = null;

  const LabReportWriteResponse.failure(this.reportId, this.errorMessage)
    : success = false,
      isQueuedForSync = false;

  final bool success;
  final String reportId;
  final String? errorMessage;
  final bool isQueuedForSync;

  @override
  String toString() {
    return 'LabReportWriteResponse(success: $success, reportId: $reportId, errorMessage: $errorMessage, isQueuedForSync: $isQueuedForSync)';
  }
}

/// One page of [LabReport]s + Firestore cursor for pagination.
class LabReportPage {
  const LabReportPage({required this.items, this.nextPageCursor});

  final List<LabReport> items;
  final DocumentSnapshot<Map<String, dynamic>>? nextPageCursor;
}

/// Firestore `users/{uid}/labReports` + Storage `labReports/{uid}/{reportId}/…`.
class LabReportRepository {
  LabReportRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static const Duration _writeTimeout = Duration(seconds: 20);
  static const Duration _verifyTimeout = Duration(seconds: 5);
  static const Duration _readTimeout = Duration(seconds: 20);

  CollectionReference<Map<String, dynamic>> _reports(String userId) {
    return _firestore.collection('users').doc(userId).collection('labReports');
  }

  String allocateReportId(String userId) => _reports(userId).doc().id;

  Future<LabReportPage> getReportsPage({
    required String userId,
    int limit = 20,
    Object? pageCursor,
    String? reportType,
    DateTime? testDateFrom,
    DateTime? testDateTo,
    String? titleSearch,
  }) async {
    final startAfter = pageCursor is DocumentSnapshot<Map<String, dynamic>>
        ? pageCursor
        : null;

    final trimmedSearch = titleSearch?.trim() ?? '';
    final useTitlePrefix = trimmedSearch.isNotEmpty;

    Query<Map<String, dynamic>> q = _reports(userId);

    if (reportType != null && reportType.isNotEmpty) {
      q = q.where('reportType', isEqualTo: reportType);
    }

    if (useTitlePrefix) {
      final prefix = trimmedSearch.toLowerCase();
      q = q.orderBy('titleLower').startAt([prefix]).endAt(['$prefix\uf8ff']);
    } else {
      if (testDateFrom != null) {
        q = q.where(
          'testDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(testDateFrom),
        );
      }
      if (testDateTo != null) {
        q = q.where(
          'testDate',
          isLessThanOrEqualTo: Timestamp.fromDate(_endOfLocalDay(testDateTo)),
        );
      }
      q = q.orderBy('createdAt', descending: true);
    }

    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }

    final snap = await q.limit(limit).get().timeout(_readTimeout);
    final docs = snap.docs;
    var items = docs.map(LabReport.fromFirestore).toList();

    if (useTitlePrefix && (testDateFrom != null || testDateTo != null)) {
      items = items.where((m) {
        if (testDateFrom != null && m.testDate.isBefore(testDateFrom)) {
          return false;
        }
        if (testDateTo != null &&
            m.testDate.isAfter(_endOfLocalDay(testDateTo))) {
          return false;
        }
        return true;
      }).toList();
    }

    final lastDoc = docs.isEmpty ? null : docs.last;
    final hasMore = docs.length == limit;

    return LabReportPage(
      items: items,
      nextPageCursor: hasMore ? lastDoc : null,
    );
  }

  Future<LabReportWriteResponse> createReport({
    required String userId,
    required LabReport report,
  }) async {
    final createPayload = report.toCreateMapClientTs(DateTime.now());
    return _runWriteOperation(
      action: 'create',
      reportId: report.id,
      operation: () async {
        await _reports(
          userId,
        ).doc(report.id).set(createPayload).timeout(_writeTimeout);
      },
      verifyOnServer: () => _verifyExists(userId: userId, reportId: report.id),
      verifyInCache: () => _verifyExists(
        userId: userId,
        reportId: report.id,
        source: Source.cache,
      ),
      onAfterSuccess: () => _logServerDocumentState(
        userId: userId,
        reportId: report.id,
        action: 'create',
      ),
      onAfterTimeout: () => _logServerDocumentState(
        userId: userId,
        reportId: report.id,
        action: 'create-timeout',
      ),
    );
  }

  Future<LabReportWriteResponse> updateReport({
    required String userId,
    required LabReport report,
  }) async {
    final updatePayload = {
      'reportType': report.reportType,
      'title': report.title,
      'titleLower': report.title.toLowerCase(),
      'description': report.description,
      'testDate': Timestamp.fromDate(report.testDate),
      'reportDate': Timestamp.fromDate(report.reportDate),
      'attachments': report.attachments.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    return _runWriteOperation(
      action: 'update',
      reportId: report.id,
      operation: () async {
        await _reports(userId)
            .doc(report.id)
            .set(updatePayload, SetOptions(merge: true))
            .timeout(_writeTimeout);
      },
      verifyOnServer: () =>
          _verifyUpdatedReport(userId: userId, report: report),
      verifyInCache: () => _verifyUpdatedReport(
        userId: userId,
        report: report,
        source: Source.cache,
      ),
      onAfterSuccess: () => _logServerDocumentState(
        userId: userId,
        reportId: report.id,
        action: 'update',
      ),
      onAfterTimeout: () => _logServerDocumentState(
        userId: userId,
        reportId: report.id,
        action: 'update-timeout',
      ),
    );
  }

  Future<LabReportWriteResponse> deleteReport({
    required String userId,
    required String reportId,
    required List<String> attachmentUrls,
  }) async {
    return _runWriteOperation(
      action: 'delete',
      reportId: reportId,
      operation: () async {
        for (final url in attachmentUrls) {
          await deleteStoredFile(url);
        }
        await _reports(userId).doc(reportId).delete().timeout(_writeTimeout);
      },
      verifyOnServer: () =>
          _verifyNotExists(userId: userId, reportId: reportId),
      verifyInCache: () => _verifyNotExists(
        userId: userId,
        reportId: reportId,
        source: Source.cache,
      ),
      onAfterSuccess: () => _logServerDocumentState(
        userId: userId,
        reportId: reportId,
        action: 'delete',
      ),
      onAfterTimeout: () => _logServerDocumentState(
        userId: userId,
        reportId: reportId,
        action: 'delete-timeout',
      ),
    );
  }

  Future<LabReportWriteResponse> _runWriteOperation({
    required String action,
    required String reportId,
    required Future<void> Function() operation,
    required Future<bool> Function() verifyOnServer,
    required Future<bool> Function() verifyInCache,
    Future<void> Function()? onAfterSuccess,
    Future<void> Function()? onAfterTimeout,
  }) async {
    try {
      await operation();
      await onAfterSuccess?.call();
      return LabReportWriteResponse.success(reportId);
    } on TimeoutException catch (error) {
      final cacheVerified = await verifyInCache();
      final serverVerified = cacheVerified ? false : await verifyOnServer();
      await onAfterTimeout?.call();
      if (cacheVerified) {
        return LabReportWriteResponse.success(reportId, isQueuedForSync: true);
      }
      if (serverVerified) {
        return LabReportWriteResponse.success(reportId);
      }
      return LabReportWriteResponse.failure(
        reportId,
        error.message ?? error.toString(),
      );
    } on FirebaseException catch (error) {
      return LabReportWriteResponse.failure(
        reportId,
        error.message ?? 'Firestore $action failed.',
      );
    } catch (error) {
      return LabReportWriteResponse.failure(reportId, error.toString());
    }
  }

  Future<bool> _verifyExists({
    required String userId,
    required String reportId,
    Source source = Source.server,
  }) async {
    try {
      final snap = await _reports(
        userId,
      ).doc(reportId).get(GetOptions(source: source)).timeout(_verifyTimeout);
      return snap.exists;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _verifyNotExists({
    required String userId,
    required String reportId,
    Source source = Source.server,
  }) async {
    try {
      final snap = await _reports(
        userId,
      ).doc(reportId).get(GetOptions(source: source)).timeout(_verifyTimeout);
      return !snap.exists;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _verifyUpdatedReport({
    required String userId,
    required LabReport report,
    Source source = Source.server,
  }) async {
    try {
      final snap = await _reports(
        userId,
      ).doc(report.id).get(GetOptions(source: source)).timeout(_verifyTimeout);
      final data = snap.data();
      if (!snap.exists || data == null) return false;

      final serverReport = LabReport.fromMap(report.id, data);
      return _matchesReport(expected: report, actual: serverReport);
    } catch (_) {
      return false;
    }
  }

  bool _matchesReport({
    required LabReport expected,
    required LabReport actual,
  }) {
    if (expected.reportType != actual.reportType) return false;
    if (expected.title != actual.title) return false;
    if (expected.description != actual.description) return false;
    if (!_sameMinute(expected.testDate, actual.testDate)) return false;
    if (!_sameMinute(expected.reportDate, actual.reportDate)) return false;
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
    required String reportId,
    required String action,
  }) async {}

  Future<String> uploadAttachment({
    required String userId,
    required String reportId,
    required String originalFileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final safe = _safeFileName(originalFileName);
    final unique = '${DateTime.now().millisecondsSinceEpoch}_$safe';
    final ref = _storage.ref('labReports/$userId/$reportId/$unique');
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
