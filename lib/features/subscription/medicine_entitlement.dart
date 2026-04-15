/// Free-tier medicine limits vs premium (Firestore `isPremium`).
abstract final class MedicineEntitlement {
  static const int freeMaxMedicines = 3;

  static bool canAddMore({
    required bool isPremium,
    required int medicineCount,
  }) {
    if (isPremium) return true;
    return medicineCount < freeMaxMedicines;
  }

  static bool isAtFreeLimit({
    required bool isPremium,
    required int medicineCount,
  }) {
    return !isPremium && medicineCount >= freeMaxMedicines;
  }
}
