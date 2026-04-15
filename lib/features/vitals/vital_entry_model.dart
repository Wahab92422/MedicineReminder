import 'package:cloud_firestore/cloud_firestore.dart';

class VitalEntry {
  VitalEntry({
    required this.id,
    required this.userId,
    required this.recordedAt,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.heartRate,
    this.temperatureC,
    this.heightCm,
    this.weightKg,
    this.bmi,
    this.respiratoryRate,
    this.oxygenSaturation,
    this.bloodGlucose,
    this.notes = '',
  });

  final String id;
  final String userId;
  final DateTime recordedAt;

  final int? bloodPressureSystolic;
  final int? bloodPressureDiastolic;
  final int? heartRate;
  final double? temperatureC;
  final double? heightCm;
  final double? weightKg;
  final double? bmi;
  final int? respiratoryRate;
  final int? oxygenSaturation;
  final double? bloodGlucose;
  final String notes;

  String? get bloodPressureLabel {
    final s = bloodPressureSystolic;
    final d = bloodPressureDiastolic;
    if (s != null && d != null) return '$s/$d mmHg';
    if (s != null) return '$s/— mmHg';
    if (d != null) return '—/$d mmHg';
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'recordedAt': Timestamp.fromDate(recordedAt),
      'bloodPressureSystolic': bloodPressureSystolic,
      'bloodPressureDiastolic': bloodPressureDiastolic,
      'heartRate': heartRate,
      'temperatureC': temperatureC,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'bmi': bmi,
      'respiratoryRate': respiratoryRate,
      'oxygenSaturation': oxygenSaturation,
      'bloodGlucose': bloodGlucose,
      'notes': notes,
    };
  }

  factory VitalEntry.fromMap(String id, Map<String, dynamic> map) {
    DateTime recordedAt;
    final raw = map['recordedAt'];
    if (raw is Timestamp) {
      recordedAt = raw.toDate();
    } else if (raw is String) {
      recordedAt = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      recordedAt = DateTime.now();
    }

    return VitalEntry(
      id: id,
      userId: map['userId'] ?? '',
      recordedAt: recordedAt,
      bloodPressureSystolic: (map['bloodPressureSystolic'] as num?)?.toInt(),
      bloodPressureDiastolic: (map['bloodPressureDiastolic'] as num?)?.toInt(),
      heartRate: (map['heartRate'] as num?)?.toInt(),
      temperatureC: (map['temperatureC'] as num?)?.toDouble(),
      heightCm: (map['heightCm'] as num?)?.toDouble(),
      weightKg: (map['weightKg'] as num?)?.toDouble(),
      bmi: (map['bmi'] as num?)?.toDouble(),
      respiratoryRate: (map['respiratoryRate'] as num?)?.toInt(),
      oxygenSaturation: (map['oxygenSaturation'] as num?)?.toInt(),
      bloodGlucose: (map['bloodGlucose'] as num?)?.toDouble(),
      notes: (map['notes'] as String?)?.trim() ?? '',
    );
  }
}
