import 'package:cloud_firestore/cloud_firestore.dart';
import 'medicine_model.dart';

class MedicineRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String collection = "medicines";

  Future<String> addMedicine(Medicine medicine) async {
    final doc = await _firestore.collection(collection).add(medicine.toMap());
    return doc.id;
  }

  Stream<List<Medicine>> getMedicines(String userId) {
    return _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Medicine.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  Future<void> deleteMedicine(String id) async {
    await _firestore.collection(collection).doc(id).delete();
  }

  Future<void> updateMedicine({
    required String id,
    required String name,
    required String dose,
    required String time,
    required int quantityOnHand,
    int? lowStockThreshold,
    required String inventoryUnit,
  }) async {
    await _firestore.collection(collection).doc(id).update({
      'name': name,
      'dose': dose,
      'time': time,
      'quantityOnHand': quantityOnHand,
      'lowStockThreshold': lowStockThreshold,
      'inventoryUnit': inventoryUnit,
    });
  }

  /// Clamps result to >= 0.
  Future<void> adjustQuantity({required String id, required int delta}) async {
    final ref = _firestore.collection(collection).doc(id);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final raw = snap.data()?['quantityOnHand'];
      final current = (raw is num) ? raw.toInt() : 0;
      final next = (current + delta).clamp(0, 999999);
      tx.update(ref, {'quantityOnHand': next});
    });
  }
}
