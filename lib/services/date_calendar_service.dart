/// Pure calendar helpers for grouping lists by local calendar day.
class DateCalendarService {
  DateCalendarService._();

  /// Stable `yyyy-MM-dd` key for a local calendar date.
  static String dateKey(DateTime local) {
    final y = local.year;
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Human label for a [dateKey] relative to [now] (defaults to `DateTime.now()`).
  static String sectionTitle(String key, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final today = dateKey(DateTime(n.year, n.month, n.day));
    final y = n.subtract(const Duration(days: 1));
    final yesterday = dateKey(DateTime(y.year, y.month, y.day));
    if (key == today) return 'Today';
    if (key == yesterday) return 'Yesterday';
    return key;
  }

  /// Groups [items] by local calendar day of [localDateTime], newest day first.
  ///
  /// [localDateTime] should return the instant in local time (e.g. `utc.toLocal()`).
  static List<({String key, List<T> items})> groupByLocalDateKey<T>(
    Iterable<T> items,
    DateTime Function(T) localDateTime,
  ) {
    final map = <String, List<T>>{};
    for (final item in items) {
      final k = dateKey(localDateTime(item));
      map.putIfAbsent(k, () => []).add(item);
    }
    final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return [for (final k in keys) (key: k, items: map[k]!)];
  }
}
