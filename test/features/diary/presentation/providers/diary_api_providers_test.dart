import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/features/diary/data/datasources/dashboard_pairing_session_api.dart';
import 'package:pulsewise/features/diary/data/datasources/patient_share_api.dart';
import 'package:pulsewise/features/diary/presentation/providers/dashboard_pairing_session_provider.dart';
import 'package:pulsewise/features/diary/presentation/providers/patient_share_provider.dart';

void main() {
  group('diary API providers', () {
    test('dashboardPairingSessionApiProvider creates API from shared Dio', () {
      final container = ProviderContainer(
        overrides: [
          apiDioProvider.overrideWithValue(Dio()),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(dashboardPairingSessionApiProvider),
        isA<DashboardPairingSessionApi>(),
      );
    });

    test('patientShareApiProvider creates API from shared Dio', () {
      final container = ProviderContainer(
        overrides: [
          apiDioProvider.overrideWithValue(Dio()),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(patientShareApiProvider),
        isA<PatientShareApi>(),
      );
    });
  });
}
