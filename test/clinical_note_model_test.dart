import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/features/clinical_notes/clinical_note_model.dart';

void main() {
  group('ClinicalNote', () {
    test('toMap / fromMap roundtrip', () {
      final encounter = DateTime(2026, 7, 10, 15, 0);
      final created = DateTime(2026, 7, 10, 16, 0);
      final updated = DateTime(2026, 7, 11, 9, 30);

      final original = ClinicalNote(
        id: 'n1',
        userId: 'u1',
        title: 'Cardiology follow-up',
        body: 'Patient reports improved exercise tolerance.',
        category: ClinicalNoteCategory.progress,
        encounterAt: encounter,
        createdAt: created,
        updatedAt: updated,
      );

      final map = original.toMap();
      final restored = ClinicalNote.fromMap('n1', map);

      expect(restored.id, 'n1');
      expect(restored.userId, original.userId);
      expect(restored.title, original.title);
      expect(restored.body, original.body);
      expect(restored.category, original.category);
      expect(restored.encounterAt, original.encounterAt);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
    });

    test('fromMap defaults unknown category to general', () {
      final map = {
        'userId': 'u',
        'title': 'T',
        'body': 'B',
        'category': 'not_a_category',
        'encounterAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 2)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 3)),
      };
      final n = ClinicalNote.fromMap('id', map);
      expect(n.category, ClinicalNoteCategory.general);
    });
  });
}
