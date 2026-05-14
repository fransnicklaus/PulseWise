import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pulsewise/features/dashboard/presentation/providers/profile_provider.dart';

class MedicationReminderNotificationPayload {
  const MedicationReminderNotificationPayload({
    required this.medicationId,
    required this.rawData,
    this.status,
    this.scheduledDate,
    this.scheduledTime,
  });

  final String medicationId;
  final String? status;
  final DateTime? scheduledDate;
  final String? scheduledTime;
  final Map<String, dynamic> rawData;

  DateTime get targetDate {
    final date = scheduledDate ?? DateTime.now();
    return DateTime(date.year, date.month, date.day);
  }

  String get debugSummary {
    return 'Item ID: $medicationId, '
        'Status: ${status ?? '-'}, '
        'Scheduled Date: ${scheduledDate?.toIso8601String() ?? '-'}, '
        'Scheduled Time: ${scheduledTime ?? '-'}';
  }

  bool matches(MedicationCalendarItem item) {
    if (item.medicationId != medicationId) return false;

    if (scheduledDate != null &&
        !_isSameDay(item.scheduledDate, scheduledDate)) {
      return false;
    }

    final expectedTime = scheduledTime?.trim();
    if (expectedTime != null &&
        expectedTime.isNotEmpty &&
        item.scheduledTime.trim() != expectedTime) {
      return false;
    }

    return true;
  }

  static MedicationReminderNotificationPayload? fromData(
    Map<String, dynamic> rawData,
  ) {
    final normalized = <String, String>{};
    rawData.forEach((key, value) {
      normalized[_normalizeKey(key)] = value?.toString().trim() ?? '';
    });

    var medicationId = _firstNonEmpty(
      normalized,
      const ['medicationid', 'medication_id', 'itemid', 'item_id'],
    );
    var status = _nullable(
      _firstNonEmpty(
        normalized,
        const ['status', 'medicationstatus', 'medication_status'],
      ),
    );
    var scheduledDateRaw = _firstNonEmpty(
      normalized,
      const ['scheduleddate', 'scheduled_date', 'medicationdate', 'date'],
    );
    var scheduledTime = _nullable(
      _firstNonEmpty(
        normalized,
        const ['scheduledtime', 'scheduled_time', 'medicationtime', 'time'],
      ),
    );

    if (medicationId.isEmpty) {
      final summary = _firstNonEmpty(
        normalized,
        const [
          'payload',
          'summary',
          'details',
          'message',
          'debugsummary',
          'itemsummary',
        ],
      );
      if (summary.isNotEmpty) {
        medicationId = _extractSummaryValue(summary, 'Item ID');
        status ??= _nullable(_extractSummaryValue(summary, 'Status'));
        scheduledDateRaw = scheduledDateRaw.isNotEmpty
            ? scheduledDateRaw
            : _extractSummaryValue(summary, 'Scheduled Date');
        scheduledTime ??=
            _nullable(_extractSummaryValue(summary, 'Scheduled Time'));
      }
    }

    if (medicationId.isEmpty) {
      return null;
    }

    return MedicationReminderNotificationPayload(
      medicationId: medicationId,
      status: status,
      scheduledDate: _parseDate(scheduledDateRaw),
      scheduledTime: scheduledTime,
      rawData: rawData,
    );
  }

  static String _normalizeKey(String key) {
    return key.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
  }

  static String _firstNonEmpty(
    Map<String, String> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key]?.trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  static String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static DateTime? _parseDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.tryParse(trimmed);
  }

  static String _extractSummaryValue(String summary, String label) {
    final pattern = RegExp('$label:\\s*([^,]+)', caseSensitive: false);
    final match = pattern.firstMatch(summary);
    return match?.group(1)?.trim() ?? '';
  }

  static bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class ReminderNotificationCoordinator extends ChangeNotifier {
  ReminderNotificationCoordinator._();

  static final ReminderNotificationCoordinator instance =
      ReminderNotificationCoordinator._();

  MedicationReminderNotificationPayload? _pendingPayload;

  MedicationReminderNotificationPayload? get pendingPayload => _pendingPayload;

  bool get hasPendingPayload => _pendingPayload != null;

  void queueFromData(
    Map<String, dynamic> data, {
    String source = 'unknown',
  }) {
    debugPrint('[ReminderNotification] Raw payload from $source: $data');
    final payload = MedicationReminderNotificationPayload.fromData(data);
    if (payload == null) {
      debugPrint('[ReminderNotification] Ignored $source payload: $data');
      return;
    }

    _pendingPayload = payload;
    debugPrint(
      '[ReminderNotification] Queued from $source: ${payload.debugSummary}',
    );
    notifyListeners();
  }

  void queueFromEncodedPayload(
    String? payload, {
    String source = 'local_notification',
  }) {
    final raw = payload?.trim() ?? '';
    if (raw.isEmpty) {
      debugPrint('[ReminderNotification] Empty encoded payload from $source');
      return;
    }

    debugPrint('[ReminderNotification] Encoded payload from $source: $raw');

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        queueFromData(decoded, source: source);
        return;
      }

      if (decoded is Map) {
        queueFromData(Map<String, dynamic>.from(decoded), source: source);
        return;
      }
    } catch (_) {
      // Fall through to summary-string parsing.
    }

    queueFromData({'payload': raw}, source: source);
  }

  MedicationReminderNotificationPayload? consumePendingPayload() {
    final payload = _pendingPayload;
    if (payload != null) {
      debugPrint(
        '[ReminderNotification] Consuming pending payload: ${payload.debugSummary}',
      );
    }
    _pendingPayload = null;
    return payload;
  }

  void clearPendingPayload() {
    if (_pendingPayload == null) return;
    debugPrint(
      '[ReminderNotification] Clearing pending payload: ${_pendingPayload!.debugSummary}',
    );
    _pendingPayload = null;
    notifyListeners();
  }
}
