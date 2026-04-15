/// BMI from metric inputs (height in centimeters, weight in kilograms).
double? computeBmiFromMetric({
  required double? heightCm,
  required double? weightKg,
}) {
  if (heightCm == null || weightKg == null) return null;
  if (heightCm <= 0 || weightKg <= 0) return null;
  final hM = heightCm / 100.0;
  if (hM <= 0) return null;
  final v = weightKg / (hM * hM);
  if (v.isNaN || v.isInfinite) return null;
  return double.parse(v.toStringAsFixed(1));
}
