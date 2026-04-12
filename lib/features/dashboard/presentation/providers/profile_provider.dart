import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/network/api_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'current_diary_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  final baseUrl = dotenv.env['API_BASE_URL'] ??
      'https://pulsewise-backend.vercel.app/api/v1';

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {
        'Accept': 'application/json',
      },
    ),
  );

  ApiLogger.attach(dio);
  return dio;
});

final profileApiProvider = Provider<ProfileApi>((ref) {
  return ProfileApi(ref.watch(dioProvider));
});

final patientProfileProvider = FutureProvider<PatientProfile>((ref) async {
  final api = ref.watch(profileApiProvider);
  return api.fetchProfile();
});

final authMeProvider = FutureProvider<AuthMeUser>((ref) async {
  final api = ref.watch(profileApiProvider);
  return api.fetchAuthMe();
});

class ProfileApi {
  final Dio _dio;
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'auth_user_id';

  ProfileApi(this._dio);

  Future<PatientProfile> fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey) ??
        dotenv.env['AUTH_TOKEN'] ??
        dotenv.env['BEARER_TOKEN'] ??
        '';
    if (token.isEmpty) {
      throw Exception(
          'Bearer token tidak ditemukan. Isi AUTH_TOKEN di file .env');
    }

    final patientId =
        prefs.getString(_userIdKey) ?? dotenv.env['PATIENT_ID'] ?? '';
    if (patientId.isEmpty) {
      throw Exception(
          'patientId tidak ditemukan. Login ulang untuk menyimpan userId.');
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '/patients/$patientId/profile',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final body = response.data;
    if (body == null || body['data'] == null) {
      throw Exception('Respons profil tidak valid dari server');
    }

    return PatientProfile.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<AuthMeUser> fetchAuthMe() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey) ??
        dotenv.env['AUTH_TOKEN'] ??
        dotenv.env['BEARER_TOKEN'] ??
        '';
    if (token.isEmpty) {
      throw Exception('Bearer token tidak ditemukan. Silakan login ulang.');
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '/auth/me',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final body = response.data;
    if (body == null || body['data'] == null) {
      throw Exception('Respons auth me tidak valid dari server');
    }

    return AuthMeUser.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<DiaryDetail> fetchDiaryDetail(String diaryId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey) ??
        dotenv.env['AUTH_TOKEN'] ??
        dotenv.env['BEARER_TOKEN'] ??
        '';
    if (token.isEmpty) {
      throw Exception('Bearer token tidak ditemukan. Silakan login ulang.');
    }

    final patientId =
        prefs.getString(_userIdKey) ?? dotenv.env['PATIENT_ID'] ?? '';
    if (patientId.isEmpty) {
      throw Exception('patientId tidak ditemukan. Silakan login ulang.');
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '/users/$patientId/diaries/$diaryId',
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
  }

  Future<DiaryDetail?> fetchDiaryDetailByDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey) ??
        dotenv.env['AUTH_TOKEN'] ??
        dotenv.env['BEARER_TOKEN'] ??
        '';
    if (token.isEmpty) {
      throw Exception('Bearer token tidak ditemukan. Silakan login ulang.');
    }

    final userId =
        prefs.getString(_userIdKey) ?? dotenv.env['PATIENT_ID'] ?? '';
    if (userId.isEmpty) {
      throw Exception('userId tidak ditemukan. Silakan login ulang.');
    }

    final dateParam =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

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
        (body['message'] ?? 'Gagal mengambil detail diary berdasarkan tanggal')
            .toString(),
      );
    }

    if (body['data'] == null) {
      return null;
    }

    return DiaryDetail.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<DiaryHistoryResponse> fetchDiaryHistory({
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey) ??
        dotenv.env['AUTH_TOKEN'] ??
        dotenv.env['BEARER_TOKEN'] ??
        '';
    if (token.isEmpty) {
      throw Exception('Bearer token tidak ditemukan. Silakan login ulang.');
    }

    final userId =
        prefs.getString(_userIdKey) ?? dotenv.env['PATIENT_ID'] ?? '';
    if (userId.isEmpty) {
      throw Exception('userId tidak ditemukan. Silakan login ulang.');
    }

    String formatDate(DateTime date) {
      return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }

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
  }

  Future<void> addDiarySymptomByDate({
    required String diaryDate,
    required String symptomName,
    required int intensity,
    required String time,
    required String note,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey) ??
        dotenv.env['AUTH_TOKEN'] ??
        dotenv.env['BEARER_TOKEN'] ??
        '';
    if (token.isEmpty) {
      throw Exception('Bearer token tidak ditemukan. Silakan login ulang.');
    }

    final userId =
        prefs.getString(_userIdKey) ?? dotenv.env['PATIENT_ID'] ?? '';
    if (userId.isEmpty) {
      throw Exception('userId tidak ditemukan. Silakan login ulang.');
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '/users/$userId/diaries/by-date/symptoms',
      data: {
        'diaryDate': diaryDate,
        'symptomName': symptomName,
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
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey) ??
        dotenv.env['AUTH_TOKEN'] ??
        dotenv.env['BEARER_TOKEN'] ??
        '';
    if (token.isEmpty) {
      throw Exception('Bearer token tidak ditemukan. Silakan login ulang.');
    }

    final userId =
        prefs.getString(_userIdKey) ?? dotenv.env['PATIENT_ID'] ?? '';
    if (userId.isEmpty) {
      throw Exception('userId tidak ditemukan. Silakan login ulang.');
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '/users/$userId/diaries/by-date/consumptions',
      data: {
        'diaryDate': diaryDate,
        'type': type,
        'name': name,
        'portion': portion,
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
          (body?['message'] ?? 'Gagal menyimpan konsumsi harian').toString());
    }
  }

  Future<void> addDiaryActivityByDate({
    required String diaryDate,
    required String name,
    required int duration,
    required int heartRate,
    required String userFeeling,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey) ??
        dotenv.env['AUTH_TOKEN'] ??
        dotenv.env['BEARER_TOKEN'] ??
        '';
    if (token.isEmpty) {
      throw Exception('Bearer token tidak ditemukan. Silakan login ulang.');
    }

    final userId =
        prefs.getString(_userIdKey) ?? dotenv.env['PATIENT_ID'] ?? '';
    if (userId.isEmpty) {
      throw Exception('userId tidak ditemukan. Silakan login ulang.');
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '/users/$userId/diaries/by-date/activities',
      data: {
        'diaryDate': diaryDate,
        'name': name,
        'duration': duration,
        'heartRate': heartRate,
        'userFeeling': userFeeling,
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
          (body?['message'] ?? 'Gagal menyimpan aktivitas').toString());
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
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey) ??
        dotenv.env['AUTH_TOKEN'] ??
        dotenv.env['BEARER_TOKEN'] ??
        '';
    if (token.isEmpty) {
      throw Exception('Bearer token tidak ditemukan. Silakan login ulang.');
    }

    final userId =
        prefs.getString(_userIdKey) ?? dotenv.env['PATIENT_ID'] ?? '';
    if (userId.isEmpty) {
      throw Exception('userId tidak ditemukan. Silakan login ulang.');
    }

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
          (body?['message'] ?? 'Gagal menyimpan metrik kesehatan').toString());
    }
  }
}

class AuthMeUser {
  final String userId;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String accountStatus;
  final DateTime? emailVerifiedAt;

  const AuthMeUser({
    required this.userId,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.accountStatus,
    required this.emailVerifiedAt,
  });

  factory AuthMeUser.fromJson(Map<String, dynamic> json) {
    return AuthMeUser(
      userId: (json['userId'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      accountStatus: (json['accountStatus'] ?? '').toString(),
      emailVerifiedAt:
          DateTime.tryParse((json['emailVerifiedAt'] ?? '').toString()),
    );
  }
}

class DiaryHistoryResponse {
  final List<DiaryHistoryItem> items;
  final DiaryHistoryPagination pagination;

  const DiaryHistoryResponse({
    required this.items,
    required this.pagination,
  });

  factory DiaryHistoryResponse.fromJson(Map<String, dynamic> json) {
    return DiaryHistoryResponse(
      items: ((json['items'] as List?) ?? const [])
          .map((e) => DiaryHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: DiaryHistoryPagination.fromJson(
        (json['pagination'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}

class DiaryHistoryItem {
  final String diaryId;
  final String userId;
  final DateTime? diaryDate;
  final DateTime? createdAt;

  const DiaryHistoryItem({
    required this.diaryId,
    required this.userId,
    required this.diaryDate,
    required this.createdAt,
  });

  factory DiaryHistoryItem.fromJson(Map<String, dynamic> json) {
    return DiaryHistoryItem(
      diaryId: (json['diaryId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      diaryDate: DateTime.tryParse((json['diaryDate'] ?? '').toString()),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }
}

class DiaryHistoryPagination {
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;

  const DiaryHistoryPagination({
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
  });

  factory DiaryHistoryPagination.fromJson(Map<String, dynamic> json) {
    return DiaryHistoryPagination(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

class PatientProfile {
  final String patientId;
  final String firstName;
  final String lastName;
  final String email;
  final String address;
  final DateTime? dateOfBirth;
  final String sex;
  final String bodyHeightCm;
  final String bloodType;

  const PatientProfile({
    required this.patientId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.address,
    required this.dateOfBirth,
    required this.sex,
    required this.bodyHeightCm,
    required this.bloodType,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      patientId: (json['patient_id'] ?? '').toString(),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      dateOfBirth: DateTime.tryParse((json['date_of_birth'] ?? '').toString()),
      sex: (json['sex'] ?? '').toString(),
      bodyHeightCm: (json['body_height_cm'] ?? '').toString(),
      bloodType: (json['blood_type'] ?? '').toString(),
    );
  }
}
