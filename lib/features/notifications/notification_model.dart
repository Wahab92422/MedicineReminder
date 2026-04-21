import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { lowStock, expiringSoon, expired }

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.lowStock:
        return 'Low stock';
      case NotificationType.expiringSoon:
        return 'Expires soon';
      case NotificationType.expired:
        return 'Past expiry';
    }
  }

  String get iconName {
    switch (this) {
      case NotificationType.lowStock:
        return 'warning';
      case NotificationType.expiringSoon:
        return 'schedule';
      case NotificationType.expired:
        return 'error';
    }
  }
}

class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final String medicineId;
  final String medicineName;
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.medicineId,
    required this.medicineName,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw StateError('Notification ${doc.id} has no data');
    }
    return AppNotification.fromMap(doc.id, data);
  }

  /// Parses Firestore document fields (also used by tests).
  factory AppNotification.fromMap(String id, Map<String, dynamic> data) {
    final typeIndex = data['type'];
    if (typeIndex is! int ||
        typeIndex < 0 ||
        typeIndex >= NotificationType.values.length) {
      throw FormatException('Invalid notification type index: $typeIndex');
    }
    final createdRaw = data['createdAt'];
    final DateTime createdAt;
    if (createdRaw is Timestamp) {
      createdAt = createdRaw.toDate();
    } else if (createdRaw is DateTime) {
      createdAt = createdRaw;
    } else {
      throw FormatException('Invalid createdAt: $createdRaw');
    }
    return AppNotification(
      id: id,
      userId: data['userId'] as String,
      type: NotificationType.values[typeIndex],
      title: data['title'] as String,
      message: data['message'] as String,
      medicineId: data['medicineId'] as String,
      medicineName: data['medicineName'] as String,
      createdAt: createdAt,
      isRead: data['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.index,
      'title': title,
      'message': message,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    String? medicineId,
    String? medicineName,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
