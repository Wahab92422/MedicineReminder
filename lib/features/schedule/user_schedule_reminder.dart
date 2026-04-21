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
    this.reminderOutcome,
  });

  final String id;
  final String userId;
  final String title;
  final String notes;
  final DateTime scheduledAt;
  final ScheduleReminderKind kind;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// `null` = still scheduled; `completed` or `missed` when resolved.
  final String? reminderOutcome;

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
      reminderOutcome: map['reminderOutcome'] as String?,
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
      if (reminderOutcome != null) 'reminderOutcome': reminderOutcome,
    };
  }

  UserScheduleReminder copyWith({
    String? title,
    String? notes,
    DateTime? scheduledAt,
    ScheduleReminderKind? kind,
    String? reminderOutcome,
    DateTime? updatedAt,
  }) {
    return UserScheduleReminder(
      id: id,
      userId: userId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      kind: kind ?? this.kind,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reminderOutcome: reminderOutcome ?? this.reminderOutcome,
    );
  }
}
