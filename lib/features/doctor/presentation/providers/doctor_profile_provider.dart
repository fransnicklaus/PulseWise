import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/features/doctor/data/datasources/doctor_profile_api.dart';
import 'package:pulsewise/features/doctor/data/models/doctor_profile_models.dart';

final doctorProfileApiProvider = Provider<DoctorProfileApi>((ref) {
  return DoctorProfileApi(ref.watch(apiDioProvider));
});

final doctorProfileProvider = FutureProvider<DoctorProfile>((ref) async {
  final api = ref.watch(doctorProfileApiProvider);
  return api.fetchProfile();
});
