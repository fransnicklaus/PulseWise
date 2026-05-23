import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/features/health_connect/data/datasources/health_connect_setup_api.dart';

final healthConnectSetupApiProvider = Provider<HealthConnectSetupApi>((ref) {
  return HealthConnectSetupApi(ref.watch(apiDioProvider));
});
