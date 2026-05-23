import 'package:dio/dio.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/home_dashboard/data/models/dashboard_overview_models.dart';

class DashboardOverviewApi {
  DashboardOverviewApi(this._dio);

  final Dio _dio;

  Future<String> _readBearerToken() {
    return AppSessionStore.requireToken();
  }

  Future<String> _readPatientId() {
    return AppSessionStore.requireUserId(
      missingMessage: 'patientId tidak ditemukan. Silakan login ulang.',
    );
  }

  Future<DashboardVitalsResponse> fetchDashboardVitals(
      String timePeriod) async {
    final token = await _readBearerToken();
    final patientId = await _readPatientId();

    final response = await _dio.get<Map<String, dynamic>>(
      '/users/$patientId/dashboard/vitals',
      queryParameters: {'timePeriod': timePeriod},
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final body = response.data;
    if (body == null || body['success'] != true) {
      throw Exception(
        (body?['message'] ?? 'Gagal mengambil data dashboard vitals')
            .toString(),
      );
    }

    return DashboardVitalsResponse.fromJson(body);
  }

  Future<QuickDashboardResponse?> fetchQuickDashboard() async {
    final token = await _readBearerToken();
    final patientId = await _readPatientId();

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/users/$patientId/dashboard',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = response.data;
      if (body == null || body['success'] != true) {
        throw Exception(
          (body?['message'] ?? 'Gagal mengambil data dashboard').toString(),
        );
      }

      return QuickDashboardResponse.fromJson(body);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }
      throw Exception('Gagal mengambil data dashboard.');
    }
  }
}
