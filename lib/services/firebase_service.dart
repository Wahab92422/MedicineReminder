import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final CollectionReference medicines = FirebaseFirestore.instance.collection(
    'medicines',
  );

  Future<void> addMedicine(Map<String, dynamic> data) async {
    await medicines.add(data);
  }

  Stream<QuerySnapshot> getMedicines() {
    return medicines.snapshots();
  }
}
