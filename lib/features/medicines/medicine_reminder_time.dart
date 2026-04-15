/// Encode/decode medicine reminder times for Firestore.
///
/// New format: local [DateTime] as [DateTime.toIso8601String] (includes date + clock).
/// Legacy: `"HH:mm"` still supported for older documents.
abstract final class MedicineReminderTime {
  MedicineReminderTime._();

  static String encodeLocal(DateTime local) {
    return local.toIso8601String();
  }

  /// Returns a local [DateTime] with the intended calendar date and clock time.
  static DateTime? decodeToLocal(String stored) {
    final t = stored.trim();
    if (t.isEmpty) return null;

    if (t.contains('T')) {
      final parsed = DateTime.tryParse(t);
      return parsed?.toLocal();
    }

    final parts = t.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;

    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day, h, m);
  }

  static String formatDateOnly(DateTime local) {
    final mo = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '${local.year}-$mo-$d';
  }

  static String formatDateAndTime(DateTime local) {
    final y = local.year;
    final mo = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final mi = local.minute.toString().padLeft(2, '0');
    return '$y-$mo-$d $h:$mi';
  }

  /// Compact clock for list tiles (24h).
  static String formatClockHm(String stored) {
    final dt = decodeToLocal(stored);
    if (dt == null) return stored;
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
