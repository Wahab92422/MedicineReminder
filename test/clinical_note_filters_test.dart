import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/features/clinical_notes/clinical_note_entry.dart';
import 'package:medicine_app/features/clinical_notes/clinical_note_filters.dart';

ClinicalNoteEntry _note(DateTime notedAt) {
  final t = notedAt;
  return ClinicalNoteEntry(
    id: '1',
    title: 'T',
    body: 'B',
    notedAt: notedAt,
    createdAt: t,
    updatedAt: t,
  );
}

void main() {
  group('applyClinicalNoteListFilters', () {
    test('returns all items when no range set', () {
      final items = [_note(DateTime(2025, 3, 15))];
      expect(applyClinicalNoteListFilters(items), items);
    });

    test('excludes entries before from day', () {
      final from = DateTime(2025, 3, 10);
      final items = [
        _note(DateTime(2025, 3, 9, 23, 0)),
        _note(DateTime(2025, 3, 10, 8, 0)),
      ];
      final out = applyClinicalNoteListFilters(items, fromNotedDay: from);
      expect(out.length, 1);
      expect(out.single.notedAt, DateTime(2025, 3, 10, 8, 0));
    });

    test('excludes entries after to day', () {
      final to = DateTime(2025, 3, 10);
      final items = [
        _note(DateTime(2025, 3, 10, 18, 0)),
        _note(DateTime(2025, 3, 11, 0, 0)),
      ];
      final out = applyClinicalNoteListFilters(items, toNotedDay: to);
      expect(out.length, 1);
      expect(out.single.notedAt, DateTime(2025, 3, 10, 18, 0));
    });

    test('includes boundary times on from and to days', () {
      final from = DateTime(2025, 6, 1);
      final to = DateTime(2025, 6, 30);
      final items = [
        _note(DateTime(2025, 6, 1, 0, 0)),
        _note(DateTime(2025, 6, 30, 23, 59, 59)),
      ];
      final out = applyClinicalNoteListFilters(
        items,
        fromNotedDay: from,
        toNotedDay: to,
      );
      expect(out.length, 2);
    });
  });
}
