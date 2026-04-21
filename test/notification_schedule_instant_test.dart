import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/services/notification_schedule_instant.dart';
import 'package:timezone/data/latest.dart' as tzdata;

void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
  });

  test('tzUtcInstantForSchedule matches UTC DateTime epoch', () {
    final when = DateTime.utc(2024, 6, 15, 14, 30);
    final scheduled = tzUtcInstantForSchedule(when);
    expect(scheduled.timeZoneName, 'UTC');
    expect(scheduled.millisecondsSinceEpoch, when.millisecondsSinceEpoch);
  });

  test('tzUtcInstantForSchedule preserves local DateTime instant', () {
    final when = DateTime(2024, 6, 15, 10, 0);
    final scheduled = tzUtcInstantForSchedule(when);
    expect(scheduled.millisecondsSinceEpoch, when.millisecondsSinceEpoch);
  });
}
