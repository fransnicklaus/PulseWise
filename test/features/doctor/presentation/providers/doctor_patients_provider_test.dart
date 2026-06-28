import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/doctor/data/datasources/doctor_dashboard_api.dart';
import 'package:pulsewise/features/doctor/data/models/doctor_dashboard_models.dart';
import 'package:pulsewise/features/doctor/presentation/providers/doctor_patients_provider.dart';
import 'package:pulsewise/features/home_dashboard/data/models/dashboard_overview_models.dart';

void main() {
  group('DoctorPatientsNotifier', () {
    test('loads patients and stores pagination state', () async {
      final notifier = DoctorPatientsNotifier(_FakeDoctorDashboardApi(
        fetchPatientsHandler: ({required int page, required int limit}) async {
          return DoctorDashboardPatientsListResponse(
            items: [_patientItem('patient-1')],
            pagination: const DoctorDashboardPagination(
              page: 1,
              limit: 5,
              totalItems: 1,
              totalPages: 1,
            ),
          );
        },
      ));

      await notifier.loadPatients(limit: 5);

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
      expect(notifier.state.items.single.patient.patientId, 'patient-1');
      expect(notifier.state.limit, 5);
      expect(notifier.state.totalItems, 1);
    });

    test('loads next page and appends patients', () async {
      final notifier = DoctorPatientsNotifier(_FakeDoctorDashboardApi(
        fetchPatientsHandler: ({required int page, required int limit}) async {
          return DoctorDashboardPatientsListResponse(
            items: [_patientItem('patient-$page')],
            pagination: DoctorDashboardPagination(
              page: page,
              limit: limit,
              totalItems: 2,
              totalPages: 2,
            ),
          );
        },
      ));

      await notifier.loadPatients();
      await notifier.loadNextPage();

      expect(notifier.state.items, hasLength(2));
      expect(notifier.state.items.first.patient.patientId, 'patient-1');
      expect(notifier.state.items.last.patient.patientId, 'patient-2');
    });

    test('does not load next page when already at last page', () async {
      final api = _FakeDoctorDashboardApi(
        fetchPatientsHandler: ({required int page, required int limit}) async {
          return DoctorDashboardPatientsListResponse(
            items: [_patientItem('patient-1')],
            pagination: const DoctorDashboardPagination(
              page: 1,
              limit: 20,
              totalItems: 1,
              totalPages: 1,
            ),
          );
        },
      );
      final notifier = DoctorPatientsNotifier(api);

      await notifier.loadPatients();
      await notifier.loadNextPage();

      expect(api.fetchPatientsCalls, 1);
      expect(notifier.state.items, hasLength(1));
    });

    test('refreshes from page one using current limit', () async {
      final requestedPages = <int>[];
      final requestedLimits = <int>[];
      final notifier = DoctorPatientsNotifier(_FakeDoctorDashboardApi(
        fetchPatientsHandler: ({required int page, required int limit}) async {
          requestedPages.add(page);
          requestedLimits.add(limit);
          return DoctorDashboardPatientsListResponse(
            items: [_patientItem('patient-$page')],
            pagination: DoctorDashboardPagination(
              page: page,
              limit: limit,
              totalItems: 2,
              totalPages: 2,
            ),
          );
        },
      ));

      await notifier.loadPatients(limit: 7);
      await notifier.loadNextPage();
      await notifier.refreshPatients();

      expect(requestedPages, [1, 2, 1]);
      expect(requestedLimits, [7, 7, 7]);
      expect(notifier.state.page, 1);
    });

    test('stores error when patients request fails', () async {
      final notifier = DoctorPatientsNotifier(_FakeDoctorDashboardApi(
        fetchPatientsHandler: ({required int page, required int limit}) async {
          throw Exception('Daftar pasien gagal dimuat');
        },
      ));

      await notifier.loadPatients();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, 'Daftar pasien gagal dimuat');
      expect(notifier.state.errorCause, isA<Exception>());
      expect(notifier.state.items, isEmpty);
    });
  });
}

class _FakeDoctorDashboardApi extends DoctorDashboardApi {
  _FakeDoctorDashboardApi({this.fetchPatientsHandler}) : super(Dio());

  final Future<DoctorDashboardPatientsListResponse> Function({
    required int page,
    required int limit,
  })? fetchPatientsHandler;

  int fetchPatientsCalls = 0;

  @override
  Future<DoctorDashboardPatientsListResponse> fetchPatients({
    int page = 1,
    int limit = 20,
  }) async {
    fetchPatientsCalls++;
    final handler = fetchPatientsHandler;
    if (handler != null) {
      return handler(page: page, limit: limit);
    }
    return DoctorDashboardPatientsListResponse(
      items: const [],
      pagination: DoctorDashboardPagination(
        page: page,
        limit: limit,
        totalItems: 0,
        totalPages: 1,
      ),
    );
  }
}

DoctorDashboardPatientListItem _patientItem(String patientId) {
  return DoctorDashboardPatientListItem(
    patient: DashboardPatient(
      patientId: patientId,
      firstName: 'Ayu',
      lastName: 'Putri',
    ),
    latestVitals: DashboardLatestVitals(heartRate: 72),
  );
}
