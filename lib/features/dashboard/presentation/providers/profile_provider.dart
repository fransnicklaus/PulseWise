import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/diary/data/models/diary_models.dart';

final profileApiProvider = Provider<ProfileApi>((ref) {
  return ProfileApi(ref.watch(apiDioProvider));
});

final dashboardVitalsProvider =
    FutureProvider.family<DashboardVitalsResponse, String>(
        (ref, timePeriod) async {
  final api = ref.watch(profileApiProvider);
  return api.fetchDashboardVitals(timePeriod);
});

final quickDashboardProvider =
    FutureProvider<QuickDashboardResponse?>((ref) async {
  final api = ref.watch(profileApiProvider);
  return api.fetchQuickDashboard();
});

final dashboardTimePeriodProvider =
    StateProvider<String>((ref) => 'last_30_days');

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

class DashboardVitalsResponse {
  final bool success;
  final String message;
  final DashboardVitalsData? data;

  DashboardVitalsResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory DashboardVitalsResponse.fromJson(Map<String, dynamic> json) {
    return DashboardVitalsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? DashboardVitalsData.fromJson(json['data'])
          : null,
    );
  }
}

class DashboardVitalsData {
  final DashboardPatient patient;
  final DashboardPeriod period;
  final DashboardSeries series;
  final DashboardLatestVitals? latestVitals;

  DashboardVitalsData({
    required this.patient,
    required this.period,
    required this.series,
    this.latestVitals,
  });

  factory DashboardVitalsData.fromJson(Map<String, dynamic> json) {
    return DashboardVitalsData(
      patient: DashboardPatient.fromJson(json['patient']),
      period: DashboardPeriod.fromJson(json['period']),
      series: DashboardSeries.fromJson(json['series']),
      latestVitals: json['latestVitals'] != null
          ? DashboardLatestVitals.fromJson(json['latestVitals'])
          : null,
    );
  }
}

class DashboardPatient {
  final String patientId;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? dateOfBirth;
  final int? age;
  final String? sex;

  DashboardPatient({
    required this.patientId,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.dateOfBirth,
    this.age,
    this.sex,
  });

  factory DashboardPatient.fromJson(Map<String, dynamic> json) {
    return DashboardPatient(
      patientId: json['patientId'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'],
      phone: json['phone'],
      dateOfBirth: json['dateOfBirth'],
      age: json['age'],
      sex: json['sex'],
    );
  }
}

class DashboardPeriod {
  final String startAt;
  final String endAt;
  final String timePeriod;

  DashboardPeriod({
    required this.startAt,
    required this.endAt,
    required this.timePeriod,
  });

  factory DashboardPeriod.fromJson(Map<String, dynamic> json) {
    return DashboardPeriod(
      startAt: json['startAt'] ?? '',
      endAt: json['endAt'] ?? '',
      timePeriod: json['timePeriod'] ?? '',
    );
  }
}

class DashboardSeries {
  final List<String> timestamps;
  final List<num?> systolicBp;
  final List<num?> diastolicBp;
  final List<num?> heartRate;
  final List<num?> oxygenSaturation;
  final List<num?> weight;
  final List<num?> height;
  final List<num?> bmi;

  DashboardSeries({
    required this.timestamps,
    required this.systolicBp,
    required this.diastolicBp,
    required this.heartRate,
    required this.oxygenSaturation,
    required this.weight,
    required this.height,
    required this.bmi,
  });

  factory DashboardSeries.fromJson(Map<String, dynamic> json) {
    List<num?> parseList(String key) {
      if (json[key] == null) return [];
      return (json[key] as List).map((e) => e as num?).toList();
    }

    return DashboardSeries(
      timestamps:
          (json['timestamps'] as List?)?.map((e) => e as String).toList() ?? [],
      systolicBp: parseList('systolicBp'),
      diastolicBp: parseList('diastolicBp'),
      heartRate: parseList('heartRate'),
      oxygenSaturation: parseList('oxygenSaturation'),
      weight: parseList('weight'),
      height: parseList('height'),
      bmi: parseList('bmi'),
    );
  }
}

class DashboardLatestVitals {
  final String? measuredAt;
  final num? systolicBp;
  final num? diastolicBp;
  final num? heartRate;
  final num? oxygenSaturation;
  final num? weight;
  final num? height;
  final num? bmi;

  DashboardLatestVitals({
    this.measuredAt,
    this.systolicBp,
    this.diastolicBp,
    this.heartRate,
    this.oxygenSaturation,
    this.weight,
    this.height,
    this.bmi,
  });

  factory DashboardLatestVitals.fromJson(Map<String, dynamic> json) {
    return DashboardLatestVitals(
      measuredAt: json['measuredAt'],
      systolicBp: json['systolicBp'] as num?,
      diastolicBp: json['diastolicBp'] as num?,
      heartRate: json['heartRate'] as num?,
      oxygenSaturation: json['oxygenSaturation'] as num?,
      weight: json['weight'] as num?,
      height: json['height'] as num?,
      bmi: json['bmi'] as num?,
    );
  }
}

class QuickDashboardResponse {
  final bool success;
  final String message;
  final QuickDashboardData? data;

  QuickDashboardResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory QuickDashboardResponse.fromJson(Map<String, dynamic> json) {
    return QuickDashboardResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? QuickDashboardData.fromJson(json['data'])
          : null,
    );
  }
}

class QuickDashboardData {
  final DashboardPatient patient;
  final DashboardLatestVitals? latestVitals;
  final Map<String, DashboardFieldMeasurement> latestVitalsByField;

  QuickDashboardData({
    required this.patient,
    this.latestVitals,
    required this.latestVitalsByField,
  });

  factory QuickDashboardData.fromJson(Map<String, dynamic> json) {
    final latestVitalsByFieldJson =
        (json['latestVitalsByField'] as Map<String, dynamic>?) ?? const {};

    return QuickDashboardData(
      patient: DashboardPatient.fromJson(json['patient'] ?? {}),
      latestVitals: json['latestVitals'] != null
          ? DashboardLatestVitals.fromJson(json['latestVitals'])
          : null,
      latestVitalsByField: latestVitalsByFieldJson.map(
        (key, value) => MapEntry(
          key,
          DashboardFieldMeasurement.fromJson(
            (value as Map<String, dynamic>?) ?? const {},
          ),
        ),
      ),
    );
  }
}

class DashboardFieldMeasurement {
  final num? value;
  final String? measuredAt;

  const DashboardFieldMeasurement({
    required this.value,
    required this.measuredAt,
  });

  factory DashboardFieldMeasurement.fromJson(Map<String, dynamic> json) {
    return DashboardFieldMeasurement(
      value: json['value'] as num?,
      measuredAt: json['measuredAt']?.toString(),
    );
  }
}

class ProfileApi {
  final Dio _dio;
  static const Object _unsetValue = Object();

  ProfileApi(this._dio);

  static const _defaultCloudinaryUploadUrl =
      'https://api.cloudinary.com/v1_1/drvu0dpry/image/upload';

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
    final token = await _readBearerToken();
    final patientId = await _readPatientId();

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
    final token = await _readBearerToken();
    final patientId = await _readPatientId();

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
    final token = await AppSessionStore.requireToken(
      missingMessage: 'Bearer token tidak ditemukan. Isi AUTH_TOKEN di file .env',
    );
    final patientId = await AppSessionStore.requireUserId(
      missingMessage: 'patientId tidak ditemukan. Login ulang untuk menyimpan userId.',
    );

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
          healthConnectPreference: null,
          healthConnectStatus: null,
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
    final token = await _readBearerToken();
    final patientId = await _readPatientId();

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

  Future<void> updateHealthConnectSetup({
    required String healthConnectPreference,
    Object? healthConnectStatus = _unsetValue,
  }) async {
    final token = await _readBearerToken();
    final patientId = await _readPatientId();

    final payload = <String, dynamic>{
      'healthConnectPreference': healthConnectPreference,
    };

    if (!identical(healthConnectStatus, _unsetValue)) {
      payload['healthConnectStatus'] = healthConnectStatus;
    }

    final response = await _dio.put<Map<String, dynamic>>(
      '/patients/$patientId/profile',
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
        (body?['message'] ?? 'Gagal memperbarui status Health Connect')
            .toString(),
      );
    }
  }

  Future<AuthMeUser> fetchAuthMe() async {
    final token = await _readBearerToken();

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

  Future<MlRecommendationResponse?> fetchLatestMlRecommendation() async {
    final token = await _readBearerToken();
    final patientId = await _readPatientId();

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

  Future<DashboardVitalsResponse> fetchDashboardVitals(
      String timePeriod) async {
    final token = await _readBearerToken();
    final patientId = await _readPatientId();

    final response = await _dio.get<Map<String, dynamic>>(
      '/users/$patientId/dashboard/vitals',
      queryParameters: {'timePeriod': timePeriod},
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final body = response.data;
    if (body == null || body['success'] != true) {
      throw Exception(
        (body?['message'] ?? 'Gagal mengambil data dashboard vitals')
            .toString(),
      );
    }

    return DashboardVitalsResponse.fromJson(body);
  }

  Future<QuickDashboardResponse?> fetchQuickDashboard() async {
    final token = await _readBearerToken();
    final patientId = await _readPatientId();

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/users/$patientId/dashboard',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = response.data;
      if (body == null || body['success'] != true) {
        throw Exception(
          (body?['message'] ?? 'Gagal mengambil data dashboard').toString(),
        );
      }

      return QuickDashboardResponse.fromJson(body);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw Exception('Gagal mengambil data dashboard.');
    }
  }

  Future<MlRecommendationResponse> fetchMlRecommendations(String date) async {
    final token = await _readBearerToken();
    final patientId = await _readPatientId();

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
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final token = await _readBearerToken();

    final userId = await _readUserId();

    String formatDate(DateTime date) {
      return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '/users/$userId/ml-recommendations/history',
      queryParameters: {
        'page': page,
        'limit': limit,
        'startDate': startDate != null ? formatDate(startDate) : null,
        'endDate': endDate != null ? formatDate(endDate) : null,
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
    final token = await _readBearerToken();
    final patientId = await _readPatientId();

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
          (body?['message'] ?? 'Gagal menambah pengingat obat').toString());
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
          (body['message'] ?? 'Gagal mengambil daftar medication').toString());
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
          (body?['message'] ?? 'Gagal memperbarui medication').toString());
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
          (body?['message'] ?? 'Gagal menghapus medication').toString());
    }
  }

  Future<void> takeMedication(String status, String medicationId,
      DateTime scheduledDate, String scheduledTime) async {
    final token = await _readBearerToken();

    final userId = await _readUserId();

    DateTime now = DateTime.now();

    String hour = now.hour.toString().padLeft(2, '0');
    String minute = now.minute.toString().padLeft(2, '0');

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
      throw Exception((body?['message'] ??
              'Gagal menandai medication sebagai sudah diminum')
          .toString());
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

    String formatDate(DateTime date) {
      final y = date.year.toString().padLeft(4, '0');
      final m = date.month.toString().padLeft(2, '0');
      final d = date.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '/users/$patientId/medications/$medicationId/logs',
      queryParameters: {
        'page': page,
        'limit': limit,
        'startDate': formatDate(startDate),
        'endDate': formatDate(endDate),
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

class MedicationLogResponse {
  final List<MedicationLogItem> items;
  final MedicationPagination pagination;

  const MedicationLogResponse({
    required this.items,
    required this.pagination,
  });

  factory MedicationLogResponse.fromJson(Map<String, dynamic> json) {
    return MedicationLogResponse(
      items: ((json['items'] as List?) ?? const [])
          .map((e) => MedicationLogItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: MedicationPagination.fromJson(
        (json['pagination'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}

class MedicationLogItem {
  final String medicationLogId;
  final String userId;
  final String medicationId;
  final String status;
  final DateTime? medicationDate;
  final String medicationTime;
  final DateTime? createdAt;

  const MedicationLogItem({
    required this.medicationLogId,
    required this.userId,
    required this.medicationId,
    required this.status,
    required this.medicationDate,
    required this.medicationTime,
    required this.createdAt,
  });

  factory MedicationLogItem.fromJson(Map<String, dynamic> json) {
    return MedicationLogItem(
      medicationLogId: (json['medicationLogId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      medicationId: (json['medicationId'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      medicationDate:
          DateTime.tryParse((json['medicationDate'] ?? '').toString()),
      medicationTime: (json['medicationTime'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
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
  final String? healthConnectPreference;
  final String? healthConnectStatus;
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
    required this.healthConnectPreference,
    required this.healthConnectStatus,
    required this.isSmoking,
    required this.isElectricSmoking,
  });

  String get fullName => '$firstName $lastName'.trim();
  bool get isHealthConnectConnected => healthConnectStatus == 'connected';
  bool get shouldActivateHealthConnectSync =>
      healthConnectPreference == 'connect_now' &&
      healthConnectStatus == 'connected';
  bool get hasNoHealthConnectDevice => healthConnectPreference == 'no_device';
  bool get shouldPromptForHealthConnectOnLogin =>
      !hasNoHealthConnectDevice && !isHealthConnectConnected;

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
        healthConnectPreference: json['healthConnectPreference']?.toString(),
        healthConnectStatus: json['healthConnectStatus']?.toString(),
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



