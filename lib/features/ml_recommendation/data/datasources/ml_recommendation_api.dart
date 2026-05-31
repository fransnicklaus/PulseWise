import 'package:dio/dio.dart';
import 'package:pulsewise/core/network/network_error_utils.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/ml_recommendation/data/models/ml_recommendation_models.dart';

class MlRecommendationApi {
  MlRecommendationApi(this._dio);

  final Dio _dio;

  Future<String> _readBearerToken() {
    return AppSessionStore.requireToken();
  }

  Future<String> _readPatientId() {
    return AppSessionStore.requireUserId(
      missingMessage: 'patientId tidak ditemukan. Silakan login ulang.',
    );
  }

  Future<String> _readUserId() {
    return AppSessionStore.requireUserId();
  }

  Future<MlRecommendationResponse?> fetchLatestMlRecommendation() async {
    final token = await _readBearerToken();
    final patientId = await _readPatientId();

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/users/$patientId/ml-recommendations/latest',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = response.data;
      if (body == null || body['success'] != true) {
        throw Exception(
          (body?['message'] ?? 'Gagal mengambil rekomendasi ML terbaru')
              .toString(),
        );
      }

      return MlRecommendationResponse.fromJson(body);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }

      if (isNetworkRequestError(error)) {
        rethrow;
      }

      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) {
          throw Exception(message);
        }
      }

      throw Exception('Gagal mengambil rekomendasi ML terbaru.');
    }
  }

  Future<MlRecommendationResponse> fetchMlRecommendations(String date) async {
    final token = await _readBearerToken();
    final patientId = await _readPatientId();

    final response = await _dio.post<Map<String, dynamic>>(
      '/users/$patientId/ml-recommendations/',
      queryParameters: {
        'date': date,
        'includePayload': 'true',
      },
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
        (body?['message'] ?? 'Gagal mengambil ML recommendations').toString(),
      );
    }

    return MlRecommendationResponse.fromJson(body);
  }

  Future<MlRecommendationHistoryResponse> fetchMlRecommendationHistory({
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final token = await _readBearerToken();
    final userId = await _readUserId();

    String formatDate(DateTime date) {
      return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '/users/$userId/ml-recommendations/history',
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
    if (body == null) {
      throw Exception('Respons history rekomendasi tidak valid dari server');
    }

    if (body['success'] != true) {
      throw Exception(
        (body['message'] ?? 'Gagal mengambil history rekomendasi').toString(),
      );
    }

    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    return MlRecommendationHistoryResponse.fromJson(data);
  }

  Future<MlRecommendationResponse> fetchMlRecommendationHistoryDetail(
    String resultId,
  ) async {
    final token = await _readBearerToken();
    final patientId = await _readPatientId();

    final response = await _dio.get<Map<String, dynamic>>(
      '/users/$patientId/ml-recommendations/history/$resultId',
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
        (body?['message'] ??
                'Gagal mengambil ML recommendations History Detail')
            .toString(),
      );
    }

    return MlRecommendationResponse.fromJson(body);
  }
}
