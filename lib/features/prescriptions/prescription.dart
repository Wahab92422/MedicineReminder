import 'package:cloud_firestore/cloud_firestore.dart';

import '../labs/lab_report.dart' show LabAttachment;

/// User-entered prescription record (not e-prescribing).
class Prescription {
  const Prescription({
    required this.id,
    required this.prescriptionType,
    required this.title,
    required this.description,
    required this.prescribedDate,
    required this.validUntil,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String prescriptionType;
  final String title;
  final String description;
  final DateTime prescribedDate;
  final DateTime validUntil;
  final List<LabAttachment> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get titleLower => title.toLowerCase();

  Prescription copyWith({
    String? id,
    String? prescriptionType,
    String? title,
    String? description,
    DateTime? prescribedDate,
    DateTime? validUntil,
    List<LabAttachment>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Prescription(
      id: id ?? this.id,
      prescriptionType: prescriptionType ?? this.prescriptionType,
      title: title ?? this.title,
      description: description ?? this.description,
      prescribedDate: prescribedDate ?? this.prescribedDate,
      validUntil: validUntil ?? this.validUntil,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime _readTs(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  factory Prescription.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return Prescription.fromMap(doc.id, doc.data() ?? {});
  }

  factory Prescription.fromMap(String id, Map<String, dynamic> m) {
    return Prescription(
      id: id,
      prescriptionType: m['prescriptionType'] as String? ?? '',
      title: m['title'] as String? ?? '',
      description: m['description'] as String? ?? '',
      prescribedDate: _readTs(m['prescribedDate']),
      validUntil: _readTs(m['validUntil']),
      attachments: LabAttachment.listFromRaw(m['attachments']),
      createdAt: _readTs(m['createdAt']),
      updatedAt: _readTs(m['updatedAt']),
    );
  }

  Map<String, dynamic> toCreateMapClientTs(DateTime now) {
    return <String, dynamic>{
      'prescriptionType': prescriptionType,
      'title': title,
      'titleLower': title.toLowerCase(),
      'description': description,
      'prescribedDate': Timestamp.fromDate(prescribedDate),
      'validUntil': Timestamp.fromDate(validUntil),
      'attachments': attachments.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };
  }
}
