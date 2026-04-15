import 'package:cloud_firestore/cloud_firestore.dart';

/// Common EHR-style clinical documentation categories.
enum ClinicalNoteCategory {
  progress,
  assessmentPlan,
  phoneMessage,
  consultationSummary,
  general;

  String get label => switch (this) {
        progress => 'Progress note',
        assessmentPlan => 'Assessment & plan',
        phoneMessage => 'Phone / message',
        consultationSummary => 'Consult summary',
        general => 'General',
      };

  static ClinicalNoteCategory? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final v in ClinicalNoteCategory.values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}

class ClinicalNote {
  ClinicalNote({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.category,
    required this.encounterAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final ClinicalNoteCategory category;
  final DateTime encounterAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'category': category.name,
      'encounterAt': Timestamp.fromDate(encounterAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ClinicalNote.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseRequired(dynamic v, DateTime fallback) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? fallback;
      return fallback;
    }

    final now = DateTime.now();
    final encounter = parseRequired(map['encounterAt'], now);
    final created = parseRequired(map['createdAt'], encounter);
    final updated = parseRequired(map['updatedAt'], created);

    return ClinicalNote(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      category:
          ClinicalNoteCategory.tryParse(map['category'] as String?) ??
              ClinicalNoteCategory.general,
      encounterAt: encounter,
      createdAt: created,
      updatedAt: updated,
    );
  }

  ClinicalNote copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    ClinicalNoteCategory? category,
    DateTime? encounterAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClinicalNote(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      encounterAt: encounterAt ?? this.encounterAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
