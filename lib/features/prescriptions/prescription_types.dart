/// Allowed values for prescription type (Firestore + UI).
abstract final class PrescriptionTypes {
  static const List<String> all = [oral, topical, injectable, other];

  static const String oral = 'Oral medication';
  static const String topical = 'Topical';
  static const String injectable = 'Injectable';
  static const String other = 'Other';
}
