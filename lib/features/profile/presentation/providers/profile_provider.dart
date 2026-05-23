import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/features/profile/data/datasources/patient_profile_api.dart';
import 'package:pulsewise/features/profile/data/models/profile_models.dart';

final patientProfileApiProvider = Provider<PatientProfileApi>((ref) {
  return PatientProfileApi(ref.watch(apiDioProvider));
});

final patientProfileProvider = FutureProvider<PatientProfile>((ref) async {
  final api = ref.watch(patientProfileApiProvider);
  return api.fetchProfile();
});

final authMeProvider = FutureProvider<AuthMeUser>((ref) async {
  final api = ref.watch(patientProfileApiProvider);
  return api.fetchAuthMe();
});
