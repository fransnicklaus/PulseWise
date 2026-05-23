import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/features/home_dashboard/data/datasources/dashboard_overview_api.dart';
import 'package:pulsewise/features/home_dashboard/data/models/dashboard_overview_models.dart';

final dashboardOverviewApiProvider = Provider<DashboardOverviewApi>((ref) {
  return DashboardOverviewApi(ref.watch(apiDioProvider));
});

final dashboardVitalsProvider =
    FutureProvider.family<DashboardVitalsResponse, String>(
  (ref, timePeriod) async {
    final api = ref.watch(dashboardOverviewApiProvider);
    return api.fetchDashboardVitals(timePeriod);
  },
);

final quickDashboardProvider =
    FutureProvider<QuickDashboardResponse?>((ref) async {
  final api = ref.watch(dashboardOverviewApiProvider);
  return api.fetchQuickDashboard();
});
