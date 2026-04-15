import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/services/time_clock_service.dart';

void main() {
  group('TimeClockService', () {
    test('parseScheduledClock parses H:mm', () {
      final t = TimeClockService.parseScheduledClock('9:05');
      expect(t.hour, 9);
      expect(t.minute, 5);
    });

    test('parseScheduledClock clamps hour and minute', () {
      final t = TimeClockService.parseScheduledClock('25:99');
      expect(t.hour, 23);
      expect(t.minute, 59);
    });

    test('toHHmm pads zeros', () {
      expect(
        TimeClockService.toHHmm(const TimeOfDay(hour: 7, minute: 3)),
        '07:03',
      );
    });
  });
}
