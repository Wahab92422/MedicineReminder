import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'history_model.dart';
import 'history_repository.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository();
});

final medicationHistoryStreamProvider = StreamProvider<List<History>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value(const []);
  }
  return ref.watch(historyRepositoryProvider).getUserHistoryStream(user.uid);
});

final historyControllerProvider = Provider<HistoryController>((ref) {
  return HistoryController(ref.watch(historyRepositoryProvider));
});

class HistoryController {
  HistoryController(this._repo);

  final HistoryRepository _repo;

  Future<String> addHistory(History history) => _repo.addRecord(history);

  Future<void> updateHistory(History history) => _repo.updateRecord(history);

  Future<void> deleteHistory(String id) => _repo.deleteRecord(id);
}
