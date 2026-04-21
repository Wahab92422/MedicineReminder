import 'package:cloud_firestore/cloud_firestore.dart';

import 'medicine_entry.dart';

class MedicinePage {
  const MedicinePage({required this.items, required this.nextPageCursor});

  final List<MedicineEntry> items;
  final DocumentSnapshot<Map<String, dynamic>>? nextPageCursor;
}
