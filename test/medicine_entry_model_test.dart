import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/features/medicine_inventory/medicine_entry.dart';

void main() {
  test('MedicineEntry round-trips attachmentUrl from map', () {
    final expiry = DateTime(2027, 1, 15);
    final created = DateTime(2026, 4, 1);
    final map = <String, dynamic>{
      'name': 'Aspirin',
      'category': 'Pain',
      'dosage': '500mg',
      'quantity': 20,
      'unit': 'tablets',
      'expiryDate': Timestamp.fromDate(expiry),
      'lowStockThreshold': 5,
      'notes': '',
      'attachmentUrl': 'https://example.com/a.png',
      'createdAt': Timestamp.fromDate(created),
      'updatedAt': Timestamp.fromDate(created),
    };

    final entry = MedicineEntry.fromMap('m1', map);
    expect(entry.attachmentUrl, 'https://example.com/a.png');

    final createPayload = entry.toCreateMapClientTs(created);
    expect(createPayload['attachmentUrl'], 'https://example.com/a.png');
  });

  test('MedicineEntry omits attachmentUrl from create map when null', () {
    final t = DateTime(2026, 4, 1);
    final entry = MedicineEntry(
      id: 'm1',
      name: 'X',
      category: 'Other',
      dosage: '1',
      quantity: 1,
      unit: 'tab',
      expiryDate: t.add(const Duration(days: 30)),
      lowStockThreshold: 1,
      createdAt: t,
      updatedAt: t,
    );
    final createPayload = entry.toCreateMapClientTs(t);
    expect(createPayload.containsKey('attachmentUrl'), isFalse);
  });
}
