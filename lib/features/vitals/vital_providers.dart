import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'vital_entry_model.dart';
import 'vital_repository.dart';

final vitalRepositoryProvider = Provider<VitalRepository>((ref) {
  return VitalRepository();
});

final vitalControllerProvider = Provider<VitalController>((ref) {
  return VitalController(ref.watch(vitalRepositoryProvider));
});

final vitalStreamProvider = StreamProvider<List<VitalEntry>>((ref) {
  final repo = ref.watch(vitalRepositoryProvider);
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return const Stream.empty();
  return repo.watchVitals(user.uid);
});

class VitalController {
  VitalController(this._repo);

  final VitalRepository _repo;

  Future<void> updateVital(VitalEntry entry) => _repo.updateVital(entry);

  Future<void> deleteVital(String id) => _repo.deleteVital(id);
}
