import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'social_history_entry.dart';

class SocialHistoryWriteResponse {
  const SocialHistoryWriteResponse.success(
    this.entryId, {
    this.isQueuedForSync = false,
  }) : success = true,
       errorMessage = null;

  const SocialHistoryWriteResponse.failure(this.entryId, this.errorMessage)
    : success = false,
      isQueuedForSync = false;

  final bool success;
  final String entryId;
  final String? errorMessage;
  final bool isQueuedForSync;
}

class SocialHistoryPage {
  const SocialHistoryPage({required this.items, this.nextPageCursor});

  final List<SocialHistoryEntry> items;
  final DocumentSnapshot<Map<String, dynamic>>? nextPageCursor;
}

class SocialHistoryRepository {
  SocialHistoryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const Duration _writeTimeout = Duration(seconds: 20);
  static const Duration _verifyTimeout = Duration(seconds: 5);
  static const Duration _readTimeout = Duration(seconds: 20);

  CollectionReference<Map<String, dynamic>> _entries(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('socialHistory');
  }

  String allocateEntryId(String userId) => _entries(userId).doc().id;

  Future<SocialHistoryPage> getEntriesPage({
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
    final items = docs.map(SocialHistoryEntry.fromFirestore).toList();
    final lastDoc = docs.isEmpty ? null : docs.last;
    final hasMore = docs.length == limit;

    return SocialHistoryPage(
      items: items,
      nextPageCursor: hasMore ? lastDoc : null,
    );
  }

  Future<SocialHistoryWriteResponse> createEntry({
    required String userId,
    required SocialHistoryEntry entry,
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

  Future<SocialHistoryWriteResponse> updateEntry({
    required String userId,
    required SocialHistoryEntry entry,
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

  Future<SocialHistoryWriteResponse> deleteEntry({
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

  Future<SocialHistoryWriteResponse> _runWrite({
    required String entryId,
    required String action,
    required Future<void> Function() operation,
    required Future<bool> Function() verifyOnServer,
    required Future<bool> Function() verifyInCache,
  }) async {
    try {
      await operation();
      return SocialHistoryWriteResponse.success(entryId);
    } on TimeoutException catch (error) {
      final cacheOk = await verifyInCache();
      final serverOk = cacheOk ? false : await verifyOnServer();
      if (cacheOk) {
        return SocialHistoryWriteResponse.success(
          entryId,
          isQueuedForSync: true,
        );
      }
      if (serverOk) {
        return SocialHistoryWriteResponse.success(entryId);
      }
      return SocialHistoryWriteResponse.failure(
        entryId,
        error.message ?? error.toString(),
      );
    } on FirebaseException catch (error) {
      return SocialHistoryWriteResponse.failure(
        entryId,
        error.message ?? 'Firestore $action failed.',
      );
    } catch (error) {
      return SocialHistoryWriteResponse.failure(entryId, error.toString());
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
    required SocialHistoryEntry expected,
    Source source = Source.server,
  }) async {
    try {
      final snap = await _entries(userId)
          .doc(expected.id)
          .get(GetOptions(source: source))
          .timeout(_verifyTimeout);
      final data = snap.data();
      if (!snap.exists || data == null) return false;
      final actual = SocialHistoryEntry.fromMap(expected.id, data);
      return _sameEntry(expected, actual);
    } catch (_) {
      return false;
    }
  }

  bool _sameEntry(SocialHistoryEntry a, SocialHistoryEntry b) {
    if (!_sameMinute(a.recordedAt, b.recordedAt)) return false;
    if (a.category != b.category) return false;
    if (a.title != b.title) return false;
    if (a.details != b.details) return false;
    if (a.notes != b.notes) return false;
    return true;
  }

  bool _sameMinute(DateTime x, DateTime y) {
    return x.year == y.year &&
        x.month == y.month &&
        x.day == y.day &&
        x.hour == y.hour &&
        x.minute == y.minute;
  }
}
