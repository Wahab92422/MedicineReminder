import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'medicine_entry.dart';
import 'medicine_repository.dart';

final _firestoreProvider = Provider<FirebaseFirestore>(
  (_) => FirebaseFirestore.instance,
);

final _storageProvider = Provider<FirebaseStorage>(
  (_) => FirebaseStorage.instance,
);

final medicineRepositoryProvider = Provider<MedicineRepository>(
  (ref) => MedicineRepository(
    firestore: ref.watch(_firestoreProvider),
    storage: ref.watch(_storageProvider),
  ),
);

/// Category filter for the inventory list (drives [medicinesInventoryStreamProvider]).
class MedicineInventoryCategoryFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setFilter(String? category) => state = category;
}

final medicineInventoryCategoryFilterProvider =
    NotifierProvider<MedicineInventoryCategoryFilterNotifier, String?>(
      MedicineInventoryCategoryFilterNotifier.new,
    );

/// Name search for the inventory list.
class MedicineInventoryNameSearchNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setQuery(String? query) => state = query;
}

final medicineInventoryNameSearchProvider =
    NotifierProvider<MedicineInventoryNameSearchNotifier, String?>(
      MedicineInventoryNameSearchNotifier.new,
    );

/// Full inventory snapshot (ordered by name) for low-stock / expiry banners and alerts sync.
final allMedicinesStreamProvider = StreamProvider.autoDispose
    .family<List<MedicineEntry>, String>((ref, userId) {
      if (userId.isEmpty) {
        return Stream.value(const []);
      }
      return ref
          .watch(medicineRepositoryProvider)
          .watchAllMedicinesOrderedByName(userId: userId);
    });

/// Filtered inventory rows for the current user (live).
final medicinesInventoryStreamProvider =
    StreamProvider.autoDispose<List<MedicineEntry>>((ref) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        return Stream.value(const []);
      }
      final category = ref.watch(medicineInventoryCategoryFilterProvider);
      final nameSearch = ref.watch(medicineInventoryNameSearchProvider);
      return ref
          .watch(medicineRepositoryProvider)
          .watchMedicines(
            userId: uid,
            categoryFilter: category,
            nameSearch: nameSearch,
          );
    });

/// Low-stock medicines derived from [allMedicinesStreamProvider] (live).
final lowStockMedicinesProvider = Provider.autoDispose
    .family<AsyncValue<List<MedicineEntry>>, String>((ref, userId) {
      if (userId.isEmpty) {
        return const AsyncValue.data([]);
      }
      return ref
          .watch(allMedicinesStreamProvider(userId))
          .whenData((list) => list.where((m) => m.isLowStock).toList());
    });

/// Expiring / expired medicines derived from [allMedicinesStreamProvider] (live).
final expiringMedicinesProvider = Provider.autoDispose
    .family<AsyncValue<List<MedicineEntry>>, String>((ref, userId) {
      if (userId.isEmpty) {
        return const AsyncValue.data([]);
      }
      return ref
          .watch(allMedicinesStreamProvider(userId))
          .whenData(
            (list) =>
                list.where((m) => m.isExpiringSoon || m.isExpired).toList(),
          );
    });
