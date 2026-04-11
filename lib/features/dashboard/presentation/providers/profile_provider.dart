import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final dioProvider = Provider<Dio>((ref) {
  final baseUrl = dotenv.env['API_BASE_URL'] ??
      'https://pulsewise-backend.vercel.app/api/v1';

  return Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {
        'Accept': 'application/json',
      },
    ),
  );
});

final profileApiProvider = Provider<ProfileApi>((ref) {
  return ProfileApi(ref.watch(dioProvider));
});

final patientProfileProvider = FutureProvider<PatientProfile>((ref) async {
  final api = ref.watch(profileApiProvider);
  return api.fetchProfile();
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
