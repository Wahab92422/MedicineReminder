import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

import 'meal_entry.dart';

class MealWriteResponse {
  const MealWriteResponse.success(this.entryId, {this.isQueuedForSync = false})
    : success = true,
      errorMessage = null;

  const MealWriteResponse.failure(this.entryId, this.errorMessage)
    : success = false,
      isQueuedForSync = false;

  final bool success;
  final String entryId;
  final String? errorMessage;
  final bool isQueuedForSync;
}

class MealPage {
  const MealPage({required this.items, this.nextPageCursor});

  final List<MealEntry> items;
  final DocumentSnapshot<Map<String, dynamic>>? nextPageCursor;
}

class MealRepository {
  MealRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static const Duration _writeTimeout = Duration(seconds: 20);
  static const Duration _verifyTimeout = Duration(seconds: 5);
  static const Duration _readTimeout = Duration(seconds: 20);

  CollectionReference<Map<String, dynamic>> _meals(String userId) {
    return _firestore.collection('users').doc(userId).collection('meals');
  }

  String allocateMealId(String userId) => _meals(userId).doc().id;

  Future<MealPage> getMealsPage({
    required String userId,
    int limit = 20,
    Object? pageCursor,
  }) async {
    final startAfter = pageCursor is DocumentSnapshot<Map<String, dynamic>>
        ? pageCursor
        : null;

    Query<Map<String, dynamic>> q = _meals(
      userId,
    ).orderBy('mealAt', descending: true);

    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }

    final snap = await q.limit(limit).get().timeout(_readTimeout);
    final docs = snap.docs;
    final items = docs.map(MealEntry.fromFirestore).toList();
    final lastDoc = docs.isEmpty ? null : docs.last;
    final hasMore = docs.length == limit;

    return MealPage(items: items, nextPageCursor: hasMore ? lastDoc : null);
  }

  Future<MealWriteResponse> createEntry({
    required String userId,
    required MealEntry entry,
  }) async {
    final payload = entry.toCreateMapClientTs(DateTime.now());
    return _runWrite(
      entryId: entry.id,
      action: 'create',
      operation: () async {
        await _meals(userId).doc(entry.id).set(payload).timeout(_writeTimeout);
      },
      verifyOnServer: () => _exists(userId: userId, entryId: entry.id),
      verifyInCache: () =>
          _exists(userId: userId, entryId: entry.id, source: Source.cache),
    );
  }

  Future<MealWriteResponse> updateEntry({
    required String userId,
    required MealEntry entry,
  }) async {
    final payload = entry.toUpdateMap();
    return _runWrite(
      entryId: entry.id,
      action: 'update',
      operation: () async {
        await _meals(userId)
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

  Future<MealWriteResponse> deleteEntry({
    required String userId,
    required String entryId,
  }) async {
    return _runWrite(
      entryId: entryId,
      action: 'delete',
      operation: () async {
        await _meals(userId).doc(entryId).delete().timeout(_writeTimeout);
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

  Future<String> uploadMealImage({
    required String userId,
    required String mealId,
    required String originalFileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final safe = _safeFileName(originalFileName);
    final unique = '${DateTime.now().millisecondsSinceEpoch}_$safe';
    final ref = _storage.ref('meals/$userId/$mealId/$unique');
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }

  Future<void> deleteStoredFile(String downloadUrl) async {
    try {
      await _storage.refFromURL(downloadUrl).delete();
    } catch (_) {}
  }

  Future<MealWriteResponse> _runWrite({
    required String entryId,
    required String action,
    required Future<void> Function() operation,
    required Future<bool> Function() verifyOnServer,
    required Future<bool> Function() verifyInCache,
  }) async {
    try {
      await operation();
      return MealWriteResponse.success(entryId);
    } on TimeoutException catch (error) {
      final cacheOk = await verifyInCache();
      final serverOk = cacheOk ? false : await verifyOnServer();
      if (cacheOk) {
        return MealWriteResponse.success(entryId, isQueuedForSync: true);
      }
      if (serverOk) {
        return MealWriteResponse.success(entryId);
      }
      return MealWriteResponse.failure(
        entryId,
        error.message ?? error.toString(),
      );
    } on FirebaseException catch (error) {
      return MealWriteResponse.failure(
        entryId,
        error.message ?? 'Firestore $action failed.',
      );
    } catch (error) {
      return MealWriteResponse.failure(entryId, error.toString());
    }
  }

  Future<bool> _exists({
    required String userId,
    required String entryId,
    Source source = Source.server,
  }) async {
    try {
      final snap = await _meals(
        userId,
      ).doc(entryId).get(GetOptions(source: source)).timeout(_verifyTimeout);
      return snap.exists;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _matches({
    required String userId,
    required MealEntry expected,
    Source source = Source.server,
  }) async {
    try {
      final snap = await _meals(userId)
          .doc(expected.id)
          .get(GetOptions(source: source))
          .timeout(_verifyTimeout);
      final data = snap.data();
      if (!snap.exists || data == null) return false;
      final actual = MealEntry.fromMap(expected.id, data);
      return _sameEntry(expected, actual);
    } catch (_) {
      return false;
    }
  }

  bool _sameEntry(MealEntry a, MealEntry b) {
    if (!_sameMinute(a.mealAt, b.mealAt)) return false;
    if (a.mealType != b.mealType) return false;
    if (a.status != b.status) return false;
    if (a.notes != b.notes) return false;
    if (a.imageUrl != b.imageUrl) return false;
    return true;
  }

  bool _sameMinute(DateTime x, DateTime y) {
    return x.year == y.year &&
        x.month == y.month &&
        x.day == y.day &&
        x.hour == y.hour &&
        x.minute == y.minute;
  }

  static String _safeFileName(String name) {
    final base = p.basename(name).replaceAll(RegExp(r'[^\w.\-]+'), '_');
    return base.isEmpty ? 'image' : base;
  }
}
