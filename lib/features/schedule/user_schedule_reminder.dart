import 'package:cloud_firestore/cloud_firestore.dart';

import 'schedule_reminder_kind.dart';

class UserScheduleReminder {
  const UserScheduleReminder({
    required this.id,
    required this.userId,
    required this.title,
    required this.notes,
    required this.scheduledAt,
    required this.kind,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String notes;
  final DateTime scheduledAt;
  final ScheduleReminderKind kind;
  final DateTime createdAt;
  final DateTime updatedAt;

  static DateTime _readTs(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  factory UserScheduleReminder.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return UserScheduleReminder.fromMap(doc.id, doc.data() ?? const {});
  }

  factory UserScheduleReminder.fromMap(String id, Map<String, dynamic> map) {
    final kind = parseScheduleReminderKind(map['kind'] as String?) ??
        ScheduleReminderKind.general;
    return UserScheduleReminder(
      id: id,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      scheduledAt: _readTs(map['scheduledAt']),
      kind: kind,
      createdAt: _readTs(map['createdAt']),
      updatedAt: _readTs(map['updatedAt']),
    );
  }

  Map<String, dynamic> toCreateMapClientTs(DateTime now) {
    return {
      'userId': userId,
      'title': title,
      'notes': notes,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'kind': kind.wireValue,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };
  }
}
