import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/features/doctor/data/datasources/doctor_profile_api.dart';
import 'package:pulsewise/features/doctor/data/models/doctor_profile_models.dart';
import 'package:pulsewise/features/doctor/presentation/providers/doctor_profile_provider.dart';

void main() {
  group('doctor profile providers', () {
    test('doctorProfileApiProvider creates API from shared Dio', () {
      final container = ProviderContainer(
        overrides: [
          apiDioProvider.overrideWithValue(Dio()),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(doctorProfileApiProvider),
        isA<DoctorProfileApi>(),
      );
    });

    test('doctorProfileProvider fetches profile through DoctorProfileApi',
        () async {
      final api = _FakeDoctorProfileApi(_doctorProfile('doctor-1'));
      final container = ProviderContainer(
        overrides: [
          doctorProfileApiProvider.overrideWithValue(api),
        ],
      );
      addTearDown(container.dispose);

      final profile = await container.read(doctorProfileProvider.future);

      expect(api.fetchProfileCalls, 1);
      expect(profile.doctorId, 'doctor-1');
      expect(profile.fullName, 'Budi Santoso');
    });
  });
}

class _FakeDoctorProfileApi extends DoctorProfileApi {
  _FakeDoctorProfileApi(this.profile) : super(Dio());

  final DoctorProfile profile;
  int fetchProfileCalls = 0;

  @override
  Future<DoctorProfile> fetchProfile() async {
    fetchProfileCalls++;
    return profile;
  }
}

DoctorProfile _doctorProfile(String doctorId) {
  return DoctorProfile(
    doctorId: doctorId,
    specialization: 'Cardiology',
    licenseNo: 'STR-123',
    hospitalName: 'PulseWise Hospital',
    createdAt: DateTime(2026, 6, 29, 8),
    firstName: 'Budi',
    lastName: 'Santoso',
    email: 'budi@example.com',
    avatarPhoto: 'avatar.png',
  );
}
