import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/features/history/history_model.dart';
import 'package:medicine_app/services/date_calendar_service.dart';

void main() {
  group('DateCalendarService', () {
    test('dateKey pads month and day', () {
      expect(
        DateCalendarService.dateKey(DateTime(2024, 3, 5)),
        '2024-03-05',
      );
    });

    test('sectionTitle returns Today and Yesterday', () {
      final now = DateTime(2026, 4, 15, 12);
      final todayKey = DateCalendarService.dateKey(DateTime(2026, 4, 15));
      final yesterdayKey = DateCalendarService.dateKey(DateTime(2026, 4, 14));
      expect(DateCalendarService.sectionTitle(todayKey, now: now), 'Today');
      expect(DateCalendarService.sectionTitle(yesterdayKey, now: now), 'Yesterday');
      expect(DateCalendarService.sectionTitle('2026-04-10', now: now), '2026-04-10');
    });

    test('groupByLocalDateKey sorts newest day first', () {
      final a = _hist('a', DateTime(2026, 1, 1, 10));
      final b = _hist('b', DateTime(2026, 1, 3, 10));
      final c = _hist('c', DateTime(2026, 1, 3, 8));
      final groups = DateCalendarService.groupByLocalDateKey<History>(
        [a, b, c],
        (h) => h.createdAt,
      );
      expect(groups.length, 2);
      expect(groups[0].key, '2026-01-03');
      expect(groups[0].items.map((e) => e.id), ['b', 'c']);
      expect(groups[1].key, '2026-01-01');
      expect(groups[1].items.single.id, 'a');
    });
  });
}

History _hist(String id, DateTime createdAt) => History(
      id: id,
      userId: 'u',
      medicineId: 'm',
      medicineName: 'x',
      dose: '1',
      scheduledTime: '09:00',
      takenTime: null,
      status: 'missed',
      createdAt: createdAt,
    );
