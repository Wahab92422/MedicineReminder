import 'package:flutter_test/flutter_test.dart';

import 'package:medicine_app/services/reminder_notification_payload.dart';

void main() {
  group('isLegacyInventoryBannerPayload', () {
    test('is true for show() low stock and expiry prefixes', () {
      expect(isLegacyInventoryBannerPayload('low_stock_Aspirin'), isTrue);
      expect(isLegacyInventoryBannerPayload('expiry_Aspirin'), isTrue);
    });

    test('is false for JSON reminder payloads', () {
      final json = ReminderNotificationPayload.encode(
        kind: ReminderPayloadKind.meal,
        entityId: 'e1',
        scheduledAt: DateTime(2026, 1, 1, 12),
      );
      expect(isLegacyInventoryBannerPayload(json), isFalse);
      expect(ReminderNotificationPayload.tryParse(json), isNotNull);
    });

    test('is false for empty', () {
      expect(isLegacyInventoryBannerPayload(''), isFalse);
    });
  });
}
