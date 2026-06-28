import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/medication/data/datasources/medication_api.dart';
import 'package:pulsewise/features/medication/data/models/medication_models.dart';
import 'package:pulsewise/features/medication/presentation/providers/medication_history_provider.dart';

void main() {
  group('MedicationHistoryNotifier', () {
    test('loads medications and stores pagination state', () async {
      final notifier = MedicationHistoryNotifier(_FakeMedicationApi(
        fetchMedicationsHandler: (
            {required int page, required int limit}) async {
          return MedicationListResponse(
            items: [_medicationItem('med-1')],
            pagination: const MedicationPagination(
              page: 1,
              limit: 5,
              totalItems: 1,
              totalPages: 1,
            ),
          );
        },
      ));

      await notifier.loadMedications(limit: 5);

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
      expect(notifier.state.items.single.medicationId, 'med-1');
      expect(notifier.state.limit, 5);
      expect(notifier.state.totalItems, 1);
    });

    test('loads next page and appends items', () async {
      final notifier = MedicationHistoryNotifier(_FakeMedicationApi(
        fetchMedicationsHandler: (
            {required int page, required int limit}) async {
          return MedicationListResponse(
            items: [_medicationItem('med-$page')],
            pagination: MedicationPagination(
              page: page,
              limit: limit,
              totalItems: 2,
              totalPages: 2,
            ),
          );
        },
      ));

      await notifier.loadMedications();
      await notifier.loadNextPage();

      expect(notifier.state.items, hasLength(2));
      expect(notifier.state.items.first.medicationId, 'med-1');
      expect(notifier.state.items.last.medicationId, 'med-2');
    });

    test('does not load next page when already at last page', () async {
      final api = _FakeMedicationApi(
        fetchMedicationsHandler: (
            {required int page, required int limit}) async {
          return MedicationListResponse(
            items: [_medicationItem('med-1')],
            pagination: const MedicationPagination(
              page: 1,
              limit: 10,
              totalItems: 1,
              totalPages: 1,
            ),
          );
        },
      );
      final notifier = MedicationHistoryNotifier(api);

      await notifier.loadMedications();
      await notifier.loadNextPage();

      expect(api.fetchMedicationsCalls, 1);
      expect(notifier.state.items, hasLength(1));
    });

    test('refreshes from page one using current limit', () async {
      final requestedPages = <int>[];
      final requestedLimits = <int>[];
      final notifier = MedicationHistoryNotifier(_FakeMedicationApi(
        fetchMedicationsHandler: (
            {required int page, required int limit}) async {
          requestedPages.add(page);
          requestedLimits.add(limit);
          return MedicationListResponse(
            items: [_medicationItem('med-$page')],
            pagination: MedicationPagination(
              page: page,
              limit: limit,
              totalItems: 2,
              totalPages: 2,
            ),
          );
        },
      ));

      await notifier.loadMedications(limit: 7);
      await notifier.loadNextPage();
      await notifier.refreshMedications();

      expect(requestedPages, [1, 2, 1]);
      expect(requestedLimits, [7, 7, 7]);
      expect(notifier.state.page, 1);
    });

    test('stores error when API throws', () async {
      final notifier = MedicationHistoryNotifier(_FakeMedicationApi(
        fetchMedicationsHandler: (
            {required int page, required int limit}) async {
          throw Exception('Medication gagal dimuat');
        },
      ));

      await notifier.loadMedications();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, 'Medication gagal dimuat');
      expect(notifier.state.errorCause, isA<Exception>());
      expect(notifier.state.items, isEmpty);
    });
  });
}

class _FakeMedicationApi extends MedicationApi {
  _FakeMedicationApi({this.fetchMedicationsHandler}) : super(Dio());

  final Future<MedicationListResponse> Function({
    required int page,
    required int limit,
  })? fetchMedicationsHandler;

  int fetchMedicationsCalls = 0;

  @override
  Future<MedicationListResponse> fetchMedications({
    int page = 1,
    int limit = 10,
  }) async {
    fetchMedicationsCalls++;
    final handler = fetchMedicationsHandler;
    if (handler != null) {
      return handler(page: page, limit: limit);
    }
    return MedicationListResponse(
      items: const [],
      pagination: MedicationPagination(
        page: page,
        limit: limit,
        totalItems: 0,
        totalPages: 1,
      ),
    );
  }
}

MedicationItem _medicationItem(String medicationId) {
  return MedicationItem(
    medicationId: medicationId,
    userId: 'user-1',
    name: 'Aspirin',
    description: null,
    conditionTag: null,
    form: 'tablet',
    color: '#FFFFFF',
    singleDose: 1,
    singleDoseUnit: 'tablet',
    startDate: DateTime(2026, 6, 28),
    frequency: 'daily',
    numOfDays: 7,
    daysOfWeek: const [],
    intakeTimes: const ['08:00'],
    note: null,
    createdAt: DateTime(2026, 6, 27),
    reminders: const [],
  );
}
