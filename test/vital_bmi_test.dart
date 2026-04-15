import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/features/vitals/vital_bmi.dart';

void main() {
  group('computeBmiFromMetric', () {
    test('computes BMI for typical adult', () {
      final bmi = computeBmiFromMetric(heightCm: 180, weightKg: 80);
      expect(bmi, closeTo(24.7, 0.05));
    });

    test('returns null when height missing', () {
      expect(computeBmiFromMetric(heightCm: null, weightKg: 70), isNull);
    });

    test('returns null when weight missing', () {
      expect(computeBmiFromMetric(heightCm: 170, weightKg: null), isNull);
    });

    test('returns null for non-positive height', () {
      expect(computeBmiFromMetric(heightCm: 0, weightKg: 70), isNull);
    });

    test('returns null for non-positive weight', () {
      expect(computeBmiFromMetric(heightCm: 170, weightKg: 0), isNull);
    });
  });
}
