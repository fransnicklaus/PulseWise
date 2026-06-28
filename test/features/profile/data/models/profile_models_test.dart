import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/profile/data/models/profile_models.dart';

void main() {
  group('AuthMeUser', () {
    test('parses auth me payload and email verification date', () {
      final user = AuthMeUser.fromJson({
        'userId': 123,
        'username': 'patientone',
        'email': 'patient@example.com',
        'firstName': 'Ayu',
        'lastName': 'Putri',
        'avatarPhoto': 'avatar.png',
        'role': 'patient',
        'accountStatus': 'active',
        'emailVerifiedAt': '2026-06-29T08:00:00.000Z',
      });

      expect(user.userId, '123');
      expect(user.username, 'patientone');
      expect(user.email, 'patient@example.com');
      expect(user.firstName, 'Ayu');
      expect(user.lastName, 'Putri');
      expect(user.avatarPhoto, 'avatar.png');
      expect(user.role, 'patient');
      expect(user.accountStatus, 'active');
      expect(user.emailVerifiedAt, DateTime.parse('2026-06-29T08:00:00.000Z'));
    });
  });

  group('PatientProfile', () {
    test('parses profile payload and health connect flags', () {
      final profile = PatientProfile.fromJson({
        'patient_id': 'patient-1',
        'first_name': 'Ayu',
        'last_name': 'Putri',
        'email': 'ayu@example.com',
        'address': 'Jakarta',
        'date_of_birth': '1990-01-02',
        'sex': 'female',
        'body_height_cm': 165,
        'blood_type': 'O',
        'healthConnectPreference': 'connect_now',
        'healthConnectStatus': 'connected',
        'is_smoking': true,
        'is_electric_smoking': false,
      });

      expect(profile.patientId, 'patient-1');
      expect(profile.fullName, 'Ayu Putri');
      expect(profile.dateOfBirth, DateTime.parse('1990-01-02'));
      expect(profile.bodyHeightCm, '165');
      expect(profile.isSmoking, isTrue);
      expect(profile.isElectricSmoking, isFalse);
      expect(profile.isHealthConnectConnected, isTrue);
      expect(profile.shouldActivateHealthConnectSync, isTrue);
      expect(profile.hasNoHealthConnectDevice, isFalse);
      expect(profile.shouldPromptForHealthConnectOnLogin, isFalse);
    });

    test('detects missing profile and prompt flags', () {
      const exception = PatientProfileNotSetupException();
      final profile = PatientProfile.fromJson({
        'first_name': 'Ayu',
        'healthConnectPreference': 'ask_later',
        'healthConnectStatus': 'disconnected',
        'date_of_birth': 'not-a-date',
      });

      expect(profile.fullName, 'Ayu');
      expect(profile.dateOfBirth, isNull);
      expect(profile.isSmoking, isFalse);
      expect(profile.isElectricSmoking, isFalse);
      expect(profile.shouldPromptForHealthConnectOnLogin, isTrue);
      expect(isPatientProfileNotSetupError(exception), isTrue);
      expect(
          isPatientProfileNotSetupError(
              Exception(patientProfileMissingMessage)),
          isTrue);
      expect(isPatientProfileNotSetupError(Exception('Other error')), isFalse);
      expect(isPatientProfileNotSetupError(null), isFalse);
    });

    test('does not prompt health connect when user has no device', () {
      final profile = PatientProfile.fromJson({
        'healthConnectPreference': 'no_device',
        'healthConnectStatus': 'disconnected',
      });

      expect(profile.hasNoHealthConnectDevice, isTrue);
      expect(profile.shouldPromptForHealthConnectOnLogin, isFalse);
    });
  });

  group('AvatarUploadSignature', () {
    test('parses aliases and defaults optional Cloudinary options', () {
      final signature = AvatarUploadSignature.fromJson({
        'url': 'https://upload.example.com',
        'apiKey': 'api-key',
        'timestamp': 1234.9,
        'folder': 'avatars',
        'signature': 'signature',
      });

      expect(signature.uploadUrl, 'https://upload.example.com');
      expect(signature.apiKey, 'api-key');
      expect(signature.timestamp, 1234);
      expect(signature.folder, 'avatars');
      expect(signature.signature, 'signature');
      expect(signature.transformation, 'c_limit,h_512,w_512,q_auto:good');
      expect(signature.allowedFormats, 'jpg,jpeg,png,webp');
    });
  });

  group('CloudinaryUploadResult', () {
    test('parses upload result and numeric metadata', () {
      final result = CloudinaryUploadResult.fromJson({
        'secure_url': 'https://cdn.example.com/avatar.png',
        'public_id': 'avatars/patient-1',
        'bytes': 2048.7,
        'width': 512,
        'height': 256.9,
        'format': 'png',
        'resource_type': 'image',
      });

      expect(result.secureUrl, 'https://cdn.example.com/avatar.png');
      expect(result.publicId, 'avatars/patient-1');
      expect(result.bytes, 2048);
      expect(result.width, 512);
      expect(result.height, 256);
      expect(result.format, 'png');
      expect(result.resourceType, 'image');
    });
  });
}
