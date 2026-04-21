import 'clinical_note_entry.dart';

/// True when [value] is strictly before the start of [day] (local calendar).
bool isTimestampBeforeStartOfDay(DateTime value, DateTime day) {
  final start = DateTime(day.year, day.month, day.day);
  return value.isBefore(start);
}

/// True when [value] is strictly after the end of [day] (local calendar).
bool isTimestampAfterEndOfDay(DateTime value, DateTime day) {
  final end = DateTime(day.year, day.month, day.day, 23, 59, 59, 999);
  return value.isAfter(end);
}

/// Client-side filters for the clinical notes list (noted-at date range).
List<ClinicalNoteEntry> applyClinicalNoteListFilters(
  List<ClinicalNoteEntry> items, {
  DateTime? fromNotedDay,
  DateTime? toNotedDay,
}) {
  return items.where((entry) {
    if (fromNotedDay != null &&
        isTimestampBeforeStartOfDay(entry.notedAt, fromNotedDay)) {
      return false;
    }
    if (toNotedDay != null &&
        isTimestampAfterEndOfDay(entry.notedAt, toNotedDay)) {
      return false;
    }
    return true;
  }).toList();
}
