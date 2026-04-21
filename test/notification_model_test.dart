import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medicine_app/features/notifications/notification_model.dart';

void main() {
  group('AppNotification.fromMap', () {
    test('parses valid Firestore-shaped map', () {
      final created = DateTime(2025, 6, 1, 12, 30);
      final n = AppNotification.fromMap('nid', {
        'userId': 'uid1',
        'type': 0,
        'title': 'T',
        'message': 'M',
        'medicineId': 'mid',
        'medicineName': 'Aspirin',
        'createdAt': Timestamp.fromDate(created),
        'isRead': false,
      });
      expect(n.id, 'nid');
      expect(n.userId, 'uid1');
      expect(n.type, NotificationType.lowStock);
      expect(n.createdAt, created);
      expect(n.isRead, false);
    });

    test('throws on invalid type index', () {
      expect(
        () => AppNotification.fromMap('x', {
          'userId': 'u',
          'type': 99,
          'title': 't',
          'message': 'm',
          'medicineId': 'm',
          'medicineName': 'n',
          'createdAt': Timestamp.now(),
        }),
        throwsFormatException,
      );
    });
  });
}
