import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/features/vitals/vital_entry.dart';

void main() {
  test('VitalEntry round-trips map fields', () {
    // Use local wall time: Firestore [Timestamp] round-trips through local dates.
    final recorded = DateTime(2026, 4, 20, 14, 30);
    final created = DateTime(2026, 4, 20, 14, 31);
    final map = <String, dynamic>{
      'recordedAt': Timestamp.fromDate(recorded),
      'systolicMmHg': 118,
      'diastolicMmHg': 76,
      'heartRateBpm': 72,
      'temperatureCelsius': 36.6,
      'weightKg': 70.5,
      'heightCm': 175,
      'glucoseMgDl': 96,
      'spo2Percent': 98,
      'notes': ' Felt fine ',
      'createdAt': Timestamp.fromDate(created),
      'updatedAt': Timestamp.fromDate(created),
    };

    final entry = VitalEntry.fromMap('v1', map);
    expect(entry.id, 'v1');
    expect(entry.recordedAt, recorded);
    expect(entry.systolicMmHg, 118);
    expect(entry.diastolicMmHg, 76);
    expect(entry.glucoseMgDl, 96.0);
    expect(entry.hasAnyData, isTrue);

    final createPayload = entry.toCreateMapClientTs(recorded);
    expect(createPayload['notes'], ' Felt fine ');
    expect(createPayload['systolicMmHg'], 118);
    expect(createPayload['glucoseMgDl'], 96.0);
  });

  test('VitalEntry hasAnyData is false when empty', () {
    final t = DateTime(2026, 1, 1);
    final e = VitalEntry(
      id: 'x',
      recordedAt: t,
      notes: '   ',
      createdAt: t,
      updatedAt: t,
    );
    expect(e.hasAnyData, isFalse);
  });

  test('VitalEntry hasAnyData is true with one measurement', () {
    final t = DateTime(2026, 1, 1);
    final e = VitalEntry(
      id: 'x',
      recordedAt: t,
      heartRateBpm: 60,
      notes: '',
      createdAt: t,
      updatedAt: t,
    );
    expect(e.hasAnyData, isTrue);
  });

  test('VitalEntry hasAnyData is true with glucose only', () {
    final t = DateTime(2026, 1, 1);

    final glucoseOnly = VitalEntry(
      id: 'glucose',
      recordedAt: t,
      glucoseMgDl: 102,
      notes: '',
      createdAt: t,
      updatedAt: t,
    );

    expect(glucoseOnly.hasAnyData, isTrue);
  });
}
