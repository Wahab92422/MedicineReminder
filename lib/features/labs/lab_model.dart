import 'package:cloud_firestore/cloud_firestore.dart';

/// Visual category for list badges (not a file-type restriction).
enum LabFileBadge {
  pdf,
  image,
  doc,
  spreadsheet,
  archive,
  other,
}

String labFileBadgeLabel(LabFileBadge badge) {
  return switch (badge) {
    LabFileBadge.pdf => 'PDF',
    LabFileBadge.image => 'IMAGE',
    LabFileBadge.doc => 'DOC',
    LabFileBadge.spreadsheet => 'SHEET',
    LabFileBadge.archive => 'ZIP',
    LabFileBadge.other => 'OTHER',
  };
}

LabFileBadge labFileBadgeFromExtension(String fileExtension) {
  final e = fileExtension.toLowerCase().replaceAll('.', '').trim();
  if (e.isEmpty) return LabFileBadge.other;
  if (e == 'pdf') return LabFileBadge.pdf;
  if (e == 'jpg' ||
      e == 'jpeg' ||
      e == 'png' ||
      e == 'gif' ||
      e == 'webp' ||
      e == 'bmp' ||
      e == 'heic' ||
      e == 'tif' ||
      e == 'tiff') {
    return LabFileBadge.image;
  }
  if (e == 'doc' || e == 'docx' || e == 'rtf' || e == 'odt') {
    return LabFileBadge.doc;
  }
  if (e == 'xls' || e == 'xlsx' || e == 'csv' || e == 'ods') {
    return LabFileBadge.spreadsheet;
  }
  if (e == 'zip' || e == 'rar' || e == '7z' || e == 'gz' || e == 'tar') {
    return LabFileBadge.archive;
  }
  return LabFileBadge.other;
}

class LabReport {
  LabReport({
    required this.id,
    required this.userId,
    required this.reportName,
    required this.testName,
    required this.reportType,
    required this.fileUrl,
    required this.fileName,
    required this.fileExtension,
    required this.mimeType,
    required this.fileSize,
    this.testDate,
    this.resultDate,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String reportName;
  final String testName;
  final String reportType;
  final String fileUrl;
  final String fileName;
  final String fileExtension;
  final String mimeType;
  final int fileSize;
  final DateTime? testDate;
  final DateTime? resultDate;
  final DateTime createdAt;

  LabFileBadge get fileBadge => labFileBadgeFromExtension(fileExtension);

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'reportName': reportName,
      'testName': testName,
      'reportType': reportType,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileExtension': fileExtension,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'testDate': testDate != null ? Timestamp.fromDate(testDate!) : null,
      'resultDate': resultDate != null ? Timestamp.fromDate(resultDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory LabReport.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
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

    return LabReport(
      id: id,
      userId: map['userId'] ?? '',
      reportName: map['reportName'] ?? '',
      testName: map['testName'] ?? '',
      reportType: map['reportType'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileName: map['fileName'] ?? '',
      fileExtension: (map['fileExtension'] as String? ?? '').replaceAll('.', '').toLowerCase(),
      mimeType: map['mimeType'] ?? 'application/octet-stream',
      fileSize: (map['fileSize'] as num?)?.toInt() ?? 0,
      testDate: parseDate(map['testDate']),
      resultDate: parseDate(map['resultDate']),
      createdAt: created,
    );
  }

  LabReport copyWith({
    String? id,
    String? userId,
    String? reportName,
    String? testName,
    String? reportType,
    String? fileUrl,
    String? fileName,
    String? fileExtension,
    String? mimeType,
    int? fileSize,
    DateTime? testDate,
    DateTime? resultDate,
    bool clearTestDate = false,
    bool clearResultDate = false,
    DateTime? createdAt,
  }) {
    return LabReport(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      reportName: reportName ?? this.reportName,
      testName: testName ?? this.testName,
      reportType: reportType ?? this.reportType,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileExtension: fileExtension ?? this.fileExtension,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      testDate: clearTestDate ? null : (testDate ?? this.testDate),
      resultDate: clearResultDate ? null : (resultDate ?? this.resultDate),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
