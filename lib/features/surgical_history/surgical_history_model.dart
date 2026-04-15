import 'package:cloud_firestore/cloud_firestore.dart';

class SurgicalHistoryRecord {
  SurgicalHistoryRecord({
    required this.id,
    required this.userId,
    required this.procedureName,
    required this.procedureDate,
    this.surgeonName = '',
    this.facilityName = '',
    this.bodySite = '',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String procedureName;
  final DateTime procedureDate;
  final String surgeonName;
  final String facilityName;
  final String bodySite;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'procedureName': procedureName,
      'procedureDate': Timestamp.fromDate(procedureDate),
      'surgeonName': surgeonName,
      'facilityName': facilityName,
      'bodySite': bodySite,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory SurgicalHistoryRecord.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    final proc = parseDate(map['procedureDate']);
    final created = parseDate(map['createdAt']);
    final updatedRaw = map['updatedAt'];
    final updated = updatedRaw is Timestamp
        ? updatedRaw.toDate()
        : (updatedRaw is String
            ? DateTime.tryParse(updatedRaw) ?? created
            : created);

    return SurgicalHistoryRecord(
      id: id,
      userId: map['userId'] ?? '',
      procedureName: map['procedureName'] ?? '',
      procedureDate: proc,
      surgeonName: (map['surgeonName'] as String?)?.trim() ?? '',
      facilityName: (map['facilityName'] as String?)?.trim() ?? '',
      bodySite: (map['bodySite'] as String?)?.trim() ?? '',
      notes: (map['notes'] as String?)?.trim() ?? '',
      createdAt: created,
      updatedAt: updated,
    );
  }
}
