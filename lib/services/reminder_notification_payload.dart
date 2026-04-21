import 'dart:convert';

/// Types routed to [ReminderIndicatorScreen] from local notification taps.
enum ReminderPayloadKind { meal, appointment, medicineLog, agenda, expiry }

/// Parsed payload from OS notification `payload` (JSON).
class ReminderNotificationPayload {
  const ReminderNotificationPayload({
    required this.kind,
    required this.entityId,
    required this.scheduledAtMs,
  });

  final ReminderPayloadKind kind;
  final String entityId;
  final int scheduledAtMs;

  DateTime get scheduledAt =>
      DateTime.fromMillisecondsSinceEpoch(scheduledAtMs, isUtc: false);

  /// JSON: `{ "r": "meal|appointment|medicineLog|agenda", "id": "...", "ms": 123 }`
  static String encode({
    required ReminderPayloadKind kind,
    required String entityId,
    required DateTime scheduledAt,
  }) {
    final wire = switch (kind) {
      ReminderPayloadKind.meal => 'meal',
      ReminderPayloadKind.appointment => 'appointment',
      ReminderPayloadKind.medicineLog => 'medicineLog',
      ReminderPayloadKind.agenda => 'agenda',
      ReminderPayloadKind.expiry => 'expiry',
    };
    return jsonEncode(<String, Object?>{
      'r': wire,
      'id': entityId,
      'ms': scheduledAt.millisecondsSinceEpoch,
    });
  }

  static ReminderNotificationPayload? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>?;
      if (m == null) return null;
      final r = m['r'] as String?;
      final id = m['id'] as String?;
      final ms = m['ms'];
      if (r == null || id == null || id.isEmpty) return null;
      final msInt = ms is int ? ms : (ms is num ? ms.toInt() : null);
      if (msInt == null) return null;
      final kind = switch (r) {
        'meal' => ReminderPayloadKind.meal,
        'appointment' => ReminderPayloadKind.appointment,
        'medicineLog' => ReminderPayloadKind.medicineLog,
        'agenda' => ReminderPayloadKind.agenda,
        'expiry' => ReminderPayloadKind.expiry,
        _ => null,
      };
      if (kind == null) return null;
      return ReminderNotificationPayload(
        kind: kind,
        entityId: id,
        scheduledAtMs: msInt,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Payloads from [NotificationService.showLowStockNotification] / [showExpiryNotification]
/// (not JSON). Taps should still open inventory.
bool isLegacyInventoryBannerPayload(String raw) {
  if (raw.isEmpty) return false;
  return raw.startsWith('low_stock_') || raw.startsWith('expiry_');
}
