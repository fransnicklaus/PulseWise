import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/diary/data/models/diary_models.dart';
import 'package:pulsewise/features/ml_recommendation/data/datasources/ml_recommendation_api.dart';
import 'package:pulsewise/features/ml_recommendation/data/models/ml_recommendation_models.dart';
import 'package:pulsewise/features/ml_recommendation/presentation/providers/recommendation_history_provider.dart';

void main() {
  group('RecommendationHistoryNotifier', () {
    test('loads first page with filters and stores pagination state', () async {
      final startDate = DateTime(2026, 6, 1);
      final endDate = DateTime(2026, 6, 28);
      late DateTime? observedStartDate;
      late DateTime? observedEndDate;

      final notifier = RecommendationHistoryNotifier(_FakeRecommendationApi(
        fetchHistoryHandler: ({
          required int page,
          required int limit,
          DateTime? startDate,
          DateTime? endDate,
        }) async {
          observedStartDate = startDate;
          observedEndDate = endDate;
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
      ));

      await notifier.loadRecommendationHistory(
        limit: 5,
        startDate: startDate,
        endDate: endDate,
      );

      expect(observedStartDate, startDate);
      expect(observedEndDate, endDate);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
      expect(notifier.state.items.single.resultId, 'result-1');
      expect(notifier.state.limit, 5);
      expect(notifier.state.totalItems, 1);
    });

    test('loads next page and appends items', () async {
      final notifier = RecommendationHistoryNotifier(_FakeRecommendationApi(
        fetchHistoryHandler: ({
          required int page,
          required int limit,
          DateTime? startDate,
          DateTime? endDate,
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
      ));

      await notifier.loadRecommendationHistory();
      await notifier.loadNextPage();

      expect(notifier.state.items, hasLength(2));
      expect(notifier.state.items.first.resultId, 'result-1');
      expect(notifier.state.items.last.resultId, 'result-2');
    });

    test('does not load next page when already at last page', () async {
      final api = _FakeRecommendationApi(
        fetchHistoryHandler: ({
          required int page,
          required int limit,
          DateTime? startDate,
          DateTime? endDate,
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
      final notifier = RecommendationHistoryNotifier(api);

      await notifier.loadRecommendationHistory();
      await notifier.loadNextPage();

      expect(api.fetchHistoryCalls, 1);
      expect(notifier.state.items, hasLength(1));
    });

    test('stores error when history request fails', () async {
      final notifier = RecommendationHistoryNotifier(_FakeRecommendationApi(
        fetchHistoryHandler: ({
          required int page,
          required int limit,
          DateTime? startDate,
          DateTime? endDate,
        }) async {
          throw Exception('Riwayat rekomendasi gagal dimuat');
        },
      ));

      await notifier.loadRecommendationHistory();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, 'Riwayat rekomendasi gagal dimuat');
      expect(notifier.state.errorCause, isA<Exception>());
      expect(notifier.state.items, isEmpty);
    });

    test('loads recommendation detail and skips cached detail requests',
        () async {
      final api = _FakeRecommendationApi(
        fetchDetailHandler: (resultId) async => _recommendationResponse(
          resultId,
          message: 'detail loaded',
        ),
      );
      final notifier = RecommendationHistoryNotifier(api);

      await notifier.loadRecommendationDetail('result-1');
      await notifier.loadRecommendationDetail('result-1');

      expect(api.fetchDetailCalls, 1);
      expect(notifier.state.detailsByDiaryId['result-1']!.message,
          'detail loaded');
      expect(notifier.state.loadingDetailDiaryIds, isNot(contains('result-1')));
      expect(notifier.state.detailErrorsByDiaryId, isEmpty);
    });

    test('stores detail error when detail request fails', () async {
      final notifier = RecommendationHistoryNotifier(_FakeRecommendationApi(
        fetchDetailHandler: (resultId) async {
          throw Exception('Detail rekomendasi gagal');
        },
      ));

      await notifier.loadRecommendationDetail('result-1');

      expect(notifier.state.detailsByDiaryId, isEmpty);
      expect(notifier.state.loadingDetailDiaryIds, isNot(contains('result-1')));
      expect(
        notifier.state.detailErrorsByDiaryId['result-1'],
        'Detail rekomendasi gagal',
      );
      expect(
        notifier.state.detailErrorCausesByDiaryId['result-1'],
        isA<Exception>(),
      );
    });

    test('refreshHistory clears detail caches and reloads page one', () async {
      final requestedPages = <int>[];
      final notifier = RecommendationHistoryNotifier(_FakeRecommendationApi(
        fetchHistoryHandler: ({
          required int page,
          required int limit,
          DateTime? startDate,
          DateTime? endDate,
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
        fetchDetailHandler: (resultId) async => _recommendationResponse(
          resultId,
        ),
      ));

      await notifier.loadRecommendationHistory(limit: 7);
      await notifier.loadNextPage();
      await notifier.loadRecommendationDetail('result-1');
      await notifier.refreshHistory();

      expect(requestedPages, [1, 2, 1]);
      expect(notifier.state.page, 1);
      expect(notifier.state.limit, 7);
      expect(notifier.state.detailsByDiaryId, isEmpty);
      expect(notifier.state.detailErrorsByDiaryId, isEmpty);
    });

    test('clearCache resets state to initial values', () async {
      final notifier = RecommendationHistoryNotifier(_FakeRecommendationApi(
        fetchHistoryHandler: ({
          required int page,
          required int limit,
          DateTime? startDate,
          DateTime? endDate,
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
      ));

      await notifier.loadRecommendationHistory();
      notifier.clearCache();

      expect(notifier.state.items, isEmpty);
      expect(notifier.state.page, 1);
      expect(notifier.state.totalItems, 0);
      expect(notifier.state.detailsByDiaryId, isEmpty);
    });
  });
}

typedef _FetchHistoryHandler = Future<MlRecommendationHistoryResponse>
    Function({
  required int page,
  required int limit,
  DateTime? startDate,
  DateTime? endDate,
});

class _FakeRecommendationApi extends MlRecommendationApi {
  _FakeRecommendationApi({
    this.fetchHistoryHandler,
    this.fetchDetailHandler,
  }) : super(Dio());

  final _FetchHistoryHandler? fetchHistoryHandler;
  final Future<MlRecommendationResponse> Function(String resultId)?
      fetchDetailHandler;

  int fetchHistoryCalls = 0;
  int fetchDetailCalls = 0;

  @override
  Future<MlRecommendationHistoryResponse> fetchMlRecommendationHistory({
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    fetchHistoryCalls++;
    final handler = fetchHistoryHandler;
    if (handler != null) {
      return handler(
        page: page,
        limit: limit,
        startDate: startDate,
        endDate: endDate,
      );
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
  Future<MlRecommendationResponse> fetchMlRecommendationHistoryDetail(
    String resultId,
  ) async {
    fetchDetailCalls++;
    final handler = fetchDetailHandler;
    if (handler != null) {
      return handler(resultId);
    }
    return _recommendationResponse(resultId);
  }
}

MlRecommendationHistoryItem _historyItem(String resultId) {
  return MlRecommendationHistoryItem(
    resultId: resultId,
    inferenceType: 'daily',
    requestContext: 'manual',
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
      requestedByUserId: 'user-1',
      inferenceType: 'daily',
      requestContext: 'manual',
      mlVersion: 'v1',
      payloadHash: 'hash-1',
      generatedAt: '2026-06-28T08:00:00.000Z',
      createdAt: '2026-06-28T08:01:00.000Z',
    ),
  );
}
