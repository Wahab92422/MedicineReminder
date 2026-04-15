import 'package:cloud_firestore/cloud_firestore.dart';

import 'vital_entry_model.dart';

class VitalRepository {
  VitalRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collection = 'vitals';

  Future<String> addVital(VitalEntry vital) async {
    final doc = await _firestore.collection(collection).add(vital.toMap());
    return doc.id;
  }

  Future<void> updateVital(VitalEntry vital) async {
    await _firestore
        .collection(collection)
        .doc(vital.id)
        .update(vital.toMap());
  }

  Future<void> deleteVital(String id) async {
    await _firestore.collection(collection).doc(id).delete();
  }

  Stream<List<VitalEntry>> watchVitals(String userId) {
    return _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => VitalEntry.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      return list;
    });
  }
}
