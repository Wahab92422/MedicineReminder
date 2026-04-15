import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'clinical_note_model.dart';
import 'clinical_note_repository.dart';

final clinicalNoteRepositoryProvider = Provider<ClinicalNoteRepository>((ref) {
  return ClinicalNoteRepository();
});

final clinicalNotesStreamProvider = StreamProvider<List<ClinicalNote>>((ref) {
  final repo = ref.watch(clinicalNoteRepositoryProvider);
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value(const []);
  }
  return repo.watchNotes(user.uid);
});

final clinicalNoteControllerProvider =
    Provider<ClinicalNoteController>((ref) {
  return ClinicalNoteController(ref.watch(clinicalNoteRepositoryProvider));
});

class ClinicalNoteController {
  ClinicalNoteController(this._repo);

  final ClinicalNoteRepository _repo;

  Future<String> addNote(ClinicalNote note) => _repo.addNote(note);

  Future<void> updateNote(ClinicalNote note) => _repo.updateNote(note);

  Future<void> deleteNote(String id) => _repo.deleteNote(id);
}
