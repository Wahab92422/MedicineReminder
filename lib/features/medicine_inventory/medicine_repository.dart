import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

import '../../services/medicine_notification_helper.dart';
import 'medicine_entry.dart';
import 'medicine_page.dart';
import 'medicine_write_response.dart';

class MedicineRepository {
  MedicineRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final _readTimeout = const Duration(seconds: 10);
  final _writeTimeout = const Duration(seconds: 15);

  CollectionReference<Map<String, dynamic>> _medicines(String userId) {
    return _firestore.collection('users').doc(userId).collection('medicines');
  }

  String allocateEntryId(String userId) {
    return _medicines(userId).doc().id;
  }

  /// Shared query for paginated reads and [watchMedicines] snapshots.
  Query<Map<String, dynamic>> medicinesQuery({
    required String userId,
    String? categoryFilter,
    String? nameSearch,
  }) {
    final trimmedSearch = nameSearch?.trim() ?? '';
    final useNamePrefix = trimmedSearch.isNotEmpty;

    Query<Map<String, dynamic>> q = _medicines(userId);

    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      q = q.where('category', isEqualTo: categoryFilter);
    }

    if (useNamePrefix) {
      final prefix = trimmedSearch.toLowerCase();
      q = q.orderBy('nameLower').startAt([prefix]).endAt(['$prefix\uf8ff']);
    } else {
      q = q.orderBy('createdAt', descending: true);
    }

    return q;
  }

  /// Client filter when both category and name-prefix search are active (matches [listMedicines]).
  static List<MedicineEntry> applyInventoryQueryPostFilter(
    List<MedicineEntry> items, {
    String? categoryFilter,
    String? nameSearch,
  }) {
    final trimmedSearch = nameSearch?.trim() ?? '';
    final useNamePrefix = trimmedSearch.isNotEmpty;
    if (useNamePrefix && categoryFilter != null && categoryFilter.isNotEmpty) {
      return items.where((m) => m.category == categoryFilter).toList();
    }
    return items;
  }

  /// Live inventory list with the same filters as [listMedicines] (bounded by [limit]).
  Stream<List<MedicineEntry>> watchMedicines({
    required String userId,
    String? categoryFilter,
    String? nameSearch,
    int limit = 300,
  }) {
    final q = medicinesQuery(
      userId: userId,
      categoryFilter: categoryFilter,
      nameSearch: nameSearch,
    ).limit(limit);
    return q.snapshots().map((snap) {
      final items = snap.docs.map(MedicineEntry.fromFirestore).toList();
      return applyInventoryQueryPostFilter(
        items,
        categoryFilter: categoryFilter,
        nameSearch: nameSearch,
      );
    });
  }

  /// All medicines, ordered by [nameLower], for pickers and derived alert lists.
  Stream<List<MedicineEntry>> watchAllMedicinesOrderedByName({
    required String userId,
  }) {
    return _medicines(userId).orderBy('nameLower').snapshots().map(
          (s) => s.docs.map(MedicineEntry.fromFirestore).toList(),
        );
  }

  Future<MedicinePage> listMedicines({
    required String userId,
    String? categoryFilter,
    String? nameSearch,
    DocumentSnapshot<Map<String, dynamic>>? pageCursor,
    int limit = 20,
  }) async {
    final startAfter = pageCursor;

    var q = medicinesQuery(
      userId: userId,
      categoryFilter: categoryFilter,
      nameSearch: nameSearch,
    );

    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }

    final snap = await q.limit(limit).get().timeout(_readTimeout);
    final docs = snap.docs;
    final items = applyInventoryQueryPostFilter(
      docs.map(MedicineEntry.fromFirestore).toList(),
      categoryFilter: categoryFilter,
      nameSearch: nameSearch,
    );

    final lastDoc = docs.isEmpty ? null : docs.last;
    final hasMore = docs.length == limit;

    return MedicinePage(items: items, nextPageCursor: hasMore ? lastDoc : null);
  }

  /// All medicines for pickers (e.g. dose logs). Ordered by [nameLower].
  Future<List<MedicineEntry>> listAllMedicines({required String userId}) async {
    final snap = await _medicines(userId)
        .orderBy('nameLower')
        .get()
        .timeout(_readTimeout);
    return snap.docs.map(MedicineEntry.fromFirestore).toList();
  }

  Future<List<MedicineEntry>> getLowStockMedicines({
    required String userId,
  }) async {
    final snap = await _medicines(
      userId,
    ).orderBy('createdAt', descending: true).get().timeout(_readTimeout);
    final items = snap.docs.map(MedicineEntry.fromFirestore).toList();
    return items.where((m) => m.isLowStock).toList();
  }

  Future<List<MedicineEntry>> getExpiringMedicines({
    required String userId,
  }) async {
    final snap = await _medicines(
      userId,
    ).orderBy('expiryDate').get().timeout(_readTimeout);
    final items = snap.docs.map(MedicineEntry.fromFirestore).toList();
    return items.where((m) => m.isExpiringSoon || m.isExpired).toList();
  }

  Future<MedicineWriteResponse> createEntry({
    required String userId,
    required MedicineEntry entry,
  }) async {
    try {
      final createPayload = entry.toCreateMapClientTs(DateTime.now());
      await _medicines(
        userId,
      ).doc(entry.id).set(createPayload).timeout(_writeTimeout);

      // Schedule expiry reminder
      MedicineNotificationHelper().scheduleExpiryReminder(entry);

      final created = await _medicines(userId).doc(entry.id).get();
      if (created.exists) {
        await MedicineNotificationHelper().checkAndCreateNotifications(
          [MedicineEntry.fromFirestore(created)],
        );
      }

      return const MedicineWriteResponse(success: true);
    } catch (e) {
      return MedicineWriteResponse(
        success: false,
        errorMessage: 'Failed to create medicine: $e',
      );
    }
  }

  Future<MedicineWriteResponse> updateEntry({
    required String userId,
    required MedicineEntry entry,
  }) async {
    try {
      final updatePayload = entry.toUpdateMap();
      await _medicines(userId)
          .doc(entry.id)
          .set(updatePayload, SetOptions(merge: true))
          .timeout(_writeTimeout);

      // Update expiry reminder
      MedicineNotificationHelper().cancelExpiryReminder(entry.id);
      MedicineNotificationHelper().scheduleExpiryReminder(entry);

      final updated = await _medicines(userId).doc(entry.id).get();
      if (updated.exists) {
        await MedicineNotificationHelper().checkAndCreateNotifications(
          [MedicineEntry.fromFirestore(updated)],
        );
      }

      return const MedicineWriteResponse(success: true);
    } catch (e) {
      return MedicineWriteResponse(
        success: false,
        errorMessage: 'Failed to update medicine: $e',
      );
    }
  }

  Future<String> uploadMedicineAttachment({
    required String userId,
    required String entryId,
    required String originalFileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final safe = _safeFileName(originalFileName);
    final unique = '${DateTime.now().millisecondsSinceEpoch}_$safe';
    final ref = _storage.ref('medicineInventory/$userId/$entryId/$unique');
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }

  Future<void> deleteStoredFile(String downloadUrl) async {
    try {
      await _storage.refFromURL(downloadUrl).delete();
    } catch (_) {}
  }

  Future<MedicineWriteResponse> deleteEntry({
    required String userId,
    required String entryId,
  }) async {
    try {
      final snap = await _medicines(userId).doc(entryId).get();
      final url = snap.data()?['attachmentUrl'] as String?;
      if (url != null && url.isNotEmpty) {
        await deleteStoredFile(url);
      }
      await MedicineNotificationHelper().cancelExpiryReminder(entryId);
      await _medicines(userId).doc(entryId).delete().timeout(_writeTimeout);
      return const MedicineWriteResponse(success: true);
    } catch (e) {
      return MedicineWriteResponse(
        success: false,
        errorMessage: 'Failed to delete medicine: $e',
      );
    }
  }

  Future<MedicineWriteResponse> updateQuantity({
    required String userId,
    required String entryId,
    required int newQuantity,
  }) async {
    try {
      await _medicines(userId)
          .doc(entryId)
          .update({
            'quantity': newQuantity,
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .timeout(_writeTimeout);
      final doc = await _medicines(userId).doc(entryId).get();
      if (doc.exists) {
        await MedicineNotificationHelper().checkAndCreateNotifications(
          [MedicineEntry.fromFirestore(doc)],
        );
      }
      return const MedicineWriteResponse(success: true);
    } catch (e) {
      return MedicineWriteResponse(
        success: false,
        errorMessage: 'Failed to update quantity: $e',
      );
    }
  }

  static String _safeFileName(String name) {
    final base = p.basename(name).replaceAll(RegExp(r'[^\w.\-]+'), '_');
    return base.isEmpty ? 'attachment' : base;
  }
}
