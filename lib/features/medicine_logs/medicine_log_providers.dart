import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../medicine_inventory/medicine_entry.dart';
import '../medicine_inventory/medicine_providers.dart';
import 'medicine_log_entry.dart';
import 'medicine_log_repository.dart';

final _firestoreProvider = Provider<FirebaseFirestore>(
  (_) => FirebaseFirestore.instance,
);

final medicineLogRepositoryProvider = Provider<MedicineLogRepository>(
  (ref) => MedicineLogRepository(firestore: ref.watch(_firestoreProvider)),
);

/// Full inventory for medicine selection on the log form (live).
final inventoryMedicinesForPickerProvider =
    StreamProvider.family<List<MedicineEntryForPicker>, String>((ref, userId) {
      if (userId.isEmpty) {
        return Stream.value(const []);
      }
      return ref
          .watch(medicineRepositoryProvider)
          .watchAllMedicinesOrderedByName(userId: userId)
          .map(
            (list) => list
                .map(
                  (MedicineEntry m) => MedicineEntryForPicker(
                    id: m.id,
                    name: m.name,
                    quantity: m.quantity,
                    unit: m.unit,
                  ),
                )
                .toList(),
          );
    });

/// Dose logs (newest first, live).
final medicineLogsStreamProvider =
    StreamProvider.autoDispose.family<List<MedicineLogEntry>, String>((ref, userId) {
      if (userId.isEmpty) {
        return Stream.value(const []);
      }
      return ref.watch(medicineLogRepositoryProvider).watchLogs(userId: userId);
    });

/// Lightweight row for dropdowns (avoids pulling full [MedicineEntry] into provider API).
@immutable
class MedicineEntryForPicker {
  const MedicineEntryForPicker({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
  });

  final String id;
  final String name;
  final int quantity;
  final String unit;
}
