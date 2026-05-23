import 'package:dio/dio.dart';
import 'package:pulsewise/features/ml_questionnaire/data/models/ml_questionnaire_models.dart';

class MlQuestionnaireApi {
  MlQuestionnaireApi(this._dio);

  final Dio _dio;

  Future<void> submitMlProfile({
    required String token,
    required String patientId,
    required Map<String, dynamic> payload,
  }) async {
    if (token.trim().isEmpty) {
      throw Exception('Bearer token tidak ditemukan. Silakan login ulang.');
    }
    if (patientId.trim().isEmpty) {
      throw Exception('patientId tidak ditemukan. Silakan login ulang.');
    }

    final response = await _dio.put<Map<String, dynamic>>(
      '/patients/$patientId/ml-profile',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ),
      data: payload,
    );

    final body = response.data ?? <String, dynamic>{};
    if (body['success'] != true) {
      throw Exception(
        (body['message'] ?? 'Gagal menyimpan kuisioner ML').toString(),
      );
    }
  }

  Future<MlQuestionnaireProfile> fetchMlProfile({
    required String token,
    required String patientId,
  }) async {
    if (token.trim().isEmpty) {
      throw Exception('Bearer token tidak ditemukan. Silakan login ulang.');
    }
    if (patientId.trim().isEmpty) {
      throw Exception('patientId tidak ditemukan. Silakan login ulang.');
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/patients/$patientId/ml-profile',
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
          (body['message'] ?? 'Gagal mengambil kuisioner ML').toString(),
        );
      }

      return MlQuestionnaireProfile.fromApiData(body['data']);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const MlQuestionnaireProfile(answers: <String, dynamic>{});
      }

      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) {
          throw Exception(message);
        }
      }

      throw Exception('Gagal mengambil kuisioner ML.');
    }
  }
}
