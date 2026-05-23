import 'package:dio/dio.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/ml_assessment/data/models/ml_assessment_models.dart';

class MlAssessmentApi {
  MlAssessmentApi(this._dio);

  final Dio _dio;

  Future<String> _readBearerToken() {
    return AppSessionStore.requireToken();
  }

  Future<String> _readPatientId() {
    return AppSessionStore.requireUserId(
      missingMessage: 'patientId tidak ditemukan. Silakan login ulang.',
    );
  }

  Future<MlAssessmentRecord?> fetchLatestMlAssessment() async {
    final token = await _readBearerToken();
    final patientId = await _readPatientId();

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/patients/$patientId/ml-assessments/latest',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      final body = response.data ?? <String, dynamic>{};
      if (body['success'] != true) {
        throw Exception(
          (body['message'] ?? 'Gagal mengambil asesmen ML terbaru').toString(),
        );
      }

      final record = MlAssessmentRecord.fromApiData(body['data']);
      return record.isEmpty ? null : record;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }

      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) {
          throw Exception(message);
        }
      }

      throw Exception('Gagal mengambil asesmen ML terbaru.');
    }
  }

  Future<List<MlAssessmentRecord>> fetchMlAssessments({
    String? startDate,
    String? endDate,
  }) async {
    final token = await _readBearerToken();
    final patientId = await _readPatientId();

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/patients/$patientId/ml-assessments',
        queryParameters: {
          if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
          if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      final body = response.data ?? <String, dynamic>{};
      if (body['success'] != true) {
        throw Exception(
          (body['message'] ?? 'Gagal mengambil daftar asesmen ML').toString(),
        );
      }

      final data = body['data'];
      if (data is List) {
        return data.map(MlAssessmentRecord.fromApiData).toList();
      }

      return const <MlAssessmentRecord>[];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const <MlAssessmentRecord>[];
      }

      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) {
          throw Exception(message);
        }
      }

      throw Exception('Gagal mengambil daftar asesmen ML.');
    }
  }

  Future<MlReadinessResult> fetchMlReadiness(String date) async {
    final token = await _readBearerToken();
    final patientId = await _readPatientId();

    final response = await _dio.get<Map<String, dynamic>>(
      '/users/$patientId/ml-readiness',
      queryParameters: {'date': date},
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final body = response.data;
    if (body == null || body['success'] != true) {
      throw Exception(
        (body?['message'] ?? 'Gagal mengambil status ML readiness').toString(),
      );
    }

    return MlReadinessResult.fromApiData(body['data']);
  }

  Future<MlPredictionResult> fetchMlPrediction(String date) async {
    final token = await _readBearerToken();
    final patientId = await _readPatientId();

    final response = await _dio.post<Map<String, dynamic>>(
      '/users/$patientId/ml-predictions',
      queryParameters: {'date': date, 'includePayload': 'true'},
      data: {},
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final body = response.data;
    if (body == null || body['success'] != true) {
      throw Exception(
        (body?['message'] ?? 'Gagal mengambil prediksi ML').toString(),
      );
    }

    return MlPredictionResult.fromApiData(body['data']);
  }

  Future<MlAssessmentRecord> submitMlAssessment({
    required Map<String, dynamic> payload,
  }) async {
    final token = await _readBearerToken();
    final patientId = await _readPatientId();

    final response = await _dio.post<Map<String, dynamic>>(
      '/patients/$patientId/ml-assessments',
      data: payload,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ),
    );

    final body = response.data ?? <String, dynamic>{};
    if (body['success'] != true) {
      throw Exception(
        (body['message'] ?? 'Gagal menyimpan asesmen ML').toString(),
      );
    }

    return MlAssessmentRecord.fromApiData(body['data']);
  }

  Future<MlAssessmentRecord> updateMlAssessment({
    required String assessmentId,
    required Map<String, dynamic> payload,
  }) async {
    final token = await _readBearerToken();
    final patientId = await _readPatientId();

    final response = await _dio.put<Map<String, dynamic>>(
      '/patients/$patientId/ml-assessments/$assessmentId',
      data: payload,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ),
    );

    final body = response.data ?? <String, dynamic>{};
    if (body['success'] != true) {
      throw Exception(
        (body['message'] ?? 'Gagal memperbarui asesmen ML').toString(),
      );
    }

    return MlAssessmentRecord.fromApiData(body['data']);
  }

  Future<MlAssessmentRecord> saveMlAssessment({
    String? assessmentId,
    required Map<String, dynamic> payload,
  }) async {
    if (assessmentId != null && assessmentId.trim().isNotEmpty) {
      return updateMlAssessment(
        assessmentId: assessmentId,
        payload: payload,
      );
    }

    return submitMlAssessment(payload: payload);
  }
}
