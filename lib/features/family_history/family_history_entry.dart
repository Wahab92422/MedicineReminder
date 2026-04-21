import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyHistoryEntry {
  const FamilyHistoryEntry({
    required this.id,
    required this.recordedAt,
    required this.category,
    required this.title,
    this.details = '',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final DateTime recordedAt;
  final String category;
  final String title;
  final String details;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  static DateTime _readTs(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  factory FamilyHistoryEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return FamilyHistoryEntry.fromMap(doc.id, doc.data() ?? const {});
  }

  factory FamilyHistoryEntry.fromMap(String id, Map<String, dynamic> map) {
    return FamilyHistoryEntry(
      id: id,
      recordedAt: _readTs(map['recordedAt']),
      category: map['category'] as String? ?? '',
      title: map['title'] as String? ?? '',
      details: map['details'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      createdAt: _readTs(map['createdAt']),
      updatedAt: _readTs(map['updatedAt']),
    );
  }

  Map<String, dynamic> toCreateMapClientTs(DateTime now) {
    return {
      'recordedAt': Timestamp.fromDate(recordedAt),
      'category': category,
      'title': title,
      'details': details,
      'notes': notes,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'recordedAt': Timestamp.fromDate(recordedAt),
      'category': category,
      'title': title,
      'details': details,
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
