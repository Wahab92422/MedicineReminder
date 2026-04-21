import 'package:cloud_firestore/cloud_firestore.dart';

/// One logged set of measurements at [recordedAt].
class VitalEntry {
  const VitalEntry({
    required this.id,
    required this.recordedAt,
    this.systolicMmHg,
    this.diastolicMmHg,
    this.heartRateBpm,
    this.temperatureCelsius,
    this.weightKg,
    this.heightCm,
    this.glucoseMgDl,
    this.spo2Percent,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final DateTime recordedAt;

  /// Blood pressure — systolic (upper number).
  final int? systolicMmHg;

  /// Blood pressure — diastolic (lower number).
  final int? diastolicMmHg;

  final int? heartRateBpm;
  final double? temperatureCelsius;
  final double? weightKg;
  final double? heightCm;
  final double? glucoseMgDl;
  final int? spo2Percent;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// True if any numeric measurement is present or notes are non-empty.
  bool get hasAnyData {
    if (notes.trim().isNotEmpty) return true;
    return systolicMmHg != null ||
        diastolicMmHg != null ||
        heartRateBpm != null ||
        temperatureCelsius != null ||
        weightKg != null ||
        heightCm != null ||
        glucoseMgDl != null ||
        spo2Percent != null;
  }

  static DateTime _readTs(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static int? _readInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString());
  }

  static double? _readDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory VitalEntry.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return VitalEntry.fromMap(doc.id, doc.data() ?? const {});
  }

  factory VitalEntry.fromMap(String id, Map<String, dynamic> m) {
    return VitalEntry(
      id: id,
      recordedAt: _readTs(m['recordedAt']),
      systolicMmHg: _readInt(m['systolicMmHg']),
      diastolicMmHg: _readInt(m['diastolicMmHg']),
      heartRateBpm: _readInt(m['heartRateBpm']),
      temperatureCelsius: _readDouble(m['temperatureCelsius']),
      weightKg: _readDouble(m['weightKg']),
      heightCm: _readDouble(m['heightCm']),
      glucoseMgDl: _readDouble(m['glucoseMgDl']),
      spo2Percent: _readInt(m['spo2Percent']),
      notes: m['notes'] as String? ?? '',
      createdAt: _readTs(m['createdAt']),
      updatedAt: _readTs(m['updatedAt']),
    );
  }

  Map<String, dynamic> toCreateMapClientTs(DateTime now) {
    return <String, dynamic>{
      'recordedAt': Timestamp.fromDate(recordedAt),
      ..._optionalFields(),
      'notes': notes,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };
  }

  /// Merge update: null measurements clear the corresponding field in Firestore.
  Map<String, dynamic> toUpdateMap() {
    return <String, dynamic>{
      'recordedAt': Timestamp.fromDate(recordedAt),
      'systolicMmHg': systolicMmHg,
      'diastolicMmHg': diastolicMmHg,
      'heartRateBpm': heartRateBpm,
      'temperatureCelsius': temperatureCelsius,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'glucoseMgDl': glucoseMgDl,
      'spo2Percent': spo2Percent,
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> _optionalFields() {
    return <String, dynamic>{
      if (systolicMmHg != null) 'systolicMmHg': systolicMmHg,
      if (diastolicMmHg != null) 'diastolicMmHg': diastolicMmHg,
      if (heartRateBpm != null) 'heartRateBpm': heartRateBpm,
      if (temperatureCelsius != null) 'temperatureCelsius': temperatureCelsius,
      if (weightKg != null) 'weightKg': weightKg,
      if (heightCm != null) 'heightCm': heightCm,
      if (glucoseMgDl != null) 'glucoseMgDl': glucoseMgDl,
      if (spo2Percent != null) 'spo2Percent': spo2Percent,
    };
  }
}
