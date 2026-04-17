import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/features/labs/lab_report.dart';

void main() {
  test('LabReport round-trips map fields', () {
    final now = DateTime.utc(2025, 6, 1, 12);
    final map = <String, dynamic>{
      'reportType': 'Blood test',
      'title': ' CBC Panel ',
      'description': 'Routine',
      'testDate': Timestamp.fromDate(now),
      'reportDate': Timestamp.fromDate(now),
      'attachments': [
        {'url': 'https://example.com/a.pdf', 'type': 'application/pdf'},
      ],
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };

    final report = LabReport.fromMap('rep1', map);
    expect(report.id, 'rep1');
    expect(report.title, ' CBC Panel ');
    expect(report.attachments.length, 1);
    expect(report.attachments.first.type, 'application/pdf');

    expect(report.toCreateMapClientTs(now)['reportType'], 'Blood test');
  });
}
