import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/features/diary/data/datasources/patient_share_api.dart';

final patientShareApiProvider = Provider<PatientShareApi>((ref) {
  return PatientShareApi(ref.watch(apiDioProvider));
});
