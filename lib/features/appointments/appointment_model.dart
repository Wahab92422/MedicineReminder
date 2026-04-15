import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus {
  scheduled,
  attended,
  missed;

  String get label => switch (this) {
        scheduled => 'Scheduled',
        attended => 'Attended',
        missed => 'Missed',
      };

  static AppointmentStatus? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final v in AppointmentStatus.values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}

class AppointmentRecord {
  AppointmentRecord({
    required this.id,
    required this.userId,
    required this.title,
    required this.doctorName,
    required this.location,
    required this.scheduledAt,
    required this.status,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String doctorName;
  final String location;
  final DateTime scheduledAt;
  final AppointmentStatus status;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// True when [scheduledAt] is strictly after [asOf] (shown in Upcoming tab).
  bool isFutureSlot(DateTime asOf) => scheduledAt.isAfter(asOf);

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'doctorName': doctorName,
      'location': location,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'status': status.name,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory AppointmentRecord.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseReq(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    final scheduled = parseReq(map['scheduledAt']);
    final created = parseReq(map['createdAt']);
    final updatedRaw = map['updatedAt'];
    final updated = updatedRaw is Timestamp
        ? updatedRaw.toDate()
        : (updatedRaw is String
            ? DateTime.tryParse(updatedRaw) ?? created
            : created);

    return AppointmentRecord(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      doctorName: (map['doctorName'] as String?)?.trim() ?? '',
      location: (map['location'] as String?)?.trim() ?? '',
      scheduledAt: scheduled,
      status: AppointmentStatus.tryParse(map['status'] as String?) ??
          AppointmentStatus.scheduled,
      notes: (map['notes'] as String?)?.trim() ?? '',
      createdAt: created,
      updatedAt: updated,
    );
  }

  AppointmentRecord copyWith({
    String? id,
    String? userId,
    String? title,
    String? doctorName,
    String? location,
    DateTime? scheduledAt,
    AppointmentStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppointmentRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      doctorName: doctorName ?? this.doctorName,
      location: location ?? this.location,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
