const patientProfileMissingMessage = 'Profil pasien tidak ditemukan';

class PatientProfileNotSetupException implements Exception {
  const PatientProfileNotSetupException([
    this.message = patientProfileMissingMessage,
  ]);

  final String message;

  @override
  String toString() => message;
}

bool isPatientProfileNotSetupError(Object? error) {
  if (error == null) {
    return false;
  }

  if (error is PatientProfileNotSetupException) {
    return true;
  }

  final message = error.toString().toLowerCase();
  return message.contains(patientProfileMissingMessage.toLowerCase());
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
      dateOfBirth: DateTime.tryParse((json['date_of_birth'] ?? '').toString()),
      sex: (json['sex'] ?? '').toString(),
      bodyHeightCm: (json['body_height_cm'] ?? '').toString(),
      bloodType: (json['blood_type'] ?? '').toString(),
      healthConnectPreference: json['healthConnectPreference']?.toString(),
      healthConnectStatus: json['healthConnectStatus']?.toString(),
      isSmoking: (json['is_smoking'] as bool?) ?? false,
      isElectricSmoking: (json['is_electric_smoking'] as bool?) ?? false,
    );
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
