import 'package:cloud_firestore/cloud_firestore.dart';

import 'surgical_history_model.dart';

class SurgicalHistoryRepository {
  SurgicalHistoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String collection = 'surgical_history';

  Future<String> add(SurgicalHistoryRecord r) async {
    final doc = await _firestore.collection(collection).add(r.toMap());
    return doc.id;
  }

  Future<void> update(SurgicalHistoryRecord r) async {
    await _firestore.collection(collection).doc(r.id).update(r.toMap());
  }

  Future<void> delete(String id) async {
    await _firestore.collection(collection).doc(id).delete();
  }

  Stream<List<SurgicalHistoryRecord>> watch(String userId) {
    return _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => SurgicalHistoryRecord.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => b.procedureDate.compareTo(a.procedureDate));
      return list;
    });
  }
}
