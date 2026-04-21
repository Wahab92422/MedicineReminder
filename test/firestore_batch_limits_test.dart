import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/features/notifications/firestore_batch_limits.dart';

void main() {
  test('firestoreBatchCommitCount matches 500-op chunks', () {
    expect(firestoreBatchCommitCount(0), 0);
    expect(firestoreBatchCommitCount(1), 1);
    expect(firestoreBatchCommitCount(500), 1);
    expect(firestoreBatchCommitCount(501), 2);
    expect(firestoreBatchCommitCount(1000), 2);
  });
}
