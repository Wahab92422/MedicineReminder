import 'package:cloud_firestore/cloud_firestore.dart';

enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  String get label => switch (this) {
        breakfast => 'Breakfast',
        lunch => 'Lunch',
        dinner => 'Dinner',
        snack => 'Snack',
      };

  static MealType? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final v in MealType.values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}

enum MealStatus {
  taken,
  missed;

  String get label => switch (this) {
        taken => 'Taken',
        missed => 'Missed',
      };

  static MealStatus? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final v in MealStatus.values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}

class MealLog {
  MealLog({
    required this.id,
    required this.userId,
    required this.mealName,
    required this.loggedAt,
    required this.mealType,
    required this.status,
    this.description = '',
    this.imageUrl,
    this.imageStoragePath,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String mealName;
  final DateTime loggedAt;
  final MealType mealType;
  final MealStatus status;
  final String description;
  final String? imageUrl;
  final String? imageStoragePath;
  final DateTime createdAt;

  bool get hasImage =>
      imageUrl != null && imageUrl!.trim().isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'mealName': mealName,
      'loggedAt': Timestamp.fromDate(loggedAt),
      'mealType': mealType.name,
      'status': status.name,
      'description': description,
      'imageUrl': imageUrl,
      'imageStoragePath': imageStoragePath,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory MealLog.fromMap(String id, Map<String, dynamic> map) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    final logged = parseDate(map['loggedAt']);
    DateTime created;
    final ca = map['createdAt'];
    if (ca is Timestamp) {
      created = ca.toDate();
    } else if (ca is String) {
      created = DateTime.tryParse(ca) ?? logged;
    } else {
      created = logged;
    }

    return MealLog(
      id: id,
      userId: map['userId'] ?? '',
      mealName: map['mealName'] ?? '',
      loggedAt: logged,
      mealType: MealType.tryParse(map['mealType'] as String?) ?? MealType.breakfast,
      status: MealStatus.tryParse(map['status'] as String?) ?? MealStatus.taken,
      description: (map['description'] as String?)?.trim() ?? '',
      imageUrl: map['imageUrl'] as String?,
      imageStoragePath: map['imageStoragePath'] as String?,
      createdAt: created,
    );
  }

  MealLog copyWith({
    String? id,
    String? userId,
    String? mealName,
    DateTime? loggedAt,
    MealType? mealType,
    MealStatus? status,
    String? description,
    String? imageUrl,
    String? imageStoragePath,
    bool clearImage = false,
    DateTime? createdAt,
  }) {
    return MealLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mealName: mealName ?? this.mealName,
      loggedAt: loggedAt ?? this.loggedAt,
      mealType: mealType ?? this.mealType,
      status: status ?? this.status,
      description: description ?? this.description,
      imageUrl: clearImage ? null : (imageUrl ?? this.imageUrl),
      imageStoragePath:
          clearImage ? null : (imageStoragePath ?? this.imageStoragePath),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
