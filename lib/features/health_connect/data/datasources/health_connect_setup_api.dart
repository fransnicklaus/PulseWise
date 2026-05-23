import 'package:dio/dio.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';

class HealthConnectSetupApi {
  HealthConnectSetupApi(this._dio);

  final Dio _dio;
  static const Object unsetValue = Object();

  Future<String> _readBearerToken() {
    return AppSessionStore.requireToken();
  }

  Future<String> _readPatientId() {
    return AppSessionStore.requireUserId(
      missingMessage: 'patientId tidak ditemukan. Silakan login ulang.',
    );
  }

  Future<void> updateHealthConnectSetup({
    required String healthConnectPreference,
    Object? healthConnectStatus = unsetValue,
  }) async {
    final token = await _readBearerToken();
    final patientId = await _readPatientId();

    final payload = <String, dynamic>{
      'healthConnectPreference': healthConnectPreference,
    };

    if (!identical(healthConnectStatus, unsetValue)) {
      payload['healthConnectStatus'] = healthConnectStatus;
    }

    final response = await _dio.put<Map<String, dynamic>>(
      '/patients/$patientId/profile',
      data: payload,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final body = response.data;
    if (body == null || body['success'] != true) {
      throw Exception(
        (body?['message'] ?? 'Gagal memperbarui status Health Connect')
            .toString(),
      );
    }
  }
}
