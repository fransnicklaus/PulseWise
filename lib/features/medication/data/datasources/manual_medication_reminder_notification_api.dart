import 'package:dio/dio.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';

import '../models/manual_medication_reminder_notification_response.dart';

class ManualMedicationReminderNotificationApi {
  ManualMedicationReminderNotificationApi(this._dio);

  final Dio _dio;

  Future<ManualMedicationReminderNotificationResponse> sendReminder({
    required String userId,
    required String medicationId,
    required String reminderId,
    required DateTime scheduledAt,
    String status = 'Open',
  }) async {
    final token = await _readBearerToken();

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/users/$userId/medications/$medicationId/reminder-notification',
        data: {
          'reminderId': reminderId,
          'scheduledDate': _formatDate(scheduledAt),
          'scheduledTime': _formatTime(scheduledAt),
          'status': status,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = response.data;
      if (body == null) {
        throw Exception(
          'Respons manual medication reminder tidak valid dari server',
        );
      }

      if (body['success'] != true) {
        throw Exception(
          (body['message'] ?? 'Gagal mengirim manual medication reminder')
              .toString(),
        );
      }

      return ManualMedicationReminderNotificationResponse.fromJson(body);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<String> _readBearerToken() async {
    return AppSessionStore.requireToken();
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

    return 'Gagal mengirim manual medication reminder';
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
