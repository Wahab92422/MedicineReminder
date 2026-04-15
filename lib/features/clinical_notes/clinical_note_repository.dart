import 'package:cloud_firestore/cloud_firestore.dart';

import 'clinical_note_model.dart';

class ClinicalNoteRepository {
  ClinicalNoteRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collection = 'clinical_notes';

  Future<String> addNote(ClinicalNote note) async {
    final doc = await _firestore.collection(collection).add(note.toMap());
    return doc.id;
  }

  Future<void> updateNote(ClinicalNote note) async {
    await _firestore.collection(collection).doc(note.id).update(note.toMap());
  }

  Future<void> deleteNote(String id) async {
    await _firestore.collection(collection).doc(id).delete();
  }

  Stream<List<ClinicalNote>> watchNotes(String userId) {
    return _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ClinicalNote.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }
}
