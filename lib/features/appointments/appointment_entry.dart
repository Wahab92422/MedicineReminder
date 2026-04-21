import 'package:cloud_firestore/cloud_firestore.dart';

import 'appointment_statuses.dart';

class AppointmentEntry {
  const AppointmentEntry({
    required this.id,
    required this.title,
    required this.scheduledAt,
    required this.status,
    this.notes = '',
    this.location = '',
    this.doctor = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final DateTime scheduledAt;
  final String status;
  final String notes;
  final String location;
  /// Care provider name (optional).
  final String doctor;
  final DateTime createdAt;
  final DateTime updatedAt;

  static DateTime _readTs(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  factory AppointmentEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return AppointmentEntry.fromMap(doc.id, doc.data() ?? const {});
  }

  factory AppointmentEntry.fromMap(String id, Map<String, dynamic> map) {
    return AppointmentEntry(
      id: id,
      title: map['title'] as String? ?? '',
      scheduledAt: _readTs(map['scheduledAt']),
      status: AppointmentStatuses.normalizeFromStorage(map['status'] as String?),
      notes: map['notes'] as String? ?? '',
      location: map['location'] as String? ?? '',
      doctor: map['doctor'] as String? ?? '',
      createdAt: _readTs(map['createdAt']),
      updatedAt: _readTs(map['updatedAt']),
    );
  }

  Map<String, dynamic> toCreateMapClientTs(DateTime now) {
    return {
      'title': title,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'status': status,
      'notes': notes,
      'location': location,
      'doctor': doctor,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'status': status,
      'notes': notes,
      'location': location,
      'doctor': doctor,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AppointmentEntry copyWith({
    String? id,
    String? title,
    DateTime? scheduledAt,
    String? status,
    String? notes,
    String? location,
    String? doctor,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppointmentEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      location: location ?? this.location,
      doctor: doctor ?? this.doctor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
