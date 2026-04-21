/// Medicine categories for inventory classification.
class MedicineCategories {
  MedicineCategories._();

  static const String antibiotics = 'Antibiotics';
  static const String painRelief = 'Pain Relief';
  static const String antiInflammatory = 'Anti-inflammatory';
  static const String antihistamine = 'Antihistamine';
  static const String cardiovascular = 'Cardiovascular';
  static const String diabetes = 'Diabetes';
  static const String respiratory = 'Respiratory';
  static const String gastrointestinal = 'Gastrointestinal';
  static const String vitamins = 'Vitamins';
  static const String supplements = 'Supplements';
  static const String other = 'Other';

  static const List<String> all = [
    antibiotics,
    painRelief,
    antiInflammatory,
    antihistamine,
    cardiovascular,
    diabetes,
    respiratory,
    gastrointestinal,
    vitamins,
    supplements,
    other,
  ];
}
