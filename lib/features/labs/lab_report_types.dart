/// Allowed values for lab report type (Firestore + UI).
abstract final class LabReportTypes {
  static const List<String> all = [
    bloodTest,
    urine,
    imaging,
    pathology,
    other,
  ];

  static const String bloodTest = 'Blood test';
  static const String urine = 'Urine';
  static const String imaging = 'Imaging';
  static const String pathology = 'Pathology';
  static const String other = 'Other';
}
