abstract final class AppointmentStatuses {
  static const attended = 'Attended';
  static const missed = 'Missed';
  /// Upcoming visit — was stored as `Pending` in older app versions.
  static const scheduled = 'Scheduled';

  static const all = [attended, missed, scheduled];

  /// Maps legacy Firestore value `Pending` to [scheduled].
  static String normalizeFromStorage(String? raw) {
    if (raw == null || raw.isEmpty) return scheduled;
    if (raw == 'Pending') return scheduled;
    return raw;
  }
}
