import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'appointment_model.dart';
import 'appointment_repository.dart';

final appointmentRepositoryProvider =
    Provider<AppointmentRepository>((ref) => AppointmentRepository());

final appointmentsStreamProvider =
    StreamProvider<List<AppointmentRecord>>((ref) {
  final repo = ref.watch(appointmentRepositoryProvider);
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(const []);
  return repo.watch(user.uid);
});

final appointmentControllerProvider =
    Provider<AppointmentController>((ref) {
  return AppointmentController(ref.watch(appointmentRepositoryProvider));
});

class AppointmentController {
  AppointmentController(this._repo);
  final AppointmentRepository _repo;

  Future<String> add(AppointmentRecord r) => _repo.add(r);

  Future<void> update(AppointmentRecord r) => _repo.update(r);

  Future<void> delete(String id) => _repo.delete(id);

  Future<void> setStatus({
    required AppointmentRecord record,
    required AppointmentStatus status,
  }) async {
    final updated = record.copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );
    await _repo.update(updated);
  }
}
