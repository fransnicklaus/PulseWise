import 'package:dio/dio.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/ml_recommendation/data/models/ml_recommendation_models.dart';
import 'package:pulsewise/features/doctor/data/models/doctor_dashboard_models.dart';

class DoctorDashboardApi {
  DoctorDashboardApi(this._dio);

  final Dio _dio;

  Future<String> _readBearerToken() {
    return AppSessionStore.requireToken(
      missingMessage:
          'Bearer token tidak ditemukan. Silakan login ulang sebagai dokter.',
    );
  }

  Future<String> _readDoctorId() {
    return AppSessionStore.requireUserId(
      missingMessage: 'doctorId tidak ditemukan. Silakan login ulang.',
    );
  }

  Future<DoctorDashboardPatientSummaryResponse> fetchPatientSummary(
    String patientId,
  ) async {
    final token = await _readBearerToken();
    final doctorId = await _readDoctorId();

    final response = await _dio.get<Map<String, dynamic>>(
      '/doctors/$doctorId/dashboard/patients/$patientId',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final body = response.data;
    if (body == null || body['success'] != true) {
      throw Exception(
        (body?['message'] ?? 'Gagal mengambil ringkasan pasien dokter')
            .toString(),
      );
    }

    return DoctorDashboardPatientSummaryResponse.fromJson(body);
  }

  Future<DoctorDashboardPatientVitalsResponse> fetchPatientVitals(
    String patientId, {
    String timePeriod = 'last_30_days',
  }) async {
    final token = await _readBearerToken();
    final doctorId = await _readDoctorId();

    final response = await _dio.get<Map<String, dynamic>>(
      '/doctors/$doctorId/dashboard/patients/$patientId/vitals',
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
        (body?['message'] ?? 'Gagal mengambil time-series vital pasien dokter')
            .toString(),
      );
    }

    return DoctorDashboardPatientVitalsResponse.fromJson(body);
  }

  Future<MlRecommendationResponse?> fetchLatestPatientMlRecommendation(
    String patientId,
  ) async {
    final token = await _readBearerToken();
    final doctorId = await _readDoctorId();

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/doctors/$doctorId/dashboard/patients/$patientId/ml-recommendations/latest',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = response.data;
      if (body == null || body['success'] != true) {
        throw Exception(
          (body?['message'] ??
                  'Gagal mengambil rekomendasi ML terbaru pasien dokter')
              .toString(),
        );
      }

      return MlRecommendationResponse.fromJson(body);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }
      throw Exception('Gagal mengambil rekomendasi ML terbaru pasien dokter.');
    }
  }

  Future<MlRecommendationHistoryResponse> fetchPatientMlRecommendationHistory(
    String patientId, {
    int page = 1,
    int limit = 10,
  }) async {
    final token = await _readBearerToken();
    final doctorId = await _readDoctorId();

    final response = await _dio.get<Map<String, dynamic>>(
      '/doctors/$doctorId/dashboard/patients/$patientId/ml-recommendations/history',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final body = response.data;
    if (body == null) {
      throw Exception('Respons history rekomendasi dokter tidak valid');
    }

    if (body['success'] != true) {
      throw Exception(
        (body['message'] ?? 'Gagal mengambil riwayat rekomendasi dokter')
            .toString(),
      );
    }

    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    return MlRecommendationHistoryResponse.fromJson(data);
  }

  Future<MlRecommendationResponse> fetchPatientMlRecommendationHistoryDetail(
    String patientId,
    String resultId,
  ) async {
    final token = await _readBearerToken();
    final doctorId = await _readDoctorId();

    final response = await _dio.get<Map<String, dynamic>>(
      '/doctors/$doctorId/dashboard/patients/$patientId/ml-recommendations/history/$resultId',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final body = response.data;
    if (body == null || body['success'] != true) {
      throw Exception(
        (body?['message'] ??
                'Gagal mengambil detail riwayat rekomendasi dokter')
            .toString(),
      );
    }

    return MlRecommendationResponse.fromJson(body);
  }
}
