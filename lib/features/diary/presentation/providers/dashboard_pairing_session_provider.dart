import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/features/diary/data/datasources/dashboard_pairing_session_api.dart';

final dashboardPairingSessionApiProvider =
    Provider<DashboardPairingSessionApi>((ref) {
  return DashboardPairingSessionApi(ref.watch(apiDioProvider));
});
