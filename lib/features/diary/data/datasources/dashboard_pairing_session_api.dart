import 'package:dio/dio.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';

class DashboardPairingSessionApi {
  DashboardPairingSessionApi(this._dio);

  final Dio _dio;

  Future<String> confirmPairing({
    required String pairingToken,
    String source = 'qr_dashboard_pairing',
  }) async {
    final normalizedPairingToken = pairingToken.trim();
    if (normalizedPairingToken.isEmpty) {
      throw Exception('QR pairing token tidak valid.');
    }

    final token = await AppSessionStore.requireToken();

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/dashboard/pairing-sessions/confirm',
        data: {
          'pairingToken': normalizedPairingToken,
          'source': source,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = response.data;
      if (body == null) {
        throw Exception('Respons pairing dashboard tidak valid.');
      }

      if (body['success'] == false) {
        throw Exception(
          (body['message'] ?? 'Gagal menghubungkan dashboard dokter')
              .toString(),
        );
      }

      final message =
          (body['message'] ?? 'Dashboard dokter berhasil dihubungkan')
              .toString()
              .trim();
      if (message.isNotEmpty) {
        return message;
      }

      return 'Dashboard dokter berhasil dihubungkan';
    } on DioException catch (error) {
      throw Exception(_extractErrorMessage(error));
    }
  }

  String _extractErrorMessage(DioException error) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message;
      }
    }

    if (data is Map) {
      final message = data['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message;
      }
    }

    final fallback = error.message?.trim() ?? '';
    if (fallback.isNotEmpty) {
      return fallback;
    }

    return 'Gagal menghubungkan dashboard dokter';
  }
}
