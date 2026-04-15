import 'package:cloud_firestore/cloud_firestore.dart';

import 'history_model.dart';

class HistoryRepository {
  HistoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collection = 'medication_history';

  Future<String> addRecord(History history) async {
    final doc =
        await _firestore.collection(collection).add(history.toMap());
    return doc.id;
  }

  Future<void> updateRecord(History history) async {
    await _firestore
        .collection(collection)
        .doc(history.id)
        .update(history.toMap());
  }

  Future<void> deleteRecord(String id) async {
    await _firestore.collection(collection).doc(id).delete();
  }

  Stream<List<History>> getUserHistoryStream(String userId) {
    return _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => History.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }
}
