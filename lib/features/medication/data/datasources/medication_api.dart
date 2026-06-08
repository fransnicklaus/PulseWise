import 'package:dio/dio.dart';
import 'package:pulsewise/core/network/network_error_utils.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/medication/data/models/medication_models.dart';

class MedicationApi {
  MedicationApi(this._dio);

  final Dio _dio;

  Future<String> _readBearerToken() {
    return AppSessionStore.requireToken();
  }

  Future<String> _readUserId() {
    return AppSessionStore.requireUserId();
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Exception _requestError(DioException error, String fallbackMessage) {
    if (isNetworkRequestError(error)) {
      throw error;
    }

    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return Exception(message.trim());
      }
    }

    final responseMessage = error.response?.statusMessage?.trim();
    if (responseMessage != null && responseMessage.isNotEmpty) {
      return Exception(responseMessage);
    }

    return Exception(fallbackMessage);
  }

  Future<void> addMedication({
    required String name,
    required String form,
    required String color,
    required num singleDose,
    required String singleDoseUnit,
    required String startDate,
    required String frequency,
    int? numOfDays,
    List<int>? daysOfWeek,
    required List<String> intakeTimes,
    String? note,
  }) async {
    final token = await _readBearerToken();
    final userId = await _readUserId();
    final normalizedFrequency = frequency.toLowerCase();

    final response = await _dio.post<Map<String, dynamic>>(
      '/users/$userId/medications',
      data: {
        'name': name,
        'form': form,
        'color': color,
        'singleDose': singleDose,
        'singleDoseUnit': singleDoseUnit,
        'startDate': startDate,
        'frequency': normalizedFrequency,
        if (normalizedFrequency == 'daily' && numOfDays != null)
          'numOfDays': numOfDays,
        if (normalizedFrequency == 'weekly' && daysOfWeek != null)
          'daysOfWeek': daysOfWeek,
        'intakeTimes': intakeTimes,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
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
        (body?['message'] ?? 'Gagal menambah rutinitas').toString(),
      );
    }
  }

  Future<MedicationListResponse> fetchMedications({
    int page = 1,
    int limit = 10,
  }) async {
    final token = await _readBearerToken();
    final userId = await _readUserId();

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/users/$userId/medications',
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
        throw Exception('Respons daftar rutinitas tidak valid dari server');
      }

      if (body['success'] != true) {
        throw Exception(
          (body['message'] ?? 'Gagal mengambil daftar rutinitas').toString(),
        );
      }

      final data = (body['data'] as Map<String, dynamic>?) ?? const {};
      return MedicationListResponse.fromJson(data);
    } on DioException catch (error) {
      throw _requestError(error, 'Gagal mengambil daftar rutinitas.');
    }
  }

  Future<MedicationItem> fetchMedicationDetail(String medicationId) async {
    final token = await _readBearerToken();
    final userId = await _readUserId();

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/users/$userId/medications/$medicationId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = response.data;
      if (body == null) {
        throw Exception('Respons detail rutinitas tidak valid dari server');
      }

      if (body['success'] != true) {
        throw Exception(
          (body['message'] ?? 'Gagal mengambil detail rutinitas').toString(),
        );
      }

      final data = (body['data'] as Map<String, dynamic>?) ?? const {};
      return MedicationItem.fromJson(data);
    } on DioException catch (error) {
      throw _requestError(error, 'Gagal mengambil detail rutinitas.');
    }
  }

  Future<void> updateMedication({
    required String medicationId,
    required String form,
    required String color,
    required num singleDose,
    required String singleDoseUnit,
    required String startDate,
    required String frequency,
    int? numOfDays,
    required List<int> daysOfWeek,
    required List<String> intakeTimes,
    String? note,
  }) async {
    final token = await _readBearerToken();
    final userId = await _readUserId();
    final normalizedFrequency = frequency.toLowerCase();

    final payload = <String, dynamic>{
      'form': form,
      'color': color,
      'singleDose': singleDose,
      'singleDoseUnit': singleDoseUnit,
      'startDate': startDate,
      'frequency': normalizedFrequency,
      if (normalizedFrequency == 'daily') ...{
        if (numOfDays != null) 'numOfDays': numOfDays,
      },
      if (normalizedFrequency == 'weekly') ...{
        if (daysOfWeek.isNotEmpty) 'daysOfWeek': daysOfWeek,
      },
      'intakeTimes': intakeTimes,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    };

    final response = await _dio.patch<Map<String, dynamic>>(
      '/users/$userId/medications/$medicationId',
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
        (body?['message'] ?? 'Gagal memperbarui rutinitas').toString(),
      );
    }
  }

  Future<void> deleteMedication(String medicationId) async {
    final token = await _readBearerToken();
    final userId = await _readUserId();

    final response = await _dio.delete<Map<String, dynamic>>(
      '/users/$userId/medications/$medicationId',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final body = response.data;
    if (body == null || body['success'] != true) {
      throw Exception(
        (body?['message'] ?? 'Gagal menghapus rutinitas').toString(),
      );
    }
  }

  Future<void> takeMedication(
    String status,
    String medicationId,
    DateTime scheduledDate,
    String scheduledTime,
  ) async {
    final token = await _readBearerToken();
    final userId = await _readUserId();
    final now = DateTime.now();

    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final payload = <String, dynamic>{
      'medicationDate': scheduledDate.toIso8601String().split('T')[0],
      'medicationTime':
          scheduledTime.isNotEmpty ? scheduledTime : '$hour:$minute',
      'status': status,
    };

    final response = await _dio.post<Map<String, dynamic>>(
      '/users/$userId/medications/$medicationId/logs',
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
        (body?['message'] ?? 'Gagal menandai rutinitas sebagai selesai')
            .toString(),
      );
    }
  }

  Future<MedicationLogResponse> fetchMedicationLogs({
    required String patientId,
    required String medicationId,
    required int page,
    required int limit,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final token = await _readBearerToken();

    if (patientId.trim().isEmpty) {
      throw Exception('patientId tidak ditemukan. Silakan login ulang.');
    }

    if (medicationId.trim().isEmpty) {
      throw Exception('medicationId tidak ditemukan. Silakan login ulang.');
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/users/$patientId/medications/$medicationId/logs',
        queryParameters: {
          'page': page,
          'limit': limit,
          'startDate': _formatDate(startDate),
          'endDate': _formatDate(endDate),
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = response.data;
      if (body == null) {
        throw Exception('Respons log rutinitas tidak valid dari server');
      }

      if (body['success'] != true) {
        throw Exception(
          (body['message'] ?? 'Gagal mengambil log rutinitas').toString(),
        );
      }

      final data = (body['data'] as Map<String, dynamic>?) ?? const {};
      return MedicationLogResponse.fromJson(data);
    } on DioException catch (error) {
      throw _requestError(error, 'Gagal mengambil log rutinitas.');
    }
  }

  Future<MedicationCalendarResponse> fetchMedicationCalendar({
    required DateTime from,
    required DateTime to,
  }) async {
    final token = await _readBearerToken();
    final userId = await _readUserId();

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/users/$userId/medications/calendar',
        queryParameters: {
          'from': _formatDate(from),
          'to': _formatDate(to),
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = response.data;
      if (body == null) {
        throw Exception('Respons kalender rutinitas tidak valid dari server');
      }

      if (body['success'] != true) {
        throw Exception(
          (body['message'] ?? 'Gagal mengambil kalender rutinitas').toString(),
        );
      }

      final data = (body['data'] as Map<String, dynamic>?) ?? const {};
      return MedicationCalendarResponse.fromJson(data);
    } on DioException catch (error) {
      throw _requestError(error, 'Gagal mengambil kalender rutinitas.');
    }
  }
}
