import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/diary/data/models/diary_models.dart';
import 'package:pulsewise/features/doctor/data/datasources/doctor_dashboard_api.dart';
import 'package:pulsewise/features/doctor/presentation/providers/doctor_recommendation_history_provider.dart';
import 'package:pulsewise/features/ml_recommendation/data/models/ml_recommendation_models.dart';

void main() {
  group('DoctorRecommendationHistoryNotifier', () {
    test('loads recommendation history for the selected patient', () async {
      late String observedPatientId;
      final notifier = DoctorRecommendationHistoryNotifier(
        _FakeDoctorDashboardApi(
          fetchHistoryHandler: (
            patientId, {
            required int page,
            required int limit,
          }) async {
            observedPatientId = patientId;
            return MlRecommendationHistoryResponse(
              items: [_historyItem('result-1')],
              pagination: const DiaryHistoryPagination(
                page: 1,
                limit: 5,
                totalItems: 1,
                totalPages: 1,
              ),
            );
          },
        ),
        'patient-1',
      );

      await notifier.loadRecommendationHistory(limit: 5);

      expect(observedPatientId, 'patient-1');
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
      expect(notifier.state.items.single.resultId, 'result-1');
      expect(notifier.state.limit, 5);
      expect(notifier.state.totalItems, 1);
    });

    test('loads next page and appends items', () async {
      final notifier = DoctorRecommendationHistoryNotifier(
        _FakeDoctorDashboardApi(
          fetchHistoryHandler: (
            patientId, {
            required int page,
            required int limit,
          }) async {
            return MlRecommendationHistoryResponse(
              items: [_historyItem('result-$page')],
              pagination: DiaryHistoryPagination(
                page: page,
                limit: limit,
                totalItems: 2,
                totalPages: 2,
              ),
            );
          },
        ),
        'patient-1',
      );

      await notifier.loadRecommendationHistory();
      await notifier.loadNextPage();

      expect(notifier.state.items, hasLength(2));
      expect(notifier.state.items.first.resultId, 'result-1');
      expect(notifier.state.items.last.resultId, 'result-2');
    });

    test('does not load next page when already at last page', () async {
      final api = _FakeDoctorDashboardApi(
        fetchHistoryHandler: (
          patientId, {
          required int page,
          required int limit,
        }) async {
          return MlRecommendationHistoryResponse(
            items: [_historyItem('result-1')],
            pagination: const DiaryHistoryPagination(
              page: 1,
              limit: 10,
              totalItems: 1,
              totalPages: 1,
            ),
          );
        },
      );
      final notifier = DoctorRecommendationHistoryNotifier(api, 'patient-1');

      await notifier.loadRecommendationHistory();
      await notifier.loadNextPage();

      expect(api.fetchHistoryCalls, 1);
      expect(notifier.state.items, hasLength(1));
    });

    test('stores error when history request fails', () async {
      final notifier = DoctorRecommendationHistoryNotifier(
        _FakeDoctorDashboardApi(
          fetchHistoryHandler: (
            patientId, {
            required int page,
            required int limit,
          }) async {
            throw Exception('Riwayat rekomendasi dokter gagal dimuat');
          },
        ),
        'patient-1',
      );

      await notifier.loadRecommendationHistory();

      expect(notifier.state.isLoading, isFalse);
      expect(
        notifier.state.error,
        'Riwayat rekomendasi dokter gagal dimuat',
      );
      expect(notifier.state.errorCause, isA<Exception>());
      expect(notifier.state.items, isEmpty);
    });

    test('loads recommendation detail and skips cached detail requests',
        () async {
      final api = _FakeDoctorDashboardApi(
        fetchDetailHandler: (patientId, resultId) async =>
            _recommendationResponse(resultId, message: patientId),
      );
      final notifier = DoctorRecommendationHistoryNotifier(api, 'patient-1');

      await notifier.loadRecommendationDetail('result-1');
      await notifier.loadRecommendationDetail('result-1');

      expect(api.fetchDetailCalls, 1);
      expect(
          notifier.state.detailsByResultId['result-1']!.message, 'patient-1');
      expect(
          notifier.state.loadingDetailResultIds, isNot(contains('result-1')));
      expect(notifier.state.detailErrorsByResultId, isEmpty);
    });

    test('stores detail error when detail request fails', () async {
      final notifier = DoctorRecommendationHistoryNotifier(
        _FakeDoctorDashboardApi(
          fetchDetailHandler: (patientId, resultId) async {
            throw Exception('Detail rekomendasi dokter gagal');
          },
        ),
        'patient-1',
      );

      await notifier.loadRecommendationDetail('result-1');

      expect(notifier.state.detailsByResultId, isEmpty);
      expect(
          notifier.state.loadingDetailResultIds, isNot(contains('result-1')));
      expect(
        notifier.state.detailErrorsByResultId['result-1'],
        'Detail rekomendasi dokter gagal',
      );
      expect(
        notifier.state.detailErrorCausesByResultId['result-1'],
        isA<Exception>(),
      );
    });

    test('refreshHistory clears detail caches and reloads page one', () async {
      final requestedPages = <int>[];
      final notifier = DoctorRecommendationHistoryNotifier(
        _FakeDoctorDashboardApi(
          fetchHistoryHandler: (
            patientId, {
            required int page,
            required int limit,
          }) async {
            requestedPages.add(page);
            return MlRecommendationHistoryResponse(
              items: [_historyItem('result-$page')],
              pagination: DiaryHistoryPagination(
                page: page,
                limit: limit,
                totalItems: 2,
                totalPages: 2,
              ),
            );
          },
          fetchDetailHandler: (patientId, resultId) async =>
              _recommendationResponse(resultId),
        ),
        'patient-1',
      );

      await notifier.loadRecommendationHistory(limit: 7);
      await notifier.loadNextPage();
      await notifier.loadRecommendationDetail('result-1');
      await notifier.refreshHistory();

      expect(requestedPages, [1, 2, 1]);
      expect(notifier.state.page, 1);
      expect(notifier.state.limit, 7);
      expect(notifier.state.detailsByResultId, isEmpty);
      expect(notifier.state.detailErrorsByResultId, isEmpty);
    });
  });
}

typedef _FetchHistoryHandler = Future<MlRecommendationHistoryResponse> Function(
  String patientId, {
  required int page,
  required int limit,
});

class _FakeDoctorDashboardApi extends DoctorDashboardApi {
  _FakeDoctorDashboardApi({
    this.fetchHistoryHandler,
    this.fetchDetailHandler,
  }) : super(Dio());

  final _FetchHistoryHandler? fetchHistoryHandler;
  final Future<MlRecommendationResponse> Function(
    String patientId,
    String resultId,
  )? fetchDetailHandler;

  int fetchHistoryCalls = 0;
  int fetchDetailCalls = 0;

  @override
  Future<MlRecommendationHistoryResponse> fetchPatientMlRecommendationHistory(
    String patientId, {
    int page = 1,
    int limit = 10,
  }) async {
    fetchHistoryCalls++;
    final handler = fetchHistoryHandler;
    if (handler != null) {
      return handler(patientId, page: page, limit: limit);
    }
    return MlRecommendationHistoryResponse(
      items: const [],
      pagination: DiaryHistoryPagination(
        page: page,
        limit: limit,
        totalItems: 0,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<MlRecommendationResponse> fetchPatientMlRecommendationHistoryDetail(
    String patientId,
    String resultId,
  ) async {
    fetchDetailCalls++;
    final handler = fetchDetailHandler;
    if (handler != null) {
      return handler(patientId, resultId);
    }
    return _recommendationResponse(resultId);
  }
}

MlRecommendationHistoryItem _historyItem(String resultId) {
  return MlRecommendationHistoryItem(
    resultId: resultId,
    inferenceType: 'daily',
    requestContext: 'doctor_dashboard',
    mlVersion: 'v1',
    generatedAt: '2026-06-28T08:00:00.000Z',
  );
}

MlRecommendationResponse _recommendationResponse(
  String resultId, {
  String message = 'OK',
}) {
  return MlRecommendationResponse(
    success: true,
    message: message,
    data: MlRecommendationData(
      resultId: resultId,
      patientId: 'patient-1',
      requestedByUserId: 'doctor-1',
      inferenceType: 'daily',
      requestContext: 'doctor_dashboard',
      mlVersion: 'v1',
      payloadHash: 'hash-1',
      generatedAt: '2026-06-28T08:00:00.000Z',
      createdAt: '2026-06-28T08:01:00.000Z',
    ),
  );
}
