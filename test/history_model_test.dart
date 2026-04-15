import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/features/history/history_model.dart';

void main() {
  test('History toMap/fromMap roundtrip', () {
    final created = DateTime.utc(2026, 3, 1, 12, 30);
    final taken = DateTime.utc(2026, 3, 1, 12, 45);
    final original = History(
      id: 'doc1',
      userId: 'u1',
      medicineId: 'm1',
      medicineName: 'Aspirin',
      dose: '100mg',
      scheduledTime: '08:00',
      takenTime: taken,
      status: 'taken',
      createdAt: created,
    );

    final map = original.toMap();
    final restored = History.fromMap('doc1', map);

    expect(restored.id, 'doc1');
    expect(restored.userId, 'u1');
    expect(restored.medicineId, 'm1');
    expect(restored.medicineName, 'Aspirin');
    expect(restored.dose, '100mg');
    expect(restored.scheduledTime, '08:00');
    expect(restored.takenTime?.toUtc(), taken.toUtc());
    expect(restored.status, 'taken');
    expect(restored.createdAt.toUtc(), created.toUtc());
    expect(map['takenTime'], isA<Timestamp>());
  });

  test('copyWith clears takenTime when requested', () {
    final h = History(
      id: '1',
      userId: 'u',
      medicineId: 'm',
      medicineName: 'X',
      dose: '1',
      scheduledTime: '09:00',
      takenTime: DateTime.now(),
      status: 'taken',
      createdAt: DateTime.now(),
    );
    final m = h.copyWith(status: 'missed', clearTakenTime: true);
    expect(m.takenTime, isNull);
    expect(m.status, 'missed');
  });
}
