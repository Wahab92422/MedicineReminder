import 'package:cloud_firestore/cloud_firestore.dart';

class History {
  History({
    required this.id,
    required this.userId,
    required this.medicineId,
    required this.medicineName,
    required this.dose,
    required this.scheduledTime,
    this.takenTime,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String medicineId;
  final String medicineName;
  final String dose;
  final String scheduledTime;
  final DateTime? takenTime;
  final String status;
  final DateTime createdAt;

  bool get isTaken => status == 'taken';
  bool get isMissed => status == 'missed';

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'dose': dose,
      'scheduledTime': scheduledTime,
      'takenTime': takenTime != null ? Timestamp.fromDate(takenTime!) : null,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory History.fromMap(String id, Map<String, dynamic> map) {
    DateTime? taken;
    final tt = map['takenTime'];
    if (tt is Timestamp) {
      taken = tt.toDate();
    } else if (tt is String) {
      taken = DateTime.tryParse(tt);
    }

    DateTime created;
    final ca = map['createdAt'];
    if (ca is Timestamp) {
      created = ca.toDate();
    } else if (ca is String) {
      created = DateTime.tryParse(ca) ?? DateTime.now();
    } else {
      created = DateTime.now();
    }

    final st = map['status'] as String? ?? 'taken';
    final normalized = st == 'missed' ? 'missed' : 'taken';

    return History(
      id: id,
      userId: map['userId'] ?? '',
      medicineId: map['medicineId'] ?? '',
      medicineName: map['medicineName'] ?? '',
      dose: map['dose'] ?? '',
      scheduledTime: map['scheduledTime'] ?? '',
      takenTime: taken,
      status: normalized,
      createdAt: created,
    );
  }

  History copyWith({
    String? id,
    String? userId,
    String? medicineId,
    String? medicineName,
    String? dose,
    String? scheduledTime,
    DateTime? takenTime,
    bool clearTakenTime = false,
    String? status,
    DateTime? createdAt,
  }) {
    return History(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      dose: dose ?? this.dose,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      takenTime: clearTakenTime ? null : (takenTime ?? this.takenTime),
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
