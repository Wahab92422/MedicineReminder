import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/services/scheduled_reminder_auto_miss_service.dart';

void main() {
  test('12h window: list shows scheduledAt >= now - grace; auto-miss uses same grace', () {
    final now = DateTime(2026, 1, 10, 15, 0);
    final windowStart =
        now.subtract(ScheduledReminderAutoMissService.gracePastScheduled);
    expect(windowStart, DateTime(2026, 1, 10, 3, 0));
    expect(ScheduledReminderAutoMissService.gracePastScheduled.inHours, 12);

    bool inListWindow(DateTime scheduledAt) => !scheduledAt.isBefore(windowStart);
    bool shouldAutoMiss(DateTime scheduledAt) =>
        scheduledAt.isBefore(windowStart);

    expect(inListWindow(DateTime(2026, 1, 10, 3, 0)), true);
    expect(shouldAutoMiss(DateTime(2026, 1, 10, 3, 0)), false);
    expect(inListWindow(DateTime(2026, 1, 10, 2, 59)), false);
    expect(shouldAutoMiss(DateTime(2026, 1, 10, 2, 59)), true);
  });
}
