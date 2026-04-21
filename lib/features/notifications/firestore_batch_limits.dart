/// Firestore batch writes are limited per commit ([maxBatchWrites]).
const int kFirestoreMaxBatchWrites = 500;

/// How many [batch.commit] calls are needed for [operationCount] updates (0 if none).
int firestoreBatchCommitCount(int operationCount) {
  if (operationCount <= 0) {
    return 0;
  }
  return (operationCount + kFirestoreMaxBatchWrites - 1) ~/ kFirestoreMaxBatchWrites;
}
