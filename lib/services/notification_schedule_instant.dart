import 'package:timezone/timezone.dart' as tz;

/// Same instant as [when], as a [tz.TZDateTime] in UTC, for use with
/// `FlutterLocalNotificationsPlugin.zonedSchedule` without [tz.local] or
/// platform timezone plugins.
tz.TZDateTime tzUtcInstantForSchedule(DateTime when) {
  return tz.TZDateTime.fromMillisecondsSinceEpoch(
    tz.UTC,
    when.millisecondsSinceEpoch,
  );
}
