import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/features/appointments/appointment_entry.dart';
import 'package:medicine_app/features/appointments/appointment_statuses.dart';

void main() {
  test('AppointmentEntry round-trips map fields', () {
    final scheduled = DateTime(2026, 6, 10, 14, 30);
    final created = DateTime(2026, 4, 1);
    final map = <String, dynamic>{
      'title': 'Cardiology',
      'scheduledAt': Timestamp.fromDate(scheduled),
      'status': AppointmentStatuses.scheduled,
      'notes': 'Bring records',
      'location': 'Main St Clinic',
      'doctor': 'Dr. Lee',
      'createdAt': Timestamp.fromDate(created),
      'updatedAt': Timestamp.fromDate(created),
    };

    final entry = AppointmentEntry.fromMap('a1', map);
    expect(entry.id, 'a1');
    expect(entry.title, 'Cardiology');
    expect(entry.scheduledAt, scheduled);
    expect(entry.status, AppointmentStatuses.scheduled);
    expect(entry.notes, 'Bring records');
    expect(entry.location, 'Main St Clinic');
    expect(entry.doctor, 'Dr. Lee');

    final createPayload = entry.toCreateMapClientTs(created);
    expect(createPayload['title'], 'Cardiology');
    expect(createPayload['status'], AppointmentStatuses.scheduled);
    expect(createPayload['notes'], 'Bring records');
    expect(createPayload['location'], 'Main St Clinic');
    expect(createPayload['doctor'], 'Dr. Lee');
  });

  test('AppointmentEntry maps legacy Pending status to Scheduled', () {
    final scheduled = DateTime(2026, 6, 10, 14, 30);
    final created = DateTime(2026, 4, 1);
    final map = <String, dynamic>{
      'title': 'Legacy',
      'scheduledAt': Timestamp.fromDate(scheduled),
      'status': 'Pending',
      'notes': '',
      'location': '',
      'createdAt': Timestamp.fromDate(created),
      'updatedAt': Timestamp.fromDate(created),
    };
    final entry = AppointmentEntry.fromMap('a2', map);
    expect(entry.status, AppointmentStatuses.scheduled);
  });

  test('AppointmentStatuses lists all three labels', () {
    expect(AppointmentStatuses.all, hasLength(3));
    expect(AppointmentStatuses.all, contains(AppointmentStatuses.attended));
    expect(AppointmentStatuses.all, contains(AppointmentStatuses.missed));
    expect(AppointmentStatuses.all, contains(AppointmentStatuses.scheduled));
  });
}
