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

  Future<DiaryDetail> fetchDiaryDetailByDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey) ??
        dotenv.env['AUTH_TOKEN'] ??
        dotenv.env['BEARER_TOKEN'] ??
        '';
    if (token.isEmpty) {
      throw Exception('Bearer token tidak ditemukan. Silakan login ulang.');
    }

    final userId = prefs.getString(_userIdKey) ?? dotenv.env['PATIENT_ID'] ?? '';
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
    if (body == null || body['data'] == null) {
      throw Exception('Respons detail diary berdasarkan tanggal tidak valid');
    }

    return DiaryDetail.fromJson(body['data'] as Map<String, dynamic>);
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
