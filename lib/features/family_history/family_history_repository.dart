import 'package:cloud_firestore/cloud_firestore.dart';

import 'family_history_model.dart';

class FamilyHistoryRepository {
  FamilyHistoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String collection = 'family_history';

  Future<String> add(FamilyHistoryRecord r) async {
    final doc = await _firestore.collection(collection).add(r.toMap());
    return doc.id;
  }

  Future<void> update(FamilyHistoryRecord r) async {
    await _firestore.collection(collection).doc(r.id).update(r.toMap());
  }

  Future<void> delete(String id) async {
    await _firestore.collection(collection).doc(id).delete();
  }

  Stream<List<FamilyHistoryRecord>> watch(String userId) {
    return _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => FamilyHistoryRecord.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }
}
