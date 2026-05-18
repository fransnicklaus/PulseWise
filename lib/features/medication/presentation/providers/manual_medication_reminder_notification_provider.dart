import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/features/medication/data/datasources/manual_medication_reminder_notification_api.dart';

final manualMedicationReminderNotificationApiProvider =
    Provider<ManualMedicationReminderNotificationApi>((ref) {
  return ManualMedicationReminderNotificationApi(ref.watch(apiDioProvider));
});
