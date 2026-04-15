import 'package:flutter/material.dart';

/// Parsing and formatting for simple `H:mm` / `HH:mm` clock strings used in history.
class TimeClockService {
  TimeClockService._();

  static TimeOfDay parseScheduledClock(String s) {
    final p = s.trim().split(':');
    if (p.length >= 2) {
      final h = int.tryParse(p[0]) ?? 0;
      final m = int.tryParse(p[1]) ?? 0;
      return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
    }
    return TimeOfDay.now();
  }

  static String toHHmm(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
