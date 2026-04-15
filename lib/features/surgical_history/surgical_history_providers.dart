import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'surgical_history_model.dart';
import 'surgical_history_repository.dart';

final surgicalHistoryRepositoryProvider =
    Provider<SurgicalHistoryRepository>((ref) => SurgicalHistoryRepository());

final surgicalHistoryStreamProvider =
    StreamProvider<List<SurgicalHistoryRecord>>((ref) {
  final repo = ref.watch(surgicalHistoryRepositoryProvider);
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(const []);
  return repo.watch(user.uid);
});

final surgicalHistoryControllerProvider =
    Provider<SurgicalHistoryController>((ref) {
  return SurgicalHistoryController(ref.watch(surgicalHistoryRepositoryProvider));
});

class SurgicalHistoryController {
  SurgicalHistoryController(this._repo);
  final SurgicalHistoryRepository _repo;

  Future<String> add(SurgicalHistoryRecord r) => _repo.add(r);
  Future<void> update(SurgicalHistoryRecord r) => _repo.update(r);
  Future<void> delete(String id) => _repo.delete(id);
}
