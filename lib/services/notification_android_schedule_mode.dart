import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Android: [exactAllowWhileIdle] requires
/// [AlarmManager.canScheduleExactAlarms]. If that is false, scheduling with
/// that mode throws and no notification is registered — use
/// [inexactAllowWhileIdle] instead (slightly less precise timing).
AndroidScheduleMode androidReminderScheduleModeForExactAlarmPermission(
  bool? canScheduleExactNotifications,
) {
  return canScheduleExactNotifications == true
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;
}
