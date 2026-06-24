import 'package:dio/dio.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/diary/data/models/patient_share_models.dart';

class PatientShareApi {
  PatientShareApi(this._dio);

  final Dio _dio;

  Future<PatientShare> createShare({
    int expiresInHours = 24,
  }) async {
    final token = await AppSessionStore.requireToken();
    final patientId = await AppSessionStore.requireUserId(
      missingMessage: 'patientId tidak ditemukan. Silakan login ulang.',
    );

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/patients/$patientId/shares',
        data: {'expiresInHours': expiresInHours},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = response.data;
      if (body == null || body['success'] == false) {
        throw Exception(
          (body?['message'] ?? 'Gagal membuat QR share pasien').toString(),
        );
      }

      final data = (body['data'] as Map<String, dynamic>?) ?? const {};
      final share = PatientShare.fromJson(data);
      if (share.qrData.trim().isEmpty) {
        throw Exception('Payload QR share pasien tidak tersedia.');
      }

      return share;
    } on DioException catch (error) {
      throw Exception(_extractErrorMessage(error));
    }
  }

  String _extractErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message']?.toString().trim() ?? '';
      if (message.isNotEmpty) return message;
    }

    final fallback = error.message?.trim() ?? '';
    if (fallback.isNotEmpty) return fallback;

    return 'Gagal membuat QR share pasien';
  }
}
