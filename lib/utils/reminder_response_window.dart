import '../services/scheduled_reminder_auto_miss_service.dart';

/// Seconds until [scheduledAt] + [ScheduledReminderAutoMissService.gracePastScheduled].
/// Returns `0` if that instant is in the past.
int secondsRemainingInReminderResponseWindow({
  required DateTime scheduledAt,
  required DateTime now,
}) {
  final deadline = scheduledAt.add(
    ScheduledReminderAutoMissService.gracePastScheduled,
  );
  final diff = deadline.difference(now);
  if (diff.isNegative) return 0;
  return diff.inSeconds;
}

/// `HH:MM:SS` if ≥1 hour left, else `MM:SS`.
String formatReminderResponseCountdown(int totalSeconds) {
  if (totalSeconds <= 0) return '00:00';
  final d = Duration(seconds: totalSeconds);
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
