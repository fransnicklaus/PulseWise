import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/features/medication/data/datasources/medication_api.dart';

final medicationApiProvider = Provider<MedicationApi>((ref) {
  return MedicationApi(ref.watch(apiDioProvider));
});
