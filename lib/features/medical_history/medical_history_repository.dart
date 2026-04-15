import 'package:cloud_firestore/cloud_firestore.dart';

import 'medical_history_model.dart';

class MedicalHistoryRepository {
  MedicalHistoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String collection = 'medical_history';

  Future<String> add(MedicalHistoryRecord r) async {
    final doc = await _firestore.collection(collection).add(r.toMap());
    return doc.id;
  }

  Future<void> update(MedicalHistoryRecord r) async {
    await _firestore.collection(collection).doc(r.id).update(r.toMap());
  }

  Future<void> delete(String id) async {
    await _firestore.collection(collection).doc(id).delete();
  }

  Stream<List<MedicalHistoryRecord>> watch(String userId) {
    return _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => MedicalHistoryRecord.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }
}
