import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lab_model.dart';
import 'lab_repository.dart';

final labRepositoryProvider = Provider<LabRepository>((ref) {
  return LabRepository();
});

final labReportsStreamProvider = StreamProvider<List<LabReport>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(const []);
  return ref.watch(labRepositoryProvider).getUserLabReportsStream(user.uid);
});

final labControllerProvider = Provider<LabController>((ref) {
  return LabController(ref.watch(labRepositoryProvider));
});

class LabController {
  LabController(this._repo);

  final LabRepository _repo;

  Future<String> addLabReport(LabReport report) => _repo.addLabReport(report);

  Future<void> updateLabReport(LabReport report) => _repo.updateLabReport(report);

  Future<void> deleteLabReport(LabReport report) => _repo.deleteLabReport(report);
}
