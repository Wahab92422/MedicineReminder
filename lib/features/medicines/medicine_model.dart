class Medicine {
  final String id;
  final String name;
  final String dose;
  final String time;
  final String userId;
  final bool repeatDaily;
  final DateTime? lastTaken;
  final bool isMissed;

  /// Current stock count (e.g. tablets remaining).
  final int quantityOnHand;

  /// When set, [isLowStock] is true if [quantityOnHand] is at or below this value.
  final int? lowStockThreshold;

  /// Label for inventory counts (e.g. tablets, capsules, ml).
  final String inventoryUnit;

  Medicine({
    required this.id,
    required this.name,
    required this.dose,
    required this.time,
    required this.userId,
    this.repeatDaily = true,
    this.lastTaken,
    this.isMissed = false,
    this.quantityOnHand = 0,
    this.lowStockThreshold,
    this.inventoryUnit = 'tablets',
  });

  bool get isOutOfStock => quantityOnHand <= 0;

  bool get isLowStock {
    final t = lowStockThreshold;
    if (t == null) return false;
    return quantityOnHand <= t;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dose': dose,
      'time': time,
      'userId': userId,
      'repeatDaily': repeatDaily,
      'lastTaken': lastTaken?.toIso8601String(),
      'isMissed': isMissed,
      'quantityOnHand': quantityOnHand,
      'lowStockThreshold': lowStockThreshold,
      'inventoryUnit': inventoryUnit,
    };
  }

  factory Medicine.fromMap(String id, Map<String, dynamic> map) {
    return Medicine(
      id: id,
      name: map['name'] ?? '',
      dose: map['dose'] ?? '',
      time: map['time'] ?? '',
      userId: map['userId'] ?? '',
      repeatDaily: map['repeatDaily'] ?? true,
      lastTaken: map['lastTaken'] != null
          ? DateTime.parse(map['lastTaken'])
          : null,
      isMissed: map['isMissed'] ?? false,
      quantityOnHand: (map['quantityOnHand'] as num?)?.toInt() ?? 0,
      lowStockThreshold: (map['lowStockThreshold'] as num?)?.toInt(),
      inventoryUnit: (map['inventoryUnit'] as String?)?.trim().isNotEmpty == true
          ? (map['inventoryUnit'] as String).trim()
          : 'tablets',
    );
  }
}
