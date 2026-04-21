abstract final class MealStatuses {
  static const taken = 'Taken';
  static const missed = 'Missed';

  /// Future / planned — was stored as `Pending` in older app versions.
  static const scheduled = 'Scheduled';

  static const all = [taken, missed, scheduled];

  /// Maps legacy Firestore value `Pending` to [scheduled].
  static String normalizeFromStorage(String? raw) {
    if (raw == null || raw.isEmpty) return scheduled;
    if (raw == 'Pending') return scheduled;
    return raw;
  }
}
