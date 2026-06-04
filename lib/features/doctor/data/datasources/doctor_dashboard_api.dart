import 'package:dio/dio.dart';
import 'package:pulsewise/core/network/network_error_utils.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/ml_recommendation/data/models/ml_recommendation_models.dart';
import 'package:pulsewise/features/doctor/data/models/doctor_dashboard_models.dart';
import 'package:pulsewise/features/doctor/data/models/doctor_heart_risk_models.dart';

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

  Exception _requestError(DioException error, String fallbackMessage) {
    if (isNetworkRequestError(error)) {
      throw error;
    }

    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return Exception(message);
      }
    }

    return Exception(fallbackMessage);
  }

  Future<DoctorDashboardPatientSummaryResponse> fetchPatientSummary(
    String patientId,
  ) async {
    final token = await _readBearerToken();
    final doctorId = await _readDoctorId();

    try {
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
    } on DioException catch (error) {
      throw _requestError(error, 'Gagal mengambil ringkasan pasien dokter.');
    }
  }

  Future<DoctorDashboardPatientsListResponse> fetchPatients({
    int page = 1,
    int limit = 20,
  }) async {
    final token = await _readBearerToken();
    final doctorId = await _readDoctorId();

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/doctors/$doctorId/dashboard/patients',
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
      if (body == null || body['success'] != true) {
        throw Exception(
          (body?['message'] ?? 'Gagal mengambil daftar pasien dokter')
              .toString(),
        );
      }

      final data = (body['data'] as Map<String, dynamic>?) ?? const {};
      return DoctorDashboardPatientsListResponse.fromJson(data);
    } on DioException catch (error) {
      throw _requestError(error, 'Gagal mengambil daftar pasien dokter.');
    }
  }

  Future<DoctorDashboardPatientVitalsResponse> fetchPatientVitals(
    String patientId, {
    String timePeriod = 'last_30_days',
  }) async {
    final token = await _readBearerToken();
    final doctorId = await _readDoctorId();

    try {
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
          (body?['message'] ??
                  'Gagal mengambil time-series vital pasien dokter')
              .toString(),
        );
      }

      return DoctorDashboardPatientVitalsResponse.fromJson(body);
    } on DioException catch (error) {
      throw _requestError(
        error,
        'Gagal mengambil time-series vital pasien dokter.',
      );
    }
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
      throw _requestError(
        error,
        'Gagal mengambil rekomendasi ML terbaru pasien dokter.',
      );
    }
  }

  Future<MlRecommendationHistoryResponse> fetchPatientMlRecommendationHistory(
    String patientId, {
    int page = 1,
    int limit = 10,
  }) async {
    final token = await _readBearerToken();
    final doctorId = await _readDoctorId();

    try {
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
    } on DioException catch (error) {
      throw _requestError(error, 'Gagal mengambil riwayat rekomendasi dokter.');
    }
  }

  Future<MlRecommendationResponse> fetchPatientMlRecommendationHistoryDetail(
    String patientId,
    String resultId,
  ) async {
    final token = await _readBearerToken();
    final doctorId = await _readDoctorId();

    try {
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
    } on DioException catch (error) {
      throw _requestError(
        error,
        'Gagal mengambil detail riwayat rekomendasi dokter.',
      );
    }
  }

  Future<DoctorHeartRiskAssessmentRecord?>
      fetchLatestPatientHeartRiskAssessment(
    String patientId,
  ) async {
    final token = await _readBearerToken();
    final doctorId = await _readDoctorId();

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/doctors/$doctorId/dashboard/patients/$patientId/heart-risk-model/assessment/latest',
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
                  'Gagal mengambil asesmen heart risk terbaru pasien dokter')
              .toString(),
        );
      }

      final data = (body['data'] as Map<String, dynamic>?) ?? const {};
      if (data.isEmpty) {
        return null;
      }

      return DoctorHeartRiskAssessmentRecord.fromJson(data);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }

      throw _requestError(
        error,
        'Gagal mengambil asesmen heart risk terbaru pasien dokter.',
      );
    }
  }

  Future<DoctorHeartRiskReadinessResult> fetchPatientHeartRiskReadiness(
    String patientId,
  ) async {
    final token = await _readBearerToken();
    final doctorId = await _readDoctorId();

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/doctors/$doctorId/dashboard/patients/$patientId/heart-risk-model/readiness',
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
                  'Gagal mengambil status readiness heart risk pasien dokter')
              .toString(),
        );
      }

      final data = (body['data'] as Map<String, dynamic>?) ?? const {};
      return DoctorHeartRiskReadinessResult.fromJson(data);
    } on DioException catch (error) {
      throw _requestError(
        error,
        'Gagal mengambil status readiness heart risk pasien dokter.',
      );
    }
  }

  Future<DoctorHeartRiskPredictionResult?>
      fetchLatestPatientHeartRiskPrediction(
    String patientId,
  ) async {
    final token = await _readBearerToken();
    final doctorId = await _readDoctorId();

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/doctors/$doctorId/dashboard/patients/$patientId/heart-risk-model/predictions/latest',
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
                  'Gagal mengambil prediksi heart risk terbaru pasien dokter')
              .toString(),
        );
      }

      final data = (body['data'] as Map<String, dynamic>?) ?? const {};
      if (data.isEmpty) {
        return null;
      }

      return DoctorHeartRiskPredictionResult.fromJson(data);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }

      throw _requestError(
        error,
        'Gagal mengambil prediksi heart risk terbaru pasien dokter.',
      );
    }
  }

  Future<DoctorHeartRiskAssessmentRecord> savePatientHeartRiskAssessment(
    String patientId, {
    String? assessmentId,
    required Map<String, dynamic> payload,
  }) async {
    final token = await _readBearerToken();
    final doctorId = await _readDoctorId();
    final hasAssessmentId = (assessmentId ?? '').trim().isNotEmpty;

    try {
      final response = hasAssessmentId
          ? await _dio.put<Map<String, dynamic>>(
              '/doctors/$doctorId/dashboard/patients/$patientId/heart-risk-model/assessments/${assessmentId!.trim()}',
              data: payload,
              options: Options(
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
              ),
            )
          : await _dio.post<Map<String, dynamic>>(
              '/doctors/$doctorId/dashboard/patients/$patientId/heart-risk-model/assessments',
              data: payload,
              options: Options(
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
              ),
            );

      final body = response.data;
      if (body == null || body['success'] != true) {
        throw Exception(
          (body?['message'] ??
                  'Gagal menyimpan asesmen heart risk pasien dokter')
              .toString(),
        );
      }

      final data = (body['data'] as Map<String, dynamic>?) ?? const {};
      return DoctorHeartRiskAssessmentRecord.fromJson(data);
    } on DioException catch (error) {
      throw _requestError(
        error,
        'Gagal menyimpan asesmen heart risk pasien dokter.',
      );
    }
  }

  Future<DoctorHeartRiskPredictionResult> runPatientHeartRiskPrediction(
    String patientId, {
    bool includePayload = true,
  }) async {
    final token = await _readBearerToken();
    final doctorId = await _readDoctorId();

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/doctors/$doctorId/dashboard/patients/$patientId/heart-risk-model/predictions',
        queryParameters: {
          'includePayload': includePayload.toString(),
        },
        data: const {},
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
                  'Gagal menjalankan prediksi heart risk pasien dokter')
              .toString(),
        );
      }

      final data = (body['data'] as Map<String, dynamic>?) ?? const {};
      return DoctorHeartRiskPredictionResult.fromJson(data);
    } on DioException catch (error) {
      throw _requestError(
        error,
        'Gagal menjalankan prediksi heart risk pasien dokter.',
      );
    }
  }

  Future<DoctorHeartRiskPredictionHistoryPageData>
      fetchPatientHeartRiskPredictionHistory(
    String patientId, {
    int page = 1,
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final token = await _readBearerToken();
    final doctorId = await _readDoctorId();

    String formatDate(DateTime date) {
      return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/doctors/$doctorId/dashboard/patients/$patientId/heart-risk-model/predictions/history',
        queryParameters: {
          'page': page,
          'limit': limit,
          'startDate': startDate != null ? formatDate(startDate) : null,
          'endDate': endDate != null ? formatDate(endDate) : null,
        },
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
                  'Gagal mengambil riwayat prediksi heart risk pasien dokter')
              .toString(),
        );
      }

      final data = (body['data'] as Map<String, dynamic>?) ?? const {};
      return DoctorHeartRiskPredictionHistoryPageData.fromJson(data);
    } on DioException catch (error) {
      throw _requestError(
        error,
        'Gagal mengambil riwayat prediksi heart risk pasien dokter.',
      );
    }
  }

  Future<DoctorHeartRiskPredictionResult>
      fetchPatientHeartRiskPredictionHistoryDetail(
    String patientId,
    String resultId,
  ) async {
    final token = await _readBearerToken();
    final doctorId = await _readDoctorId();

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/doctors/$doctorId/dashboard/patients/$patientId/heart-risk-model/predictions/history/$resultId',
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
                  'Gagal mengambil detail riwayat prediksi heart risk pasien dokter')
              .toString(),
        );
      }

      final data = (body['data'] as Map<String, dynamic>?) ?? const {};
      return DoctorHeartRiskPredictionResult.fromJson(data);
    } on DioException catch (error) {
      throw _requestError(
        error,
        'Gagal mengambil detail riwayat prediksi heart risk pasien dokter.',
      );
    }
  }
}
