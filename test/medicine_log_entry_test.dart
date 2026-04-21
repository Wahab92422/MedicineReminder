import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medicine_app/features/meals/meal_statuses.dart';
import 'package:medicine_app/features/medicine_logs/medicine_log_entry.dart';

void main() {
  group('MedicineLogEntry.fromMap', () {
    test('parses document fields', () {
      final t = DateTime(2025, 3, 15, 9, 30);
      final e = MedicineLogEntry.fromMap('lid', {
        'medicineId': 'mid',
        'medicineName': 'Aspirin',
        'loggedAt': Timestamp.fromDate(t),
        'status': MealStatuses.taken,
        'units': 2,
        'notes': 'after food',
        'createdAt': Timestamp.fromDate(t),
        'updatedAt': Timestamp.fromDate(t),
      });
      expect(e.id, 'lid');
      expect(e.medicineId, 'mid');
      expect(e.status, MealStatuses.taken);
      expect(e.units, 2);
      expect(e.isTaken, true);
    });
  });
}
