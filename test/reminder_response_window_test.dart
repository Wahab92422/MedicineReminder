import 'package:flutter_test/flutter_test.dart';

import 'package:medicine_app/services/scheduled_reminder_auto_miss_service.dart';
import 'package:medicine_app/utils/reminder_response_window.dart';

void main() {
  group('secondsRemainingInReminderResponseWindow', () {
    test('full grace when now equals scheduledAt', () {
      final at = DateTime(2026, 6, 1, 12, 0, 0);
      expect(
        secondsRemainingInReminderResponseWindow(
          scheduledAt: at,
          now: at,
        ),
        ScheduledReminderAutoMissService.gracePastScheduled.inSeconds,
      );
    });

    test('half grace when now is 6h after scheduledAt', () {
      final at = DateTime(2026, 6, 1, 12, 0, 0);
      final now = at.add(const Duration(hours: 6));
      expect(
        secondsRemainingInReminderResponseWindow(scheduledAt: at, now: now),
        const Duration(hours: 6).inSeconds,
      );
    });

    test('zero when past deadline', () {
      final at = DateTime(2026, 6, 1, 12, 0, 0);
      final now = at.add(
        ScheduledReminderAutoMissService.gracePastScheduled +
            const Duration(seconds: 1),
      );
      expect(
        secondsRemainingInReminderResponseWindow(scheduledAt: at, now: now),
        0,
      );
    });

    test('includes time before scheduledAt (deadline is scheduled + 12h)', () {
      final at = DateTime(2026, 6, 1, 12, 0, 0);
      final now = at.subtract(const Duration(hours: 1));
      expect(
        secondsRemainingInReminderResponseWindow(scheduledAt: at, now: now),
        const Duration(hours: 13).inSeconds,
      );
    });
  });

  group('formatReminderResponseCountdown', () {
    test('MM:SS under one hour', () {
      expect(formatReminderResponseCountdown(125), '02:05');
      expect(formatReminderResponseCountdown(0), '00:00');
    });

    test('H:MM:SS at one hour or more', () {
      expect(formatReminderResponseCountdown(3600), '1:00:00');
      expect(formatReminderResponseCountdown(3661), '1:01:01');
    });
  });
}
