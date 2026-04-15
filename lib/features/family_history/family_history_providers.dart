import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'family_history_model.dart';
import 'family_history_repository.dart';

final familyHistoryRepositoryProvider =
    Provider<FamilyHistoryRepository>((ref) => FamilyHistoryRepository());

final familyHistoryStreamProvider = StreamProvider<List<FamilyHistoryRecord>>((ref) {
  final repo = ref.watch(familyHistoryRepositoryProvider);
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(const []);
  return repo.watch(user.uid);
});

final familyHistoryControllerProvider = Provider<FamilyHistoryController>((ref) {
  return FamilyHistoryController(ref.watch(familyHistoryRepositoryProvider));
});

class FamilyHistoryController {
  FamilyHistoryController(this._repo);
  final FamilyHistoryRepository _repo;

  Future<String> add(FamilyHistoryRecord r) => _repo.add(r);
  Future<void> update(FamilyHistoryRecord r) => _repo.update(r);
  Future<void> delete(String id) => _repo.delete(id);
}
