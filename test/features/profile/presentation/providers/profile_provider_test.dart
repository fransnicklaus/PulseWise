import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/profile/data/datasources/patient_profile_api.dart';
import 'package:pulsewise/features/profile/data/models/profile_models.dart';
import 'package:pulsewise/features/profile/presentation/providers/profile_provider.dart';

void main() {
  group('profile providers', () {
    test('patientProfileProvider fetches profile through PatientProfileApi',
        () async {
      final api = _FakePatientProfileApi(
        profile: _patientProfile('patient-1'),
      );
      final container = ProviderContainer(
        overrides: [
          patientProfileApiProvider.overrideWithValue(api),
        ],
      );
      addTearDown(container.dispose);

      final profile = await container.read(patientProfileProvider.future);

      expect(api.fetchProfileCalls, 1);
      expect(profile.patientId, 'patient-1');
      expect(profile.fullName, 'Ayu Putri');
    });

    test('authMeProvider fetches auth user through PatientProfileApi',
        () async {
      final api = _FakePatientProfileApi(
        authMeUser: _authMeUser('user-1'),
      );
      final container = ProviderContainer(
        overrides: [
          patientProfileApiProvider.overrideWithValue(api),
        ],
      );
      addTearDown(container.dispose);

      final user = await container.read(authMeProvider.future);

      expect(api.fetchAuthMeCalls, 1);
      expect(user.userId, 'user-1');
      expect(user.email, 'ayu@example.com');
    });
  });
}

class _FakePatientProfileApi extends PatientProfileApi {
  _FakePatientProfileApi({
    PatientProfile? profile,
    AuthMeUser? authMeUser,
  })  : profile = profile ?? _patientProfile('patient-1'),
        authMeUser = authMeUser ?? _authMeUser('user-1'),
        super(Dio());

  final PatientProfile profile;
  final AuthMeUser authMeUser;

  int fetchProfileCalls = 0;
  int fetchAuthMeCalls = 0;

  @override
  Future<PatientProfile> fetchProfile() async {
    fetchProfileCalls++;
    return profile;
  }

  @override
  Future<AuthMeUser> fetchAuthMe() async {
    fetchAuthMeCalls++;
    return authMeUser;
  }
}

PatientProfile _patientProfile(String patientId) {
  return PatientProfile(
    patientId: patientId,
    firstName: 'Ayu',
    lastName: 'Putri',
    email: 'ayu@example.com',
    address: 'Jakarta',
    dateOfBirth: DateTime(1990, 1, 2),
    sex: 'female',
    bodyHeightCm: '165',
    bloodType: 'O',
    healthConnectPreference: 'connect_now',
    healthConnectStatus: 'connected',
    isSmoking: false,
    isElectricSmoking: false,
  );
}

AuthMeUser _authMeUser(String userId) {
  return AuthMeUser(
    userId: userId,
    username: 'patientone',
    email: 'ayu@example.com',
    firstName: 'Ayu',
    lastName: 'Putri',
    avatarPhoto: 'avatar.png',
    role: 'patient',
    accountStatus: 'active',
    emailVerifiedAt: DateTime(2026, 6, 29, 8),
  );
}
