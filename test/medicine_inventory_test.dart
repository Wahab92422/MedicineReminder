import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/features/medicines/medicine_model.dart';

void main() {
  test('fromMap uses defaults when inventory fields missing', () {
    final m = Medicine.fromMap('x', {
      'name': 'Aspirin',
      'dose': '1',
      'time': '10:00',
      'userId': 'u1',
    });
    expect(m.quantityOnHand, 0);
    expect(m.lowStockThreshold, isNull);
    expect(m.inventoryUnit, 'tablets');
    expect(m.isOutOfStock, isTrue);
    expect(m.isLowStock, isFalse);
  });

  test('isLowStock and isOutOfStock', () {
    final low = Medicine(
      id: '1',
      name: 'X',
      dose: '1',
      time: '09:00',
      userId: 'u',
      quantityOnHand: 3,
      lowStockThreshold: 5,
      inventoryUnit: 'tablets',
    );
    expect(low.isLowStock, isTrue);
    expect(low.isOutOfStock, isFalse);

    final ok = Medicine(
      id: '1',
      name: 'X',
      dose: '1',
      time: '09:00',
      userId: 'u',
      quantityOnHand: 10,
      lowStockThreshold: 5,
      inventoryUnit: 'tablets',
    );
    expect(ok.isLowStock, isFalse);
  });
}
