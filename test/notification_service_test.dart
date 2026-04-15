import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/services/notification_service.dart';

void main() {
  test('notificationIdForMedicine is stable and positive', () {
    const id = 'abc123xyz';
    final a = NotificationService.notificationIdForMedicine(id);
    final b = NotificationService.notificationIdForMedicine(id);
    expect(a, b);
    expect(a, greaterThan(0));
  });
}
