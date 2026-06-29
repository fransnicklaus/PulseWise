import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/features/medication/data/datasources/manual_medication_reminder_notification_api.dart';
import 'package:pulsewise/features/medication/data/datasources/medication_api.dart';
import 'package:pulsewise/features/medication/presentation/providers/manual_medication_reminder_notification_provider.dart';
import 'package:pulsewise/features/medication/presentation/providers/medication_api_provider.dart';

void main() {
  group('medication API providers', () {
    test('medicationApiProvider creates API from shared Dio', () {
      final container = ProviderContainer(
        overrides: [
          apiDioProvider.overrideWithValue(Dio()),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(medicationApiProvider), isA<MedicationApi>());
    });

    test('manual reminder notification provider creates API from shared Dio',
        () {
      final container = ProviderContainer(
        overrides: [
          apiDioProvider.overrideWithValue(Dio()),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(manualMedicationReminderNotificationApiProvider),
        isA<ManualMedicationReminderNotificationApi>(),
      );
    });
  });
}
