import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/services/notification_android_schedule_mode.dart';

void main() {
  test('uses exactAllowWhileIdle when exact alarms are allowed', () {
    expect(
      androidReminderScheduleModeForExactAlarmPermission(true),
      AndroidScheduleMode.exactAllowWhileIdle,
    );
  });

  test('uses inexactAllowWhileIdle when exact alarms are denied or unknown', () {
    expect(
      androidReminderScheduleModeForExactAlarmPermission(false),
      AndroidScheduleMode.inexactAllowWhileIdle,
    );
    expect(
      androidReminderScheduleModeForExactAlarmPermission(null),
      AndroidScheduleMode.inexactAllowWhileIdle,
    );
  });
}
