import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/features/doctor/data/datasources/doctor_dashboard_api.dart';
import 'package:pulsewise/features/doctor/presentation/providers/doctor_dashboard_provider.dart';

void main() {
  group('doctor API providers', () {
    test('doctorDashboardApiProvider creates API from shared Dio', () {
      final container = ProviderContainer(
        overrides: [
          apiDioProvider.overrideWithValue(Dio()),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(doctorDashboardApiProvider),
        isA<DoctorDashboardApi>(),
      );
    });
  });
}
