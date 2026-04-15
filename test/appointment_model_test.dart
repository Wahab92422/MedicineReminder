import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/features/appointments/appointment_model.dart';

void main() {
  group('isFutureSlot', () {
    final asOf = DateTime(2026, 6, 15, 12, 0);

    test('true when scheduledAt is after asOf', () {
      final r = AppointmentRecord(
        id: '1',
        userId: 'u',
        title: 'Visit',
        doctorName: 'Dr',
        location: 'Clinic',
        scheduledAt: DateTime(2026, 6, 16, 9, 0),
        status: AppointmentStatus.scheduled,
        createdAt: asOf,
        updatedAt: asOf,
      );
      expect(r.isFutureSlot(asOf), isTrue);
    });

    test('false when scheduledAt is before or equal to asOf', () {
      final past = AppointmentRecord(
        id: '2',
        userId: 'u',
        title: 'Visit',
        doctorName: 'Dr',
        location: 'Clinic',
        scheduledAt: DateTime(2026, 6, 14, 9, 0),
        status: AppointmentStatus.scheduled,
        createdAt: asOf,
        updatedAt: asOf,
      );
      expect(past.isFutureSlot(asOf), isFalse);

      final same = AppointmentRecord(
        id: '3',
        userId: 'u',
        title: 'Visit',
        doctorName: 'Dr',
        location: 'Clinic',
        scheduledAt: asOf,
        status: AppointmentStatus.attended,
        createdAt: asOf,
        updatedAt: asOf,
      );
      expect(same.isFutureSlot(asOf), isFalse);
    });

    test('future attended still counts as future slot', () {
      final r = AppointmentRecord(
        id: '4',
        userId: 'u',
        title: 'Visit',
        doctorName: 'Dr',
        location: 'Clinic',
        scheduledAt: DateTime(2026, 7, 1, 10, 0),
        status: AppointmentStatus.attended,
        createdAt: asOf,
        updatedAt: asOf,
      );
      expect(r.isFutureSlot(asOf), isTrue);
    });
  });
}
