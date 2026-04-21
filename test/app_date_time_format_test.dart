import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/utils/app_date_time_format.dart';

void main() {
  test('formatTime uses 12-hour AM/PM', () {
    final s = AppDateTimeFormat.formatTime(DateTime(2026, 4, 21, 14, 5));
    expect(s.contains('PM') || s.contains('AM'), isTrue);
    expect(s.contains('14:'), isFalse);
  });

  test('formatDateTime includes month name and AM/PM', () {
    final s = AppDateTimeFormat.formatDateTime(DateTime(2026, 4, 21, 9, 30));
    expect(s.toLowerCase().contains('apr'), isTrue);
    expect(s.contains('AM') || s.contains('PM'), isTrue);
  });
}
