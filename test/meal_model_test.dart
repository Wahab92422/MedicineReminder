import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/features/meals/meal_model.dart';

void main() {
  group('MealLog', () {
    test('toMap / fromMap roundtrip', () {
      final logged = DateTime(2026, 6, 1, 14, 30);
      final created = DateTime(2026, 6, 2, 9, 0);
      final original = MealLog(
        id: 'doc1',
        userId: 'user1',
        mealName: 'Oatmeal',
        loggedAt: logged,
        mealType: MealType.breakfast,
        status: MealStatus.missed,
        description: 'Rushed morning',
        imageUrl: 'https://example.com/a.jpg',
        imageStoragePath: 'meal_images/user1/1.jpg',
        createdAt: created,
      );

      final map = original.toMap();
      final restored = MealLog.fromMap('doc1', map);

      expect(restored.id, 'doc1');
      expect(restored.userId, original.userId);
      expect(restored.mealName, original.mealName);
      expect(restored.loggedAt, original.loggedAt);
      expect(restored.mealType, original.mealType);
      expect(restored.status, original.status);
      expect(restored.description, original.description);
      expect(restored.imageUrl, original.imageUrl);
      expect(restored.imageStoragePath, original.imageStoragePath);
      expect(restored.createdAt, original.createdAt);
    });

    test('fromMap uses defaults for unknown enums', () {
      final map = {
        'userId': 'u',
        'mealName': 'X',
        'loggedAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'mealType': 'unknown_type',
        'status': 'unknown_status',
        'description': '',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 2)),
      };
      final m = MealLog.fromMap('id', map);
      expect(m.mealType, MealType.breakfast);
      expect(m.status, MealStatus.taken);
    });
  });

  group('MealType.tryParse', () {
    test('parses known names', () {
      expect(MealType.tryParse('lunch'), MealType.lunch);
      expect(MealType.tryParse('snack'), MealType.snack);
    });
  });
}
