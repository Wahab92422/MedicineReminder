import 'package:cloud_firestore/cloud_firestore.dart';

import '../meals/meal_statuses.dart';

/// A single dose log for an inventory medicine (taken / missed / scheduled).
class MedicineLogEntry {
  const MedicineLogEntry({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.loggedAt,
    required this.status,
    required this.units,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String medicineId;
  final String medicineName;
  final DateTime loggedAt;

  /// Same labels as meals: [MealStatuses.taken], [MealStatuses.missed], [MealStatuses.scheduled].
  final String status;

  /// Units consumed when status is [MealStatuses.taken] (deducted from inventory).
  final int units;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isTaken => status == MealStatuses.taken;

  static DateTime _readTs(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  factory MedicineLogEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return MedicineLogEntry.fromMap(doc.id, doc.data() ?? const {});
  }

  factory MedicineLogEntry.fromMap(String id, Map<String, dynamic> map) {
    return MedicineLogEntry(
      id: id,
      medicineId: map['medicineId'] as String? ?? '',
      medicineName: map['medicineName'] as String? ?? '',
      loggedAt: _readTs(map['loggedAt']),
      status: MealStatuses.normalizeFromStorage(map['status'] as String?),
      units: (map['units'] as num?)?.toInt().clamp(1, 999999) ?? 1,
      notes: map['notes'] as String? ?? '',
      createdAt: _readTs(map['createdAt']),
      updatedAt: _readTs(map['updatedAt']),
    );
  }

  Map<String, dynamic> toCreateMapClientTs(DateTime now) {
    return {
      'medicineId': medicineId,
      'medicineName': medicineName,
      'loggedAt': Timestamp.fromDate(loggedAt),
      'status': status,
      'units': units,
      'notes': notes,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'medicineId': medicineId,
      'medicineName': medicineName,
      'loggedAt': Timestamp.fromDate(loggedAt),
      'status': status,
      'units': units,
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  MedicineLogEntry copyWith({
    String? id,
    String? medicineId,
    String? medicineName,
    DateTime? loggedAt,
    String? status,
    int? units,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicineLogEntry(
      id: id ?? this.id,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      loggedAt: loggedAt ?? this.loggedAt,
      status: status ?? this.status,
      units: units ?? this.units,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
