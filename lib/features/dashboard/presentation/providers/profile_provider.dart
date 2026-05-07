import 'dart:convert';
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

class MlRecommendationLifestyle {
  final String variable;
  final String codeValue;
  final String comparison;
  final String description;
  final String changeStatus;
  final dynamic currentValue;
  final String recommendedValueInterval;

  MlRecommendationLifestyle({
    required this.variable,
    required this.codeValue,
    required this.comparison,
    required this.description,
    required this.changeStatus,
    required this.currentValue,
    required this.recommendedValueInterval,
  });

  factory MlRecommendationLifestyle.fromJson(Map<String, dynamic> json) {
    return MlRecommendationLifestyle(
      variable: json['variable']?.toString() ?? '',
      codeValue: json['codeValue']?.toString() ?? '',
      comparison: json['comparison']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      changeStatus: json['changeStatus']?.toString() ?? '',
      currentValue: json['currentValue'],
      recommendedValueInterval:
          json['recommendedValueInterval']?.toString() ?? '',
    );
  }
}

class MlRecommendationResult {
  final List<MlRecommendationLifestyle> lifestyle;
  final String timeTaken;
  final double currentRisk;
  final double riskReduction;
  final String timeGenerated;
  final double currentRiskThresh;
  final double riskReductionThresh;
  final double riskAfterRecommendation;
  final double riskAfterRecommendationThresh;

  MlRecommendationResult({
    required this.lifestyle,
    required this.timeTaken,
    required this.currentRisk,
    required this.riskReduction,
    required this.timeGenerated,
    required this.currentRiskThresh,
    required this.riskReductionThresh,
    required this.riskAfterRecommendation,
    required this.riskAfterRecommendationThresh,
  });

  factory MlRecommendationResult.fromJson(Map<String, dynamic> json) {
    var lifestyleList = <MlRecommendationLifestyle>[];
    if (json['lifestyle'] != null) {
      for (var item in json['lifestyle']) {
        if (item is Map<String, dynamic>) {
          lifestyleList.add(MlRecommendationLifestyle.fromJson(item));
        }
      }
    }
    return MlRecommendationResult(
      lifestyle: lifestyleList,
      timeTaken: json['timeTaken']?.toString() ?? '',
      currentRisk:
          double.tryParse(json['currentRisk']?.toString() ?? '0') ?? 0.0,
      riskReduction:
          double.tryParse(json['riskReduction']?.toString() ?? '0') ?? 0.0,
      timeGenerated: json['timeGenerated']?.toString() ?? '',
      currentRiskThresh:
          double.tryParse(json['currentRiskThresh']?.toString() ?? '0') ?? 0.0,
      riskReductionThresh:
          double.tryParse(json['riskReductionThresh']?.toString() ?? '0') ??
              0.0,
      riskAfterRecommendation:
          double.tryParse(json['riskAfterRecommendation']?.toString() ?? '0') ??
              0.0,
      riskAfterRecommendationThresh: double.tryParse(
              json['riskAfterRecommendationThresh']?.toString() ?? '0') ??
          0.0,
    );
  }
}

class MlRecommendationBody {
  final int status;
  final List<double> resultHistory;
  final String statusMessage;
  final MlRecommendationResult recommendationResult;

  MlRecommendationBody({
    required this.status,
    required this.resultHistory,
    required this.statusMessage,
    required this.recommendationResult,
  });

  factory MlRecommendationBody.fromJson(Map<String, dynamic> json) {
    var hist = <double>[];
    if (json['resultHistory'] != null) {
      for (var h in json['resultHistory']) {
        hist.add(double.tryParse(h.toString()) ?? 0.0);
      }
    }
    return MlRecommendationBody(
      status: int.tryParse(json['status']?.toString() ?? '0') ?? 0,
      resultHistory: hist,
      statusMessage: json['statusMessage']?.toString() ?? '',
      recommendationResult: json['recommendationResult'] != null
          ? MlRecommendationResult.fromJson(
              Map<String, dynamic>.from(json['recommendationResult']))
          : MlRecommendationResult(
              lifestyle: [],
              timeTaken: '',
              currentRisk: 0.0,
              riskReduction: 0.0,
              timeGenerated: '',
              currentRiskThresh: 0.0,
              riskReductionThresh: 0.0,
              riskAfterRecommendation: 0.0,
              riskAfterRecommendationThresh: 0.0),
    );
  }
}

class MlRecommendationUpstream {
  final String endpoint;
  final int status;
  final MlRecommendationBody? body;

  MlRecommendationUpstream({
    required this.endpoint,
    required this.status,
    this.body,
  });

  factory MlRecommendationUpstream.fromJson(Map<String, dynamic> json) {
    MlRecommendationBody? parsedBody;
    var rawBody = json['body'];
    if (rawBody is String) {
      try {
        rawBody = jsonDecode(rawBody);
      } catch (_) {}
    }
    if (rawBody is Map<String, dynamic>) {
      parsedBody = MlRecommendationBody.fromJson(rawBody);
    }

    return MlRecommendationUpstream(
      endpoint: json['endpoint']?.toString() ?? '',
      status: int.tryParse(json['status']?.toString() ?? '0') ?? 0,
      body: parsedBody,
    );
  }
}

class MlRecommendationData {
  final String resultId;
  final String patientId;
  final String requestedByUserId;
  final String inferenceType;
  final String requestContext;
  final String mlVersion;
  final String payloadHash;
  final MlRecommendationUpstream? upstream;
  final String generatedAt;
  final String createdAt;

  MlRecommendationData({
    required this.resultId,
    required this.patientId,
    required this.requestedByUserId,
    required this.inferenceType,
    required this.requestContext,
    required this.mlVersion,
    required this.payloadHash,
    this.upstream,
    required this.generatedAt,
    required this.createdAt,
  });

  factory MlRecommendationData.fromJson(Map<String, dynamic> json) {
    return MlRecommendationData(
      resultId: json['resultId']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      requestedByUserId: json['requestedByUserId']?.toString() ?? '',
      inferenceType: json['inferenceType']?.toString() ?? '',
      requestContext: json['requestContext']?.toString() ?? '',
      mlVersion: json['mlVersion']?.toString() ?? '',
      payloadHash: json['payloadHash']?.toString() ?? '',
      upstream: json['upstream'] != null
          ? MlRecommendationUpstream.fromJson(
              Map<String, dynamic>.from(json['upstream']))
          : null,
      generatedAt: json['generatedAt']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class MlRecommendationResponse {
  final bool success;
  final String message;
  final MlRecommendationData? data;

  MlRecommendationResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory MlRecommendationResponse.fromJson(Map<String, dynamic> json) {
    return MlRecommendationResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null
          ? MlRecommendationData.fromJson(
              Map<String, dynamic>.from(json['data']))
          : null,
    );
  }
}

class MlRecommendationHistoryResponse {
  final List<MlRecommendationHistoryItem> items;
  final DiaryHistoryPagination pagination;

  const MlRecommendationHistoryResponse({
    required this.items,
    required this.pagination,
  });

  factory MlRecommendationHistoryResponse.fromJson(Map<String, dynamic> json) {
    return MlRecommendationHistoryResponse(
      items: ((json['items'] as List?) ?? const [])
          .map((e) =>
              MlRecommendationHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: DiaryHistoryPagination.fromJson(
        (json['pagination'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}

class MlRecommendationHistoryItem {
  final String resultId;
  final String inferenceType;
  final String requestContext;
  final String mlVersion;
  final String generatedAt;

  MlRecommendationHistoryItem({
    required this.resultId,
    required this.inferenceType,
    required this.requestContext,
    required this.mlVersion,
    required this.generatedAt,
  });

  factory MlRecommendationHistoryItem.fromJson(Map<String, dynamic> json) {
    return MlRecommendationHistoryItem(
      resultId: json['resultId']?.toString() ?? '',
      inferenceType: json['inferenceType']?.toString() ?? '',
      requestContext: json['requestContext']?.toString() ?? '',
      mlVersion: json['mlVersion']?.toString() ?? '',
      generatedAt: json['generatedAt']?.toString() ?? '',
    );
  }
}

class ProfileApi {
  final Dio _dio;
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'auth_user_id';

  ProfileApi(this._dio);

  static const _defaultCloudinaryUploadUrl =
      'https://api.cloudinary.com/v1_1/drvu0dpry/image/upload';

  Future<void> uploadAvatar({
    required MultipartFile file,
  }) async {
    final signature = await fetchAvatarUploadSignature(
      folder: dotenv.env['CLOUDINARY_FOLDER'] ?? 'pulsewise/avatars',
    );

    final uploadResult = await _uploadAvatarToCloudinary(
      file: file,
      signature: signature,
    );

    await saveAvatarMetadata(
      secureUrl: uploadResult.secureUrl,
      publicId: uploadResult.publicId,
      bytes: uploadResult.bytes,
      width: uploadResult.width,
      height: uploadResult.height,
      format: uploadResult.format,
      resourceType: uploadResult.resourceType,
    );
  }

  Future<AvatarUploadSignature> fetchAvatarUploadSignature({
    required String folder,
  }) async {
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
      '/users/$patientId/avatar/upload-signature',
      queryParameters: {'folder': folder},
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final body = response.data;
    if (body == null) {
      throw Exception('Respons signature upload avatar tidak valid');
    }

    if (body['success'] != true) {
      throw Exception(
        (body['message'] ?? 'Gagal mendapatkan signature upload avatar')
            .toString(),
      );
    }

    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    return AvatarUploadSignature.fromJson(data);
  }

  Future<CloudinaryUploadResult> _uploadAvatarToCloudinary({
    required MultipartFile file,
    required AvatarUploadSignature signature,
  }) async {
    final uploadUrl = signature.uploadUrl.isEmpty
        ? _defaultCloudinaryUploadUrl
        : signature.uploadUrl;

    final formData = FormData.fromMap({
      'file': file,
      'api_key': signature.apiKey,
      'timestamp': signature.timestamp,
      'folder': signature.folder,
      'signature': signature.signature,
      'transformation': signature.transformation,
      'allowed_formats': signature.allowedFormats,
    });

    final response = await _dio.post<Map<String, dynamic>>(
      uploadUrl,
      data: formData,
      options: Options(
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    final body = response.data;
    if (body == null) {
      throw Exception('Respons upload Cloudinary tidak valid');
    }

    return CloudinaryUploadResult.fromJson(body);
  }

  Future<void> saveAvatarMetadata({
    required String secureUrl,
    required String publicId,
    required int bytes,
    required int width,
    required int height,
    required String format,
    required String resourceType,
  }) async {
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

    final response = await _dio.put<Map<String, dynamic>>(
      '/users/$patientId/avatar',
      data: {
        'secureUrl': secureUrl,
        'publicId': publicId,
        'bytes': bytes,
        'width': width,
        'height': height,
        'format': format,
        'resourceType': resourceType,
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
        (body?['message'] ?? 'Gagal menyimpan avatar pengguna').toString(),
      );
    }
  }

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

    try {
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
    } on DioException catch (e) {
      // If profile not found (new account), return an empty/default profile
      if (e.response?.statusCode == 404) {
        return PatientProfile(
          patientId: patientId,
          firstName: '',
          lastName: '',
          email: '',
          address: '',
          dateOfBirth: null,
          sex: '',
          bodyHeightCm: '',
          bloodType: '',
          isSmoking: false,
          isElectricSmoking: false,
        );
      }

      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) {
          throw Exception(message);
        }
      }

      throw Exception('Gagal mengambil profil pengguna.');
    }
  }

  Future<void> updatePatientProfile({
    required String dateOfBirth,
    required String sex,
    required double heightCm,
    required bool isSmoking,
    required bool isElectricSmoking,
    required String bloodType,
    required String address,
  }) async {
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

    final response = await _dio.put<Map<String, dynamic>>(
      '/patients/$patientId/profile',
      data: {
        'dateOfBirth': dateOfBirth,
        'sex': sex,
        'heightCm': heightCm,
        'isSmoking': isSmoking,
        'isElectricSmoking': isElectricSmoking,
        'bloodType': bloodType,
        'address': address,
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
          (body?['message'] ?? 'Gagal memperbarui profil').toString());
    }
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
          (body['message'] ?? 'Gagal menyimpan kuisioner ML').toString());
    }
  }

  Future<Map<String, dynamic>> fetchMlProfile({
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
            (body['message'] ?? 'Gagal mengambil kuisioner ML').toString());
      }

      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (data is Map) {
        return data.map((key, value) => MapEntry(key.toString(), value));
      }
      return <String, dynamic>{};
    } on DioException catch (e) {
      // If profile has not been created yet, allow empty form for first fill.
      if (e.response?.statusCode == 404) {
        return <String, dynamic>{};
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

  Future<Map<String, dynamic>> fetchLatestMlAssessment() async {
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

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/patients/$patientId/ml-assessments/latest',
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
          (body['message'] ?? 'Gagal mengambil asesmen ML terbaru').toString(),
        );
      }

      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (data is Map) {
        return data.map((key, value) => MapEntry(key.toString(), value));
      }
      return <String, dynamic>{};
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return <String, dynamic>{};
      }

      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) {
          throw Exception(message);
        }
      }

      throw Exception('Gagal mengambil asesmen ML terbaru.');
    }
  }

  Future<List<Map<String, dynamic>>> fetchMlAssessments({
    String? startDate,
    String? endDate,
  }) async {
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

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/patients/$patientId/ml-assessments',
        queryParameters: {
          if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
          if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
        },
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
          (body['message'] ?? 'Gagal mengambil daftar asesmen ML').toString(),
        );
      }

      final data = body['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((item) =>
                item.map((key, value) => MapEntry(key.toString(), value)))
            .toList();
      }

      return const <Map<String, dynamic>>[];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const <Map<String, dynamic>>[];
      }

      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) {
          throw Exception(message);
        }
      }

      throw Exception('Gagal mengambil daftar asesmen ML.');
    }
  }

  Future<Map<String, dynamic>> fetchMlReadiness(String date) async {
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
      '/users/$patientId/ml-readiness',
      queryParameters: {'date': date},
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final body = response.data;
    if (body == null || body['success'] != true) {
      throw Exception(
        (body?['message'] ?? 'Gagal mengambil status ML readiness').toString(),
      );
    }

    return body['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchMlPrediction(String date) async {
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

    final response = await _dio.post<Map<String, dynamic>>(
      '/users/$patientId/ml-predictions',
      queryParameters: {'date': date, 'includePayload': 'true'},
      data: {},
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final body = response.data;
    if (body == null || body['success'] != true) {
      throw Exception(
        (body?['message'] ?? 'Gagal mengambil prediksi ML').toString(),
      );
    }

    return body['data'] as Map<String, dynamic>;
  }

  Future<MlRecommendationResponse?> fetchLatestMlRecommendation() async {
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

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/users/$patientId/ml-recommendations/latest',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = response.data;
      if (body == null || body['success'] != true) {
        throw Exception(
          (body?['message'] ?? 'Gagal mengambil rekomendasi ML terbaru')
              .toString(),
        );
      }

      return MlRecommendationResponse.fromJson(body);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw Exception('Gagal mengambil rekomendasi ML terbaru.');
    }
  }

  Future<MlRecommendationResponse> fetchMlRecommendations(String date) async {
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

    final response = await _dio.post<Map<String, dynamic>>(
      '/users/$patientId/ml-recommendations/',
      queryParameters: {'date': date, 'includePayload': 'true'},
      data: {},
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final body = response.data;
    if (body == null || body['success'] != true) {
      throw Exception(
        (body?['message'] ?? 'Gagal mengambil ML recommendations').toString(),
      );
    }

    return MlRecommendationResponse.fromJson(body);
  }

  Future<MlRecommendationHistoryResponse> fetchMlRecommendationHistory({
    int page = 1,
    int limit = 20,
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
      '/users/$userId/ml-recommendations/history',
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
      throw Exception('Respons history rekomendasi tidak valid dari server');
    }

    if (body['success'] != true) {
      throw Exception(
        (body['message'] ?? 'Gagal mengambil history rekomendasi').toString(),
      );
    }

    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    return MlRecommendationHistoryResponse.fromJson(data);
  }

  Future<MlRecommendationResponse> fetchMlRecommendationHistoryDetail(
      String resultId) async {
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
      '/users/$patientId/ml-recommendations/history/$resultId',
      // queryParameters: {'date': date, 'includePayload': 'true'},
      data: {},
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
                'Gagal mengambil ML recommendations History Detail')
            .toString(),
      );
    }

    return MlRecommendationResponse.fromJson(body);
  }

  Future<Map<String, dynamic>> submitMlAssessment({
    required Map<String, dynamic> payload,
  }) async {
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

    final response = await _dio.post<Map<String, dynamic>>(
      '/patients/$patientId/ml-assessments',
      data: payload,
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
        (body['message'] ?? 'Gagal menyimpan asesmen ML').toString(),
      );
    }

    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> updateMlAssessment({
    required String assessmentId,
    required Map<String, dynamic> payload,
  }) async {
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

    final response = await _dio.put<Map<String, dynamic>>(
      '/patients/$patientId/ml-assessments/$assessmentId',
      data: payload,
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
        (body['message'] ?? 'Gagal memperbarui asesmen ML').toString(),
      );
    }

    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> saveMlAssessment({
    String? assessmentId,
    required Map<String, dynamic> payload,
  }) async {
    if (assessmentId != null && assessmentId.trim().isNotEmpty) {
      return updateMlAssessment(assessmentId: assessmentId, payload: payload);
    }

    return submitMlAssessment(payload: payload);
  }

  Future<DiaryDetail> fetchDiaryDetail(DateTime diaryDate) async {
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

    final cleanDiaryDate = diaryDate.toIso8601String().split('T')[0];

    final response = await _dio.get<Map<String, dynamic>>(
      '/users/$patientId/diaries/by-date?date=$cleanDiaryDate',
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

  Future<Map<String, dynamic>?> fetchSleepDiaryByDate(DateTime date) async {
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
    } catch (e) {
      return null;
    }
  }

  Future<void> addDiarySleepByDate({
    required String diaryDate,
    required String sleepTime,
    required String wakeTime,
    required num sleepDurationHours,
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

    final response = await _dio.put<Map<String, dynamic>>(
      '/users/$userId/diaries/by-date/sleep',
      data: {
        'diaryDate': diaryDate,
        'sleepTime': sleepTime,
        'wakeTime': wakeTime,
        'sleepDurationHours': sleepDurationHours,
        'source': 'app_manual'
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
        // DUMMY DATA FOR ML
        'portionGrams': 150,
        'fdcFoodId': '123456',
        'nutritionSource': 'dummy',
        'energyKcal': 250,
        'proteinG': 10,
        'carbohydrateG': 30,
        'sugarG': 5,
        'fiberG': 3,
        'totalFatG': 8,
        'saturatedFatG': 2,
        'monounsaturatedFatG': 3,
        'polyunsaturatedFatG': 1,
        'cholesterolMg': 20,
        'calciumMg': 50,
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
    required String activityCategory,
    String? intensityLevel,
    String? transportMode,
    int? outdoorMinutes,
    required int duration,
    int? heartRate,
    String? userFeeling,
    String? note,
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
    int? oxygenSaturation,
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
          (body?['message'] ?? 'Gagal menyimpan metrik kesehatan').toString());
    }
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
          (body?['message'] ?? 'Gagal menambah pengingat obat').toString());
    }
  }

  Future<MedicationListResponse> fetchMedications({
    int page = 1,
    int limit = 10,
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
          (body['message'] ?? 'Gagal mengambil daftar medication').toString());
    }

    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    return MedicationListResponse.fromJson(data);
  }

  Future<MedicationItem> fetchMedicationDetail(String medicationId) async {
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
          (body['message'] ?? 'Gagal mengambil detail medication').toString());
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
          (body?['message'] ?? 'Gagal memperbarui medication').toString());
    }
  }

  Future<void> deleteMedication(String medicationId) async {
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
          (body?['message'] ?? 'Gagal menghapus medication').toString());
    }
  }

  Future<MedicationCalendarResponse> fetchMedicationCalendar({
    required DateTime from,
    required DateTime to,
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
      final y = date.year.toString().padLeft(4, '0');
      final m = date.month.toString().padLeft(2, '0');
      final d = date.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '/users/$userId/medications/calendar',
      queryParameters: {
        'from': formatDate(from),
        'to': formatDate(to),
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
      throw Exception((body['message'] ?? 'Gagal mengambil kalender medication')
          .toString());
    }

    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    return MedicationCalendarResponse.fromJson(data);
  }
}

class AuthMeUser {
  final String userId;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String avatarPhoto;
  final String role;
  final String accountStatus;
  final DateTime? emailVerifiedAt;

  const AuthMeUser({
    required this.userId,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.avatarPhoto,
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
      avatarPhoto: (json['avatarPhoto'] ?? '').toString(),
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

class MedicationListResponse {
  final List<MedicationItem> items;
  final MedicationPagination pagination;

  const MedicationListResponse({
    required this.items,
    required this.pagination,
  });

  factory MedicationListResponse.fromJson(Map<String, dynamic> json) {
    return MedicationListResponse(
      items: ((json['items'] as List?) ?? const [])
          .map((e) => MedicationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: MedicationPagination.fromJson(
        (json['pagination'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}

class MedicationItem {
  final String medicationId;
  final String userId;
  final String name;
  final String? description;
  final String? conditionTag;
  final String form;
  final String color;
  final num singleDose;
  final String singleDoseUnit;
  final DateTime? startDate;
  final String frequency;
  final int? numOfDays;
  final List<int> daysOfWeek;
  final List<String> intakeTimes;
  final String? note;
  final DateTime? createdAt;
  final List<MedicationReminder> reminders;

  const MedicationItem({
    required this.medicationId,
    required this.userId,
    required this.name,
    required this.description,
    required this.conditionTag,
    required this.form,
    required this.color,
    required this.singleDose,
    required this.singleDoseUnit,
    required this.startDate,
    required this.frequency,
    required this.numOfDays,
    required this.daysOfWeek,
    required this.intakeTimes,
    required this.note,
    required this.createdAt,
    required this.reminders,
  });

  factory MedicationItem.fromJson(Map<String, dynamic> json) {
    return MedicationItem(
      medicationId: (json['medicationId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      conditionTag: json['conditionTag']?.toString(),
      form: (json['form'] ?? '').toString(),
      color: (json['color'] ?? '').toString(),
      singleDose: (json['singleDose'] as num?) ?? 0,
      singleDoseUnit: (json['singleDoseUnit'] ?? '').toString(),
      startDate: DateTime.tryParse((json['startDate'] ?? '').toString()),
      frequency: (json['frequency'] ?? '').toString(),
      numOfDays: (json['numOfDays'] as num?)?.toInt(),
      daysOfWeek: ((json['daysOfWeek'] as List?) ?? const [])
          .map((e) => (e as num).toInt())
          .toList(),
      intakeTimes: ((json['intakeTimes'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      note: json['note']?.toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      reminders: ((json['reminders'] as List?) ?? const [])
          .map((e) => MedicationReminder.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MedicationReminder {
  final String reminderId;
  final String userId;
  final String medicationId;
  final String scheduleTime;
  final int? dayOfWeek;
  final DateTime? createdAt;

  const MedicationReminder({
    required this.reminderId,
    required this.userId,
    required this.medicationId,
    required this.scheduleTime,
    required this.dayOfWeek,
    required this.createdAt,
  });

  factory MedicationReminder.fromJson(Map<String, dynamic> json) {
    return MedicationReminder(
      reminderId: (json['reminderId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      medicationId: (json['medicationId'] ?? '').toString(),
      scheduleTime: (json['scheduleTime'] ?? '').toString(),
      dayOfWeek: (json['dayOfWeek'] as num?)?.toInt(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }
}

class MedicationPagination {
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;

  const MedicationPagination({
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
  });

  factory MedicationPagination.fromJson(Map<String, dynamic> json) {
    return MedicationPagination(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 10,
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

class MedicationCalendarResponse {
  final MedicationCalendarRange range;
  final int totalItems;
  final List<MedicationCalendarItem> items;

  const MedicationCalendarResponse({
    required this.range,
    required this.totalItems,
    required this.items,
  });

  factory MedicationCalendarResponse.fromJson(Map<String, dynamic> json) {
    return MedicationCalendarResponse(
      range: MedicationCalendarRange.fromJson(
        (json['range'] as Map<String, dynamic>?) ?? const {},
      ),
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      items: ((json['items'] as List?) ?? const [])
          .map(
              (e) => MedicationCalendarItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MedicationCalendarRange {
  final DateTime? from;
  final DateTime? to;

  const MedicationCalendarRange({
    required this.from,
    required this.to,
  });

  factory MedicationCalendarRange.fromJson(Map<String, dynamic> json) {
    return MedicationCalendarRange(
      from: DateTime.tryParse((json['from'] ?? '').toString()),
      to: DateTime.tryParse((json['to'] ?? '').toString()),
    );
  }
}

class MedicationCalendarItem {
  final String eventId;
  final DateTime? scheduledDate;
  final String scheduledTime;
  final String reminderId;
  final String medicationId;
  final String? medicationLogId;
  final String name;
  final String color;
  final num singleDose;
  final String singleDoseUnit;
  final String? status;

  const MedicationCalendarItem({
    required this.eventId,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.reminderId,
    required this.medicationId,
    required this.medicationLogId,
    required this.name,
    required this.color,
    required this.singleDose,
    required this.singleDoseUnit,
    required this.status,
  });

  factory MedicationCalendarItem.fromJson(Map<String, dynamic> json) {
    return MedicationCalendarItem(
      eventId: (json['eventId'] ?? '').toString(),
      scheduledDate:
          DateTime.tryParse((json['scheduledDate'] ?? '').toString()),
      scheduledTime: (json['scheduledTime'] ?? '').toString(),
      reminderId: (json['reminderId'] ?? '').toString(),
      medicationId: (json['medicationId'] ?? '').toString(),
      medicationLogId: json['medicationLogId']?.toString(),
      name: (json['name'] ?? '').toString(),
      color: (json['color'] ?? '').toString(),
      singleDose: (json['singleDose'] as num?) ?? 0,
      singleDoseUnit: (json['singleDoseUnit'] ?? '').toString(),
      status: json['status']?.toString(),
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
  final bool isSmoking;
  final bool isElectricSmoking;

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
    required this.isSmoking,
    required this.isElectricSmoking,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
        patientId: (json['patient_id'] ?? '').toString(),
        firstName: (json['first_name'] ?? '').toString(),
        lastName: (json['last_name'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        address: (json['address'] ?? '').toString(),
        dateOfBirth:
            DateTime.tryParse((json['date_of_birth'] ?? '').toString()),
        sex: (json['sex'] ?? '').toString(),
        bodyHeightCm: (json['body_height_cm'] ?? '').toString(),
        bloodType: (json['blood_type'] ?? '').toString(),
        isSmoking: (json['is_smoking'] as bool?) ?? false,
        isElectricSmoking: (json['is_electric_smoking'] as bool?) ?? false);
  }
}

class AvatarUploadSignature {
  final String uploadUrl;
  final String apiKey;
  final int timestamp;
  final String folder;
  final String signature;
  final String transformation;
  final String allowedFormats;

  const AvatarUploadSignature({
    required this.uploadUrl,
    required this.apiKey,
    required this.timestamp,
    required this.folder,
    required this.signature,
    required this.transformation,
    required this.allowedFormats,
  });

  factory AvatarUploadSignature.fromJson(Map<String, dynamic> json) {
    return AvatarUploadSignature(
      uploadUrl: (json['uploadUrl'] ?? json['url'] ?? '').toString(),
      apiKey: (json['api_key'] ?? json['apiKey'] ?? '').toString(),
      timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
      folder: (json['folder'] ?? '').toString(),
      signature: (json['signature'] ?? '').toString(),
      transformation:
          (json['transformation'] ?? 'c_limit,h_512,w_512,q_auto:good')
              .toString(),
      allowedFormats: (json['allowed_formats'] ??
              json['allowedFormats'] ??
              'jpg,jpeg,png,webp')
          .toString(),
    );
  }
}

class CloudinaryUploadResult {
  final String secureUrl;
  final String publicId;
  final int bytes;
  final int width;
  final int height;
  final String format;
  final String resourceType;

  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
    required this.bytes,
    required this.width,
    required this.height,
    required this.format,
    required this.resourceType,
  });

  factory CloudinaryUploadResult.fromJson(Map<String, dynamic> json) {
    return CloudinaryUploadResult(
      secureUrl: (json['secure_url'] ?? '').toString(),
      publicId: (json['public_id'] ?? '').toString(),
      bytes: (json['bytes'] as num?)?.toInt() ?? 0,
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      format: (json['format'] ?? '').toString(),
      resourceType: (json['resource_type'] ?? '').toString(),
    );
  }
}
