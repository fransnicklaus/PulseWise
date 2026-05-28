import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/doctor/data/models/doctor_profile_models.dart';

class DoctorProfileApi {
  DoctorProfileApi(this._dio);

  final Dio _dio;

  static const _defaultCloudinaryUploadUrl =
      'https://api.cloudinary.com/v1_1/drvu0dpry/image/upload';

  Future<String> _readBearerToken() {
    return AppSessionStore.requireToken(
      missingMessage:
          'Bearer token tidak ditemukan. Silakan login ulang sebagai dokter.',
    );
  }

  Future<String> _readDoctorId() {
    return AppSessionStore.requireUserId(
      missingMessage: 'doctorId tidak ditemukan. Silakan login ulang.',
    );
  }

  Future<void> uploadAvatar({
    required MultipartFile file,
  }) async {
    final signature = await _fetchAvatarUploadSignature(
      folder: dotenv.env['CLOUDINARY_FOLDER'] ?? 'pulsewise/avatars',
    );

    final uploadResult = await _uploadAvatarToCloudinary(
      file: file,
      signature: signature,
    );

    await _saveAvatarMetadata(
      secureUrl: uploadResult.secureUrl,
      publicId: uploadResult.publicId,
      bytes: uploadResult.bytes,
      width: uploadResult.width,
      height: uploadResult.height,
      format: uploadResult.format,
      resourceType: uploadResult.resourceType,
    );
  }

  Future<DoctorProfile> fetchProfile() async {
    final token = await _readBearerToken();
    final doctorId = await _readDoctorId();

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/doctors/$doctorId/profile',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = response.data;
      if (body == null || body['data'] == null) {
        throw Exception('Respons profil dokter tidak valid dari server');
      }

      return DoctorProfile.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return DoctorProfile(
          doctorId: doctorId,
          specialization: '',
          licenseNo: '',
          hospitalName: '',
          createdAt: null,
          firstName: '',
          lastName: '',
          email: '',
          avatarPhoto: '',
        );
      }

      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) {
          throw Exception(message);
        }
      }

      throw Exception('Gagal mengambil profil dokter.');
    }
  }

  Future<void> updateDoctorProfile({
    required String specialization,
    required String licenseNo,
    required String hospitalName,
  }) async {
    final token = await _readBearerToken();
    final doctorId = await _readDoctorId();

    final response = await _dio.put<Map<String, dynamic>>(
      '/doctors/$doctorId/profile',
      data: {
        'specialization': specialization,
        'licenseNo': licenseNo,
        'hospitalName': hospitalName,
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
        (body?['message'] ?? 'Gagal memperbarui profil dokter').toString(),
      );
    }
  }

  Future<_AvatarUploadSignature> _fetchAvatarUploadSignature({
    required String folder,
  }) async {
    final token = await _readBearerToken();
    final doctorId = await _readDoctorId();

    final response = await _dio.get<Map<String, dynamic>>(
      '/users/$doctorId/avatar/upload-signature',
      queryParameters: {'folder': folder},
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final body = response.data;
    if (body == null) {
      throw Exception('Respons signature upload avatar dokter tidak valid');
    }

    if (body['success'] != true) {
      throw Exception(
        (body['message'] ?? 'Gagal mendapatkan signature upload avatar dokter')
            .toString(),
      );
    }

    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    return _AvatarUploadSignature.fromJson(data);
  }

  Future<_CloudinaryUploadResult> _uploadAvatarToCloudinary({
    required MultipartFile file,
    required _AvatarUploadSignature signature,
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
      throw Exception('Respons upload Cloudinary dokter tidak valid');
    }

    return _CloudinaryUploadResult.fromJson(body);
  }

  Future<void> _saveAvatarMetadata({
    required String secureUrl,
    required String publicId,
    required int bytes,
    required int width,
    required int height,
    required String format,
    required String resourceType,
  }) async {
    final token = await _readBearerToken();
    final doctorId = await _readDoctorId();

    final response = await _dio.put<Map<String, dynamic>>(
      '/users/$doctorId/avatar',
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
        (body?['message'] ?? 'Gagal menyimpan avatar dokter').toString(),
      );
    }
  }
}

class _AvatarUploadSignature {
  const _AvatarUploadSignature({
    required this.uploadUrl,
    required this.apiKey,
    required this.timestamp,
    required this.folder,
    required this.signature,
    required this.transformation,
    required this.allowedFormats,
  });

  final String uploadUrl;
  final String apiKey;
  final int timestamp;
  final String folder;
  final String signature;
  final String transformation;
  final String allowedFormats;

  factory _AvatarUploadSignature.fromJson(Map<String, dynamic> json) {
    return _AvatarUploadSignature(
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

class _CloudinaryUploadResult {
  const _CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
    required this.bytes,
    required this.width,
    required this.height,
    required this.format,
    required this.resourceType,
  });

  final String secureUrl;
  final String publicId;
  final int bytes;
  final int width;
  final int height;
  final String format;
  final String resourceType;

  factory _CloudinaryUploadResult.fromJson(Map<String, dynamic> json) {
    return _CloudinaryUploadResult(
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
