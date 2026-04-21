import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/features/medicine_inventory/medicine_entry.dart';
import 'package:medicine_app/features/medicine_inventory/medicine_repository.dart';

MedicineEntry _m({
  required String id,
  required String name,
  required String category,
  int quantity = 5,
}) {
  final now = DateTime.now();
  return MedicineEntry(
    id: id,
    name: name,
    category: category,
    dosage: '1',
    quantity: quantity,
    unit: 'tab',
    expiryDate: now.add(const Duration(days: 365)),
    lowStockThreshold: 2,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('MedicineRepository.applyInventoryQueryPostFilter', () {
    test('returns all items when name search is empty', () {
      final items = [_m(id: '1', name: 'Aspirin', category: 'Pain')];
      final out = MedicineRepository.applyInventoryQueryPostFilter(
        items,
        categoryFilter: 'Pain',
        nameSearch: '   ',
      );
      expect(out, items);
    });

    test('filters by category when name prefix search is active', () {
      final items = [
        _m(id: '1', name: 'Amox', category: 'Antibiotic'),
        _m(id: '2', name: 'Amox', category: 'Pain'),
      ];
      final out = MedicineRepository.applyInventoryQueryPostFilter(
        items,
        categoryFilter: 'Pain',
        nameSearch: 'Am',
      );
      expect(out.length, 1);
      expect(out.single.id, '2');
    });
  });
}
