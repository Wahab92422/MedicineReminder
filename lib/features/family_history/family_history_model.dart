import 'package:cloud_firestore/cloud_firestore.dart';

enum FamilyRelationship {
  father,
  mother,
  sibling,
  child,
  maternalGrandparent,
  paternalGrandparent,
  other;

  String get label => switch (this) {
        father => 'Father',
        mother => 'Mother',
        sibling => 'Sibling',
        child => 'Child',
        maternalGrandparent => 'Maternal grandparent',
        paternalGrandparent => 'Paternal grandparent',
        other => 'Other',
      };

  static FamilyRelationship? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final v in FamilyRelationship.values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}

class FamilyHistoryRecord {
  FamilyHistoryRecord({
    required this.id,
    required this.userId,
    required this.relationship,
    required this.conditionName,
    this.ageAtOnset,
    this.deceased = false,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final FamilyRelationship relationship;
  final String conditionName;
  final int? ageAtOnset;
  final bool deceased;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'relationship': relationship.name,
      'conditionName': conditionName,
      'ageAtOnset': ageAtOnset,
      'deceased': deceased,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory FamilyHistoryRecord.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseReq(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    final created = parseReq(map['createdAt']);
    final updatedRaw = map['updatedAt'];
    final updated = updatedRaw is Timestamp
        ? updatedRaw.toDate()
        : (updatedRaw is String
            ? DateTime.tryParse(updatedRaw) ?? created
            : created);

    return FamilyHistoryRecord(
      id: id,
      userId: map['userId'] ?? '',
      relationship:
          FamilyRelationship.tryParse(map['relationship'] as String?) ??
              FamilyRelationship.other,
      conditionName: map['conditionName'] ?? '',
      ageAtOnset: (map['ageAtOnset'] as num?)?.toInt(),
      deceased: map['deceased'] as bool? ?? false,
      notes: (map['notes'] as String?)?.trim() ?? '',
      createdAt: created,
      updatedAt: updated,
    );
  }
}
