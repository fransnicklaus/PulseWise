import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pulsewise/core/network/network_error_utils.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/profile/data/models/profile_models.dart';

class PatientProfileApi {
  PatientProfileApi(this._dio);

  final Dio _dio;

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
        headers: const {
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
      missingMessage:
          'Bearer token tidak ditemukan. Isi AUTH_TOKEN di file .env',
    );
    final patientId = await AppSessionStore.requireUserId(
      missingMessage:
          'patientId tidak ditemukan. Login ulang untuk menyimpan userId.',
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

      if (isNetworkRequestError(e)) {
        rethrow;
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
        (body?['message'] ?? 'Gagal memperbarui profil').toString(),
      );
    }
  }

  Future<AuthMeUser> fetchAuthMe() async {
    final token = await _readBearerToken();

    try {
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
    } on DioException catch (e) {
      if (isNetworkRequestError(e)) {
        rethrow;
      }

      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) {
          throw Exception(message);
        }
      }

      throw Exception('Gagal mengambil data auth me.');
    }
  }
}
