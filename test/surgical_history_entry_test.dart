import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/features/surgical_history/surgical_history_entry.dart';

void main() {
  test('SurgicalHistoryEntry round-trips map fields', () {
    final recorded = DateTime(2026, 3, 10);
    final created = DateTime(2026, 3, 11);
    final map = <String, dynamic>{
      'recordedAt': Timestamp.fromDate(recorded),
      'category': 'Orthopedic',
      'title': ' Knee scope ',
      'details': 'Outpatient',
      'notes': '',
      'createdAt': Timestamp.fromDate(created),
      'updatedAt': Timestamp.fromDate(created),
    };

    final entry = SurgicalHistoryEntry.fromMap('s1', map);
    expect(entry.id, 's1');
    expect(entry.title, ' Knee scope ');
    expect(entry.category, 'Orthopedic');

    final createPayload = entry.toCreateMapClientTs(recorded);
    expect(createPayload['category'], 'Orthopedic');
  });
}
