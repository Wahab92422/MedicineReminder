import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/medicine_notification_helper.dart';
import '../meals/meal_statuses.dart';
import '../medicine_inventory/medicine_entry.dart';
import 'medicine_log_entry.dart';

class MedicineLogWriteResponse {
  const MedicineLogWriteResponse.success(this.entryId, {this.errorMessage})
    : success = true;

  const MedicineLogWriteResponse.failure(this.entryId, this.errorMessage)
    : success = false;

  final bool success;
  final String entryId;
  final String? errorMessage;
}

class MedicineLogPage {
  const MedicineLogPage({required this.items, this.nextPageCursor});

  final List<MedicineLogEntry> items;
  final DocumentSnapshot<Map<String, dynamic>>? nextPageCursor;
}

class MedicineLogRepository {
  MedicineLogRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _readTimeout = Duration(seconds: 20);
  static const Duration _writeTimeout = Duration(seconds: 20);

  CollectionReference<Map<String, dynamic>> _medicines(String userId) {
    return _firestore.collection('users').doc(userId).collection('medicines');
  }

  CollectionReference<Map<String, dynamic>> _logs(String userId) {
    return _firestore.collection('users').doc(userId).collection('medicineLogs');
  }

  String allocateLogId(String userId) => _logs(userId).doc().id;

  Future<MedicineLogPage> getLogsPage({
    required String userId,
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? pageCursor,
  }) async {
    Query<Map<String, dynamic>> q = _logs(userId).orderBy('loggedAt', descending: true);
    if (pageCursor != null) {
      q = q.startAfterDocument(pageCursor);
    }
    final snap = await q.limit(limit).get().timeout(_readTimeout);
    final docs = snap.docs;
    final items = docs.map(MedicineLogEntry.fromFirestore).toList();
    final lastDoc = docs.isEmpty ? null : docs.last;
    final hasMore = docs.length == limit;
    return MedicineLogPage(items: items, nextPageCursor: hasMore ? lastDoc : null);
  }

  /// Live dose log list (newest first).
  Stream<List<MedicineLogEntry>> watchLogs({
    required String userId,
    int limit = 200,
  }) {
    return _logs(userId)
        .orderBy('loggedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(MedicineLogEntry.fromFirestore).toList());
  }

  Future<void> _notifyInventoryAlerts(String userId, String medicineId) async {
    final medDoc = await _medicines(userId).doc(medicineId).get();
    if (medDoc.exists) {
      await MedicineNotificationHelper().checkAndCreateNotifications(
        [MedicineEntry.fromFirestore(medDoc)],
      );
    }
  }

  Future<MedicineLogWriteResponse> createEntry({
    required String userId,
    required MedicineLogEntry entry,
  }) async {
    try {
      await _firestore.runTransaction((txn) async {
        final medRef = _medicines(userId).doc(entry.medicineId);
        final logRef = _logs(userId).doc(entry.id);
        final medSnap = await txn.get(medRef);
        if (!medSnap.exists) {
          throw StateError('Medicine no longer in inventory.');
        }
        final med = MedicineEntry.fromFirestore(medSnap);
        final payload = entry.toCreateMapClientTs(DateTime.now());
        txn.set(logRef, payload);

        if (entry.status == MealStatuses.taken) {
          final u = entry.units;
          if (u > med.quantity) {
            throw StateError('Not enough stock (${med.quantity} available).');
          }
          final newQty = med.quantity - u;
          txn.update(medRef, {
            'quantity': newQty,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }).timeout(_writeTimeout);
      await _notifyInventoryAlerts(userId, entry.medicineId);
      return MedicineLogWriteResponse.success(entry.id);
    } catch (e) {
      return MedicineLogWriteResponse.failure(
        entry.id,
        e is StateError ? e.message : e.toString(),
      );
    }
  }

  Future<MedicineLogWriteResponse> updateEntry({
    required String userId,
    required MedicineLogEntry entry,
    required MedicineLogEntry previous,
  }) async {
    if (entry.medicineId != previous.medicineId) {
      return MedicineLogWriteResponse.failure(
        entry.id,
        'Cannot change medicine on an existing log.',
      );
    }
    try {
      await _firestore.runTransaction((txn) async {
        final medRef = _medicines(userId).doc(entry.medicineId);
        final logRef = _logs(userId).doc(entry.id);
        final medSnap = await txn.get(medRef);
        if (!medSnap.exists) {
          throw StateError('Medicine no longer in inventory.');
        }
        var med = MedicineEntry.fromFirestore(medSnap);
        // Revert previous "taken" deduction
        if (previous.status == MealStatuses.taken) {
          med = med.copyWith(quantity: med.quantity + previous.units);
        }
        // Apply new state
        if (entry.status == MealStatuses.taken) {
          if (entry.units > med.quantity) {
            throw StateError('Not enough stock (${med.quantity} available).');
          }
          med = med.copyWith(quantity: med.quantity - entry.units);
        }
        txn.update(logRef, entry.toUpdateMap());
        txn.update(medRef, {
          'quantity': med.quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }).timeout(_writeTimeout);
      await _notifyInventoryAlerts(userId, entry.medicineId);
      return MedicineLogWriteResponse.success(entry.id);
    } catch (e) {
      return MedicineLogWriteResponse.failure(
        entry.id,
        e is StateError ? e.message : e.toString(),
      );
    }
  }

  Future<MedicineLogWriteResponse> deleteEntry({
    required String userId,
    required MedicineLogEntry entry,
  }) async {
    try {
      await _firestore.runTransaction((txn) async {
        final logRef = _logs(userId).doc(entry.id);
        final logSnap = await txn.get(logRef);
        if (!logSnap.exists) {
          throw StateError('Log already removed.');
        }
        final data = logSnap.data();
        if (data == null) {
          throw StateError('Log already removed.');
        }
        final fromServer = MedicineLogEntry.fromMap(entry.id, data);
        final medRef = _medicines(userId).doc(fromServer.medicineId);
        if (fromServer.status == MealStatuses.taken) {
          final medSnap = await txn.get(medRef);
          if (medSnap.exists) {
            final med = MedicineEntry.fromFirestore(medSnap);
            txn.update(medRef, {
              'quantity': med.quantity + fromServer.units,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
        txn.delete(logRef);
      }).timeout(_writeTimeout);
      await _notifyInventoryAlerts(userId, entry.medicineId);
      return MedicineLogWriteResponse.success(entry.id);
    } catch (e) {
      return MedicineLogWriteResponse.failure(
        entry.id,
        e is StateError ? e.message : e.toString(),
      );
    }
  }
}
