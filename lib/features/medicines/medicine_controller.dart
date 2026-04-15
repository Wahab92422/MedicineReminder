import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../history/history_controller.dart';
import '../history/history_model.dart';
import '../history/history_repository.dart';
import 'medicine_model.dart';
import 'medicine_reminder_time.dart';
import 'medicine_repository.dart';
import '../../services/notification_service.dart';

final medicineRepositoryProvider = Provider((ref) {
  return MedicineRepository();
});

final medicineStreamProvider = StreamProvider<List<Medicine>>((ref) {
  final repo = ref.watch(medicineRepositoryProvider);
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return const Stream.empty();
  }

  return repo.getMedicines(user.uid);
});

final medicineControllerProvider = Provider((ref) {
  return MedicineController(
    ref.watch(medicineRepositoryProvider),
    ref.watch(historyRepositoryProvider),
  );
});

/// Medicines that should receive a daily local notification.
@visibleForTesting
List<Medicine> medicinesForDailyReminderScheduling(List<Medicine> medicines) {
  return medicines.where((m) => m.repeatDaily).toList();
}

class MedicineController {
  final MedicineRepository _repo;
  final HistoryRepository _historyRepo;

  MedicineController(this._repo, this._historyRepo);

  /// Logs a taken dose and clears the missed flag on the medicine document.
  Future<void> markMedicineTaken(Medicine med) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final scheduled = MedicineReminderTime.formatClockHm(med.time);

    await FirebaseFirestore.instance.collection('medicines').doc(med.id).update({
      'isMissed': false,
      'lastTaken': now.toIso8601String(),
    });

    await _historyRepo.addRecord(
      History(
        id: '',
        userId: user.uid,
        medicineId: med.id,
        medicineName: med.name,
        dose: med.dose,
        scheduledTime: scheduled,
        takenTime: now,
        status: 'taken',
        createdAt: now,
      ),
    );
  }

  Future<String?> addMedicine({
    required String name,
    required String dose,
    required String time,
    int quantityOnHand = 0,
    int? lowStockThreshold,
    String inventoryUnit = 'tablets',
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return null;

    final medicine = Medicine(
      id: '',
      name: name,
      dose: dose,
      time: time,
      userId: user.uid,
      quantityOnHand: quantityOnHand,
      lowStockThreshold: lowStockThreshold,
      inventoryUnit: inventoryUnit,
    );

    return _repo.addMedicine(medicine);
  }

  Future<void> deleteMedicine(String id) async {
    await NotificationService.cancel(NotificationService.notificationIdForMedicine(id));
    await _repo.deleteMedicine(id);
  }

  Future<void> updateMedicine({
    required String id,
    required String name,
    required String dose,
    required String time,
    required int quantityOnHand,
    int? lowStockThreshold,
    required String inventoryUnit,
  }) async {
    await _repo.updateMedicine(
      id: id,
      name: name,
      dose: dose,
      time: time,
      quantityOnHand: quantityOnHand,
      lowStockThreshold: lowStockThreshold,
      inventoryUnit: inventoryUnit,
    );
    await scheduleMedicineReminder(medicineId: id, name: name, time: time);
  }

  Future<void> adjustMedicineQuantity({
    required String id,
    required int delta,
  }) async {
    await _repo.adjustQuantity(id: id, delta: delta);
  }

  /// Re-applies daily reminder schedules from Firestore (app start, resume, stream updates).
  Future<void> syncReminderSchedulesForMedicines(List<Medicine> medicines) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    for (final med in medicines) {
      if (!med.repeatDaily) {
        await NotificationService.cancel(
          NotificationService.notificationIdForMedicine(med.id),
        );
      }
    }

    for (final med in medicinesForDailyReminderScheduling(medicines)) {
      await scheduleMedicineReminder(
        medicineId: med.id,
        name: med.name,
        time: med.time,
      );
    }
  }

  /// Daily reminder at the clock from [time] (ISO local or legacy `HH:mm`).
  Future<void> scheduleMedicineReminder({
    required String medicineId,
    required String name,
    required String time,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final local = MedicineReminderTime.decodeToLocal(time);
    if (local == null) return;

    final hour = local.hour;
    final minute = local.minute;

    final nid = NotificationService.notificationIdForMedicine(medicineId);
    await NotificationService.cancel(nid);
    await NotificationService.scheduleDailyReminder(
      notificationId: nid,
      title: 'Medicine reminder',
      body: 'Time to take $name',
      hour: hour,
      minute: minute,
      firstScheduleLocal: local,
    );
  }

  Future<void> checkMissedDoses(List<Medicine> medicines) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();

    for (final med in medicines) {
      final anchor = MedicineReminderTime.decodeToLocal(med.time);
      if (anchor == null) continue;

      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        anchor.hour,
        anchor.minute,
      );

      if (now.isAfter(scheduledTime.add(const Duration(hours: 1)))) {
        if (med.isMissed) continue;

        await FirebaseFirestore.instance
            .collection('medicines')
            .doc(med.id)
            .update({'isMissed': true});

        await _historyRepo.addRecord(
          History(
            id: '',
            userId: user.uid,
            medicineId: med.id,
            medicineName: med.name,
            dose: med.dose,
            scheduledTime: MedicineReminderTime.formatClockHm(med.time),
            takenTime: null,
            status: 'missed',
            createdAt: now,
          ),
        );
      }
    }
  }
}
