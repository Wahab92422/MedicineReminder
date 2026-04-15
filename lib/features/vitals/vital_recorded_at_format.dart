/// Shared display format for when a vital was recorded (local time, 12-hour AM/PM).
String formatVitalRecordedAt(DateTime dt) {
  final l = dt.toLocal();
  final mo = l.month.toString().padLeft(2, '0');
  final day = l.day.toString().padLeft(2, '0');
  var hour12 = l.hour % 12;
  if (hour12 == 0) hour12 = 12;
  final period = l.hour < 12 ? 'AM' : 'PM';
  final min = l.minute.toString().padLeft(2, '0');
  return '${l.year}-$mo-$day  $hour12:$min $period';
}
