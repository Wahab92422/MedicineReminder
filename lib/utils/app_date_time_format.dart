import 'package:intl/intl.dart';

/// US-style 12-hour (AM/PM) dates and times used app-wide.
abstract final class AppDateTimeFormat {
  static final DateFormat _dateMedium = DateFormat('MMM d, y', 'en_US');
  static final DateFormat _time12 = DateFormat('h:mm a', 'en_US');
  static final DateFormat _dateTime12 = DateFormat("MMM d, y 'at' h:mm a", 'en_US');

  static String formatDate(DateTime d) => _dateMedium.format(d.toLocal());

  static String formatTime(DateTime d) => _time12.format(d.toLocal());

  static String formatDateTime(DateTime d) => _dateTime12.format(d.toLocal());

  /// Short label for alert list rows (matches prior today/yesterday behavior).
  static String formatShortRelativeWithTime(DateTime date) {
    final local = date.toLocal();
    final difference = DateTime.now().difference(local);
    final t = formatTime(local);
    if (difference.inDays == 0) {
      return 'Today at $t';
    }
    if (difference.inDays == 1) {
      return 'Yesterday at $t';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }
    return formatDate(local);
  }
}
