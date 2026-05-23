import 'package:dio/dio.dart';
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
        (body?['message'] ?? 'Gagal menambah pengingat obat').toString(),
      );
    }
  }

  Future<MedicationListResponse> fetchMedications({
    int page = 1,
    int limit = 10,
  }) async {
    final token = await _readBearerToken();
    final userId = await _readUserId();

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
      throw Exception('Respons daftar medication tidak valid dari server');
    }

    if (body['success'] != true) {
      throw Exception(
        (body['message'] ?? 'Gagal mengambil daftar medication').toString(),
      );
    }

    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    return MedicationListResponse.fromJson(data);
  }

  Future<MedicationItem> fetchMedicationDetail(String medicationId) async {
    final token = await _readBearerToken();
    final userId = await _readUserId();

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
      throw Exception('Respons detail medication tidak valid dari server');
    }

    if (body['success'] != true) {
      throw Exception(
        (body['message'] ?? 'Gagal mengambil detail medication').toString(),
      );
    }

    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    return MedicationItem.fromJson(data);
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
        (body?['message'] ?? 'Gagal memperbarui medication').toString(),
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
        (body?['message'] ?? 'Gagal menghapus medication').toString(),
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
        (body?['message'] ??
                'Gagal menandai medication sebagai sudah diminum')
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
      throw Exception('Respons medication logs tidak valid dari server');
    }

    if (body['success'] != true) {
      throw Exception(
        (body['message'] ?? 'Gagal mengambil medication logs').toString(),
      );
    }

    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    return MedicationLogResponse.fromJson(data);
  }

  Future<MedicationCalendarResponse> fetchMedicationCalendar({
    required DateTime from,
    required DateTime to,
  }) async {
    final token = await _readBearerToken();
    final userId = await _readUserId();

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
      throw Exception('Respons kalender medication tidak valid dari server');
    }

    if (body['success'] != true) {
      throw Exception(
        (body['message'] ?? 'Gagal mengambil kalender medication').toString(),
      );
    }

    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    return MedicationCalendarResponse.fromJson(data);
  }
}
