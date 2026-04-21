import 'package:cloud_firestore/cloud_firestore.dart';

import 'meal_statuses.dart';

class MealEntry {
  const MealEntry({
    required this.id,
    required this.mealAt,
    required this.mealType,
    required this.status,
    this.notes = '',
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final DateTime mealAt;
  final String mealType;
  final String status;
  final String notes;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  static DateTime _readTs(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  factory MealEntry.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return MealEntry.fromMap(doc.id, doc.data() ?? const {});
  }

  factory MealEntry.fromMap(String id, Map<String, dynamic> map) {
    return MealEntry(
      id: id,
      mealAt: _readTs(map['mealAt']),
      mealType: map['mealType'] as String? ?? '',
      status: MealStatuses.normalizeFromStorage(map['status'] as String?),
      notes: map['notes'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      createdAt: _readTs(map['createdAt']),
      updatedAt: _readTs(map['updatedAt']),
    );
  }

  Map<String, dynamic> toCreateMapClientTs(DateTime now) {
    return {
      'mealAt': Timestamp.fromDate(mealAt),
      'mealType': mealType,
      'status': status,
      'notes': notes,
      if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'mealAt': Timestamp.fromDate(mealAt),
      'mealType': mealType,
      'status': status,
      'notes': notes,
      'imageUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
