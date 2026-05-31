import 'package:dio/dio.dart';
import 'package:pulsewise/core/network/network_error_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/diary/data/models/diary_models.dart';

final diaryApiProvider = Provider<DiaryApi>((ref) {
  return DiaryApi(ref.watch(apiDioProvider));
});

class DiaryApi {
  final Dio _dio;

  DiaryApi(this._dio);

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

  Future<DiaryDetail> fetchDiaryDetail(DateTime diaryDate) async {
    final patientId = await _readPatientId();
    return fetchDiaryDetailForUser(patientId, diaryDate);
  }

  Future<DiaryDetail?> fetchDiaryDetailByDate(DateTime date) async {
    final token = await _readBearerToken();
    final userId = await _readUserId();
    final dateParam =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/users/$userId/diaries/by-date',
        queryParameters: {
          'date': dateParam,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = response.data;
      if (body == null) {
        throw Exception('Respons detail diary berdasarkan tanggal tidak valid');
      }

      if (body['success'] != true) {
        throw Exception(
          (body['message'] ??
                  'Gagal mengambil detail diary berdasarkan tanggal')
              .toString(),
        );
      }

      if (body['data'] == null) {
        return null;
      }

      return DiaryDetail.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }

      throw _requestError(
        error,
        'Gagal mengambil detail diary berdasarkan tanggal.',
      );
    }
  }

  Future<DiaryDetail> fetchDiaryDetailForUser(
    String userId,
    DateTime diaryDate,
  ) async {
    final token = await _readBearerToken();
    final cleanDiaryDate = diaryDate.toIso8601String().split('T')[0];

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/users/$userId/diaries/by-date',
        queryParameters: {
          'date': cleanDiaryDate,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = response.data;
      if (body == null || body['data'] == null) {
        throw Exception('Respons detail diary tidak valid dari server');
      }

      return DiaryDetail.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw _requestError(error, 'Gagal mengambil detail diary.');
    }
  }

  Future<DiaryHistoryResponse> fetchDiaryHistory({
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final userId = await _readUserId();
    return fetchDiaryHistoryForUser(
      userId,
      page: page,
      limit: limit,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<DiaryHistoryResponse> fetchDiaryHistoryForUser(
    String userId, {
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final token = await _readBearerToken();

    String formatDate(DateTime date) {
      return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/users/$userId/diaries',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (startDate != null) 'startDate': formatDate(startDate),
          if (endDate != null) 'endDate': formatDate(endDate),
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = response.data;
      if (body == null) {
        throw Exception('Respons riwayat diary tidak valid dari server');
      }

      if (body['success'] != true) {
        throw Exception(
          (body['message'] ?? 'Gagal mengambil riwayat diary').toString(),
        );
      }

      final data = (body['data'] as Map<String, dynamic>?) ?? const {};
      return DiaryHistoryResponse.fromJson(data);
    } on DioException catch (error) {
      throw _requestError(error, 'Gagal mengambil riwayat diary.');
    }
  }

  Future<Map<String, dynamic>?> fetchSleepDiaryByDate(DateTime date) async {
    final userId = await _readUserId();
    return fetchSleepDiaryByDateForUser(userId, date);
  }

  Future<Map<String, dynamic>?> fetchSleepDiaryByDateForUser(
    String userId,
    DateTime date,
  ) async {
    final token = await _readBearerToken();
    final dateParam =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/users/$userId/diaries/by-date/sleep',
        queryParameters: {
          'date': dateParam,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = response.data;
      if (body != null && body['success'] == true && body['data'] != null) {
        return body['data'] as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }

      throw _requestError(error, 'Gagal mengambil data tidur.');
    } catch (_) {
      return null;
    }
  }

  Future<void> addDiarySleepByDate({
    required String diaryDate,
    required String sleepTime,
    required String wakeTime,
    required num sleepDurationHours,
  }) async {
    final token = await _readBearerToken();
    final userId = await _readUserId();

    final response = await _dio.put<Map<String, dynamic>>(
      '/users/$userId/diaries/by-date/sleep',
      data: {
        'diaryDate': diaryDate,
        'sleepTime': sleepTime,
        'wakeTime': wakeTime,
        'sleepDurationHours': sleepDurationHours,
        'source': 'app_manual',
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
        (body?['message'] ?? 'Gagal menyimpan data tidur').toString(),
      );
    }
  }

  Future<void> addDiarySymptomByDate({
    required String diaryDate,
    required String symptomName,
    required String symptomCode,
    required String bodyArea,
    required bool isChestPain,
    int? painFrequencyCode,
    int? painLocationCode,
    required int intensity,
    required String time,
    required String note,
  }) async {
    final token = await _readBearerToken();
    final userId = await _readUserId();

    final response = await _dio.post<Map<String, dynamic>>(
      '/users/$userId/diaries/by-date/symptoms',
      data: {
        'diaryDate': diaryDate,
        'symptomName': symptomName,
        'symptomCode': symptomCode,
        'bodyArea': bodyArea,
        'isChestPain': isChestPain,
        'painFrequencyCode': painFrequencyCode,
        'painLocationCode': painLocationCode,
        'intensity': intensity,
        'time': time,
        'note': note,
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
          (body?['message'] ?? 'Gagal menyimpan gejala').toString());
    }
  }

  Future<void> addDiaryConsumptionByDate({
    required String diaryDate,
    required String type,
    required String name,
    required String portion,
    required String time,
    required String note,
    Map<String, dynamic>? nutritionPayload,
  }) async {
    final token = await _readBearerToken();
    final userId = await _readUserId();
    final requestBody = <String, dynamic>{
      'diaryDate': diaryDate,
      'type': type,
      'name': name,
      'portion': portion,
      'time': time,
      'note': note,
    };
    if (nutritionPayload != null) {
      for (final entry in nutritionPayload.entries) {
        final value = entry.value;
        if (value == null) continue;
        if (value is String && value.trim().isEmpty) continue;
        requestBody[entry.key] = value;
      }
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '/users/$userId/diaries/by-date/consumptions',
      data: requestBody,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final body = response.data;
    if (body == null || body['success'] != true) {
      throw Exception(
        (body?['message'] ?? 'Gagal menyimpan konsumsi harian').toString(),
      );
    }
  }

  Future<void> addDiaryActivityByDate({
    required String diaryDate,
    required String name,
    required String activityCategory,
    String? intensityLevel,
    String? transportMode,
    int? outdoorMinutes,
    required int duration,
    int? heartRate,
    String? userFeeling,
    String? note,
  }) async {
    final token = await _readBearerToken();
    final userId = await _readUserId();

    final response = await _dio.post<Map<String, dynamic>>(
      '/users/$userId/diaries/by-date/activities',
      data: {
        'diaryDate': diaryDate,
        'name': name,
        'activityCategory': activityCategory,
        if (intensityLevel != null) 'intensityLevel': intensityLevel,
        if (transportMode != null) 'transportMode': transportMode,
        if (outdoorMinutes != null) 'outdoorMinutes': outdoorMinutes,
        'duration': duration,
        if (heartRate != null) 'heartRate': heartRate,
        if (userFeeling != null) 'userFeeling': userFeeling,
        if (note != null) 'note': note,
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
        (body?['message'] ?? 'Gagal menyimpan aktivitas').toString(),
      );
    }
  }

  Future<void> updateDiaryBodyMetricsByDate({
    required String diaryDate,
    required String conditionTag,
    required String timeStamp,
    double? bodyHeight,
    double? bodyWeight,
    double? bmi,
    int? systolicPressure,
    int? diastolicPressure,
    int? heartRate,
    int? oxygenSaturation,
  }) async {
    final token = await _readBearerToken();
    final userId = await _readUserId();
    final data = <String, dynamic>{
      'diaryDate': diaryDate,
      'conditionTag': conditionTag,
      'timeStamp': timeStamp,
    };
    if (bodyHeight != null) data['bodyHeight'] = bodyHeight;
    if (bodyWeight != null) data['bodyWeight'] = bodyWeight;
    if (bmi != null) data['bmi'] = bmi;
    if (systolicPressure != null) data['systolicPressure'] = systolicPressure;
    if (diastolicPressure != null) {
      data['diastolicPressure'] = diastolicPressure;
    }
    if (heartRate != null) data['heartRate'] = heartRate;
    if (oxygenSaturation != null) data['oxygenSaturation'] = oxygenSaturation;

    final response = await _dio.put<Map<String, dynamic>>(
      '/users/$userId/diaries/by-date/body-metrics',
      data: data,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final body = response.data;
    if (body == null || body['success'] != true) {
      throw Exception(
        (body?['message'] ?? 'Gagal menyimpan metrik kesehatan').toString(),
      );
    }
  }
}
