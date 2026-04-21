import 'package:cloud_firestore/cloud_firestore.dart';

class MedicineEntry {
  const MedicineEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.dosage,
    required this.quantity,
    required this.unit,
    required this.expiryDate,
    required this.lowStockThreshold,
    this.notes = '',
    this.attachmentUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String category;
  final String dosage;
  final int quantity;
  final String unit;
  final DateTime expiryDate;
  final int lowStockThreshold;
  final String notes;
  final String? attachmentUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isLowStock => quantity <= lowStockThreshold;
  bool get isExpired => expiryDate.isBefore(DateTime.now());
  bool get isExpiringSoon {
    final expiryThreshold = DateTime.now().add(const Duration(days: 30));
    return expiryDate.isBefore(expiryThreshold) && !isExpired;
  }

  static DateTime _readTs(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  factory MedicineEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return MedicineEntry.fromMap(doc.id, doc.data() ?? {});
  }

  factory MedicineEntry.fromMap(String id, Map<String, dynamic> m) {
    return MedicineEntry(
      id: id,
      name: m['name'] as String? ?? '',
      category: m['category'] as String? ?? '',
      dosage: m['dosage'] as String? ?? '',
      quantity: m['quantity'] as int? ?? 0,
      unit: m['unit'] as String? ?? '',
      expiryDate: _readTs(m['expiryDate']),
      lowStockThreshold: m['lowStockThreshold'] as int? ?? 10,
      notes: m['notes'] as String? ?? '',
      attachmentUrl: m['attachmentUrl'] as String?,
      createdAt: _readTs(m['createdAt']),
      updatedAt: _readTs(m['updatedAt']),
    );
  }

  Map<String, dynamic> toCreateMapClientTs(DateTime now) {
    return <String, dynamic>{
      'name': name,
      'nameLower': name.toLowerCase(),
      'category': category,
      'dosage': dosage,
      'quantity': quantity,
      'unit': unit,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'lowStockThreshold': lowStockThreshold,
      'notes': notes,
      if (attachmentUrl != null && attachmentUrl!.isNotEmpty)
        'attachmentUrl': attachmentUrl,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return <String, dynamic>{
      'name': name,
      'nameLower': name.toLowerCase(),
      'category': category,
      'dosage': dosage,
      'quantity': quantity,
      'unit': unit,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'lowStockThreshold': lowStockThreshold,
      'notes': notes,
      'attachmentUrl': attachmentUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  MedicineEntry copyWith({
    String? id,
    String? name,
    String? category,
    String? dosage,
    int? quantity,
    String? unit,
    DateTime? expiryDate,
    int? lowStockThreshold,
    String? notes,
    String? attachmentUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicineEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      dosage: dosage ?? this.dosage,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expiryDate: expiryDate ?? this.expiryDate,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      notes: notes ?? this.notes,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
