import 'package:cloud_firestore/cloud_firestore.dart';

enum MedicalConditionStatus {
  active,
  resolved,
  remission,
  unknown;

  String get label => switch (this) {
        active => 'Active',
        resolved => 'Resolved',
        remission => 'In remission',
        unknown => 'Unknown',
      };

  static MedicalConditionStatus? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final v in MedicalConditionStatus.values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}

class MedicalHistoryRecord {
  MedicalHistoryRecord({
    required this.id,
    required this.userId,
    required this.conditionName,
    required this.status,
    this.onsetDate,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String conditionName;
  final MedicalConditionStatus status;
  final DateTime? onsetDate;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'conditionName': conditionName,
      'status': status.name,
      'onsetDate': onsetDate != null ? Timestamp.fromDate(onsetDate!) : null,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory MedicalHistoryRecord.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseReq(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseOpt(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    final created = parseReq(map['createdAt']);
    final updatedRaw = map['updatedAt'];
    final updated = updatedRaw is Timestamp
        ? updatedRaw.toDate()
        : (updatedRaw is String
            ? DateTime.tryParse(updatedRaw) ?? created
            : created);

    return MedicalHistoryRecord(
      id: id,
      userId: map['userId'] ?? '',
      conditionName: map['conditionName'] ?? '',
      status: MedicalConditionStatus.tryParse(map['status'] as String?) ??
          MedicalConditionStatus.unknown,
      onsetDate: parseOpt(map['onsetDate']),
      notes: (map['notes'] as String?)?.trim() ?? '',
      createdAt: created,
      updatedAt: updated,
    );
  }
}
