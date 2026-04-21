import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/features/clinical_notes/clinical_note_entry.dart';

void main() {
  test('ClinicalNoteEntry round-trips map fields', () {
    final noted = DateTime(2026, 3, 15, 10, 0);
    final created = DateTime(2026, 3, 15, 10, 5);
    final map = <String, dynamic>{
      'title': 'Cardiology visit',
      'body': 'Discussed BP targets.',
      'notedAt': Timestamp.fromDate(noted),
      'createdAt': Timestamp.fromDate(created),
      'updatedAt': Timestamp.fromDate(created),
    };

    final entry = ClinicalNoteEntry.fromMap('n1', map);
    expect(entry.id, 'n1');
    expect(entry.title, 'Cardiology visit');
    expect(entry.body, 'Discussed BP targets.');
    expect(entry.notedAt, noted);

    final createPayload = entry.toCreateMapClientTs(created);
    expect(createPayload['title'], 'Cardiology visit');
    expect(createPayload['body'], 'Discussed BP targets.');
  });
}
