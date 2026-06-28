import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/home_dashboard/data/datasources/dashboard_overview_api.dart';
import 'package:pulsewise/features/home_dashboard/data/models/dashboard_overview_models.dart';
import 'package:pulsewise/features/home_dashboard/presentation/providers/dashboard_overview_provider.dart';

void main() {
  group('dashboard overview providers', () {
    test('dashboardVitalsProvider fetches vitals for requested period',
        () async {
      final api = _FakeDashboardOverviewApi();
      final container = ProviderContainer(
        overrides: [
          dashboardOverviewApiProvider.overrideWithValue(api),
        ],
      );
      addTearDown(container.dispose);

      final response =
          await container.read(dashboardVitalsProvider('last_7_days').future);

      expect(api.fetchDashboardVitalsCalls, 1);
      expect(api.observedTimePeriods, ['last_7_days']);
      expect(response.data!.period.timePeriod, 'last_7_days');
    });

    test('quickDashboardProvider fetches quick dashboard once', () async {
      final api = _FakeDashboardOverviewApi();
      final container = ProviderContainer(
        overrides: [
          dashboardOverviewApiProvider.overrideWithValue(api),
        ],
      );
      addTearDown(container.dispose);

      final response = await container.read(quickDashboardProvider.future);

      expect(api.fetchQuickDashboardCalls, 1);
      expect(response!.data!.latestVitals!.heartRate, 72);
    });
  });
}

class _FakeDashboardOverviewApi extends DashboardOverviewApi {
  _FakeDashboardOverviewApi() : super(Dio());

  final observedTimePeriods = <String>[];
  int fetchDashboardVitalsCalls = 0;
  int fetchQuickDashboardCalls = 0;

  @override
  Future<DashboardVitalsResponse> fetchDashboardVitals(
      String timePeriod) async {
    fetchDashboardVitalsCalls++;
    observedTimePeriods.add(timePeriod);
    return _vitalsResponse(timePeriod);
  }

  @override
  Future<QuickDashboardResponse?> fetchQuickDashboard() async {
    fetchQuickDashboardCalls++;
    return _quickDashboardResponse();
  }
}

DashboardVitalsResponse _vitalsResponse(String timePeriod) {
  return DashboardVitalsResponse(
    success: true,
    message: 'OK',
    data: DashboardVitalsData(
      patient: _patient(),
      period: DashboardPeriod(
        startAt: '2026-06-22',
        endAt: '2026-06-29',
        timePeriod: timePeriod,
      ),
      series: DashboardSeries(
        timestamps: const ['2026-06-29'],
        systolicBp: const [120],
        diastolicBp: const [80],
        heartRate: const [72],
        oxygenSaturation: const [97],
        weight: const [60],
        height: const [165],
        bmi: const [22],
      ),
    ),
  );
}

QuickDashboardResponse _quickDashboardResponse() {
  return QuickDashboardResponse(
    success: true,
    message: 'OK',
    data: QuickDashboardData(
      patient: _patient(),
      latestVitals: DashboardLatestVitals(heartRate: 72),
      latestVitalsByField: const {
        'heartRate': DashboardFieldMeasurement(
          value: 72,
          measuredAt: '2026-06-29T08:00:00.000Z',
        ),
      },
    ),
  );
}

DashboardPatient _patient() {
  return DashboardPatient(
    patientId: 'patient-1',
    firstName: 'Ayu',
    lastName: 'Putri',
  );
}
