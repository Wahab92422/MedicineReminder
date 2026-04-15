import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/features/medicines/medicine_reminder_time.dart';

void main() {
  test('encode/decode roundtrip preserves local components', () {
    final original = DateTime(2026, 6, 15, 14, 30);
    final stored = MedicineReminderTime.encodeLocal(original);
    final decoded = MedicineReminderTime.decodeToLocal(stored);
    expect(decoded, isNotNull);
    expect(decoded!.year, original.year);
    expect(decoded.month, original.month);
    expect(decoded.day, original.day);
    expect(decoded.hour, original.hour);
    expect(decoded.minute, original.minute);
  });

  test('legacy HH:mm decodes to today with that clock', () {
    final decoded = MedicineReminderTime.decodeToLocal('08:45');
    expect(decoded, isNotNull);
    expect(decoded!.hour, 8);
    expect(decoded.minute, 45);
  });

  test('formatClockHm handles legacy string', () {
    expect(MedicineReminderTime.formatClockHm('09:05'), '09:05');
  });

  test('formatDateOnly', () {
    expect(
      MedicineReminderTime.formatDateOnly(DateTime(2026, 3, 7)),
      '2026-03-07',
    );
  });
}
