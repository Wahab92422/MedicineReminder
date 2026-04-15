import 'package:cloud_firestore/cloud_firestore.dart';

import 'appointment_model.dart';

class AppointmentRepository {
  AppointmentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String collection = 'appointments';

  Future<String> add(AppointmentRecord r) async {
    final doc = await _firestore.collection(collection).add(r.toMap());
    return doc.id;
  }

  Future<void> update(AppointmentRecord r) async {
    await _firestore.collection(collection).doc(r.id).update(r.toMap());
  }

  Future<void> delete(String id) async {
    await _firestore.collection(collection).doc(id).delete();
  }

  Stream<List<AppointmentRecord>> watch(String userId) {
    return _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppointmentRecord.fromMap(doc.id, doc.data()))
          .toList();
    });
  }
}
