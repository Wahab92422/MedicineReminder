import 'package:cloud_firestore/cloud_firestore.dart';

class LabAttachment {
  const LabAttachment({required this.url, required this.type});

  final String url;
  final String type;

  Map<String, dynamic> toMap() => {'url': url, 'type': type};

  factory LabAttachment.fromMap(Map<String, dynamic> map) {
    return LabAttachment(
      url: map['url'] as String? ?? '',
      type: map['type'] as String? ?? 'application/octet-stream',
    );
  }

  static List<LabAttachment> listFromRaw(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) {
          if (e is Map<String, dynamic>) return LabAttachment.fromMap(e);
          if (e is Map)
            return LabAttachment.fromMap(Map<String, dynamic>.from(e));
          return const LabAttachment(url: '', type: '');
        })
        .where((e) => e.url.isNotEmpty)
        .toList();
  }
}

class LabReport {
  const LabReport({
    required this.id,
    required this.reportType,
    required this.title,
    required this.description,
    required this.testDate,
    required this.reportDate,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String reportType;
  final String title;
  final String description;
  final DateTime testDate;
  final DateTime reportDate;
  final List<LabAttachment> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get titleLower => title.toLowerCase();

  LabReport copyWith({
    String? id,
    String? reportType,
    String? title,
    String? description,
    DateTime? testDate,
    DateTime? reportDate,
    List<LabAttachment>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LabReport(
      id: id ?? this.id,
      reportType: reportType ?? this.reportType,
      title: title ?? this.title,
      description: description ?? this.description,
      testDate: testDate ?? this.testDate,
      reportDate: reportDate ?? this.reportDate,
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

  factory LabReport.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return LabReport.fromMap(doc.id, doc.data() ?? {});
  }

  factory LabReport.fromMap(String id, Map<String, dynamic> m) {
    return LabReport(
      id: id,
      reportType: m['reportType'] as String? ?? '',
      title: m['title'] as String? ?? '',
      description: m['description'] as String? ?? '',
      testDate: _readTs(m['testDate']),
      reportDate: _readTs(m['reportDate']),
      attachments: LabAttachment.listFromRaw(m['attachments']),
      createdAt: _readTs(m['createdAt']),
      updatedAt: _readTs(m['updatedAt']),
    );
  }

  Map<String, dynamic> toCreateMapClientTs(DateTime now) {
    return <String, dynamic>{
      'reportType': reportType,
      'title': title,
      'titleLower': title.toLowerCase(),
      'description': description,
      'testDate': Timestamp.fromDate(testDate),
      'reportDate': Timestamp.fromDate(reportDate),
      'attachments': attachments.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };
  }
}
