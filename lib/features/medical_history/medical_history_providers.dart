import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'medical_history_model.dart';
import 'medical_history_repository.dart';

final medicalHistoryRepositoryProvider =
    Provider<MedicalHistoryRepository>((ref) => MedicalHistoryRepository());

final medicalHistoryStreamProvider =
    StreamProvider<List<MedicalHistoryRecord>>((ref) {
  final repo = ref.watch(medicalHistoryRepositoryProvider);
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(const []);
  return repo.watch(user.uid);
});

final medicalHistoryControllerProvider =
    Provider<MedicalHistoryController>((ref) {
  return MedicalHistoryController(ref.watch(medicalHistoryRepositoryProvider));
});

class MedicalHistoryController {
  MedicalHistoryController(this._repo);
  final MedicalHistoryRepository _repo;

  Future<String> add(MedicalHistoryRecord r) => _repo.add(r);
  Future<void> update(MedicalHistoryRecord r) => _repo.update(r);
  Future<void> delete(String id) => _repo.delete(id);
}
