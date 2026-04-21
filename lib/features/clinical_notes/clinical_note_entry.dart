import 'package:cloud_firestore/cloud_firestore.dart';

class ClinicalNoteEntry {
  const ClinicalNoteEntry({
    required this.id,
    required this.title,
    required this.body,
    required this.notedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime notedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  static DateTime _readTs(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  factory ClinicalNoteEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return ClinicalNoteEntry.fromMap(doc.id, doc.data() ?? const {});
  }

  factory ClinicalNoteEntry.fromMap(String id, Map<String, dynamic> map) {
    return ClinicalNoteEntry(
      id: id,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      notedAt: _readTs(map['notedAt']),
      createdAt: _readTs(map['createdAt']),
      updatedAt: _readTs(map['updatedAt']),
    );
  }

  Map<String, dynamic> toCreateMapClientTs(DateTime now) {
    return {
      'title': title,
      'body': body,
      'notedAt': Timestamp.fromDate(notedAt),
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'body': body,
      'notedAt': Timestamp.fromDate(notedAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ClinicalNoteEntry copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? notedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClinicalNoteEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      notedAt: notedAt ?? this.notedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
