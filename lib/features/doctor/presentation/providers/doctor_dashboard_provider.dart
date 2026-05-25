import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/features/doctor/data/datasources/doctor_dashboard_api.dart';

final doctorDashboardApiProvider = Provider<DoctorDashboardApi>((ref) {
  return DoctorDashboardApi(ref.watch(apiDioProvider));
});
