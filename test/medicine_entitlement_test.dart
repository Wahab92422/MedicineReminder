import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/features/subscription/medicine_entitlement.dart';

void main() {
  group('MedicineEntitlement.canAddMore', () {
    test('premium users are not limited', () {
      expect(
        MedicineEntitlement.canAddMore(isPremium: true, medicineCount: 100),
        isTrue,
      );
    });

    test('free users can add below cap', () {
      expect(
        MedicineEntitlement.canAddMore(isPremium: false, medicineCount: 0),
        isTrue,
      );
      expect(
        MedicineEntitlement.canAddMore(isPremium: false, medicineCount: 2),
        isTrue,
      );
    });

    test('free users cannot add at or above cap', () {
      expect(
        MedicineEntitlement.canAddMore(isPremium: false, medicineCount: 3),
        isFalse,
      );
      expect(
        MedicineEntitlement.canAddMore(isPremium: false, medicineCount: 10),
        isFalse,
      );
    });
  });

  group('MedicineEntitlement.isAtFreeLimit', () {
    test('not at limit when premium', () {
      expect(
        MedicineEntitlement.isAtFreeLimit(isPremium: true, medicineCount: 50),
        isFalse,
      );
    });

    test('at limit when free and count reaches max', () {
      expect(
        MedicineEntitlement.isAtFreeLimit(isPremium: false, medicineCount: 3),
        isTrue,
      );
    });

    test('not at limit when free and below max', () {
      expect(
        MedicineEntitlement.isAtFreeLimit(isPremium: false, medicineCount: 2),
        isFalse,
      );
    });
  });
}
