import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/features/family_history/family_history_model.dart';
import 'package:medicine_app/features/medical_history/medical_history_model.dart';
import 'package:medicine_app/features/surgical_history/surgical_history_model.dart';

void main() {
  group('SurgicalHistoryRecord', () {
    test('toMap / fromMap', () {
      final d = DateTime(2020, 5, 1);
      final r = SurgicalHistoryRecord(
        id: 'a',
        userId: 'u',
        procedureName: 'Appendectomy',
        procedureDate: d,
        surgeonName: 'Dr. Smith',
        facilityName: 'City Hospital',
        bodySite: 'RLQ',
        notes: 'Uneventful',
        createdAt: d,
        updatedAt: d,
      );
      final m = r.toMap();
      final back = SurgicalHistoryRecord.fromMap('a', m);
      expect(back.procedureName, 'Appendectomy');
      expect(back.procedureDate.year, 2020);
      expect(back.surgeonName, 'Dr. Smith');
    });
  });

  group('FamilyHistoryRecord', () {
    test('toMap / fromMap', () {
      final t = DateTime(2026, 1, 1);
      final r = FamilyHistoryRecord(
        id: 'b',
        userId: 'u',
        relationship: FamilyRelationship.mother,
        conditionName: 'HTN',
        ageAtOnset: 55,
        deceased: false,
        notes: '',
        createdAt: t,
        updatedAt: t,
      );
      final back = FamilyHistoryRecord.fromMap('b', r.toMap());
      expect(back.relationship, FamilyRelationship.mother);
      expect(back.conditionName, 'HTN');
      expect(back.ageAtOnset, 55);
    });
  });

  group('MedicalHistoryRecord', () {
    test('toMap / fromMap with optional onset', () {
      final t = DateTime(2026, 2, 1);
      final onset = DateTime(2015, 3, 15);
      final r = MedicalHistoryRecord(
        id: 'c',
        userId: 'u',
        conditionName: 'Asthma',
        status: MedicalConditionStatus.active,
        onsetDate: onset,
        notes: 'Inhaler PRN',
        createdAt: t,
        updatedAt: t,
      );
      final map = r.toMap();
      expect(map['onsetDate'], isA<Timestamp>());
      final back = MedicalHistoryRecord.fromMap('c', map);
      expect(back.conditionName, 'Asthma');
      expect(back.status, MedicalConditionStatus.active);
      expect(back.onsetDate?.year, 2015);
    });
  });
}
