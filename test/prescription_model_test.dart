import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/features/prescriptions/prescription.dart';

void main() {
  test('Prescription round-trips map fields', () {
    final now = DateTime.utc(2025, 6, 1, 12);
    final map = <String, dynamic>{
      'prescriptionType': 'Oral medication',
      'title': ' Lisinopril ',
      'description': '10mg daily',
      'prescribedDate': Timestamp.fromDate(now),
      'validUntil': Timestamp.fromDate(now),
      'attachments': [
        {'url': 'https://example.com/a.pdf', 'type': 'application/pdf'},
      ],
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };

    final p = Prescription.fromMap('rx1', map);
    expect(p.id, 'rx1');
    expect(p.title, ' Lisinopril ');
    expect(p.prescriptionType, 'Oral medication');
    expect(p.attachments.length, 1);
    expect(p.attachments.first.type, 'application/pdf');

    expect(p.toCreateMapClientTs(now)['prescriptionType'], 'Oral medication');
  });
}
