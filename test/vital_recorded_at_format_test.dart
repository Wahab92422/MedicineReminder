import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/features/vitals/vital_recorded_at_format.dart';

void main() {
  test('formatVitalRecordedAt uses 12-hour clock with AM', () {
    expect(formatVitalRecordedAt(DateTime(2026, 3, 5, 8, 7)), '2026-03-05  8:07 AM');
  });

  test('formatVitalRecordedAt uses PM and 12 for noon', () {
    expect(formatVitalRecordedAt(DateTime(2026, 3, 5, 12, 0)), '2026-03-05  12:00 PM');
    expect(formatVitalRecordedAt(DateTime(2026, 3, 5, 14, 30)), '2026-03-05  2:30 PM');
  });

  test('formatVitalRecordedAt uses 12 for midnight', () {
    expect(formatVitalRecordedAt(DateTime(2026, 3, 5, 0, 5)), '2026-03-05  12:05 AM');
  });
}
