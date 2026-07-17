import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/diary/data/datasources/diary_api.dart';
import 'package:pulsewise/features/diary/data/models/diary_models.dart';
import 'package:pulsewise/features/diary/presentation/providers/diary_history_provider.dart';

void main() {
  group('DiaryHistoryNotifier', () {
    test('loads first page with filters and stores pagination state', () async {
      final startDate = DateTime(2026, 6, 1);
      final endDate = DateTime(2026, 6, 28);
      late DateTime? observedStartDate;
      late DateTime? observedEndDate;

      final notifier = DiaryHistoryNotifier(_FakeDiaryApi(
        fetchDiaryHistoryHandler: ({
          required int page,
          required int limit,
          DateTime? startDate,
          DateTime? endDate,
        }) async {
          observedStartDate = startDate;
          observedEndDate = endDate;
          return DiaryHistoryResponse(
            items: [_historyItem('diary-1')],
            pagination: const DiaryHistoryPagination(
              page: 1,
              limit: 5,
              totalItems: 1,
              totalPages: 1,
            ),
          );
        },
      ));

      await notifier.loadDiaryHistory(
        limit: 5,
        startDate: startDate,
        endDate: endDate,
      );

      expect(observedStartDate, startDate);
      expect(observedEndDate, endDate);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
      expect(notifier.state.items.single.diaryId, 'diary-1');
      expect(notifier.state.limit, 5);
      expect(notifier.state.totalItems, 1);
    });

    test('loads next page and appends items', () async {
      final notifier = DiaryHistoryNotifier(_FakeDiaryApi(
        fetchDiaryHistoryHandler: ({
          required int page,
          required int limit,
          DateTime? startDate,
          DateTime? endDate,
        }) async {
          return DiaryHistoryResponse(
            items: [_historyItem('diary-$page')],
            pagination: DiaryHistoryPagination(
              page: page,
              limit: limit,
              totalItems: 2,
              totalPages: 2,
            ),
          );
        },
      ));

      await notifier.loadDiaryHistory();
      await notifier.loadNextPage();

      expect(notifier.state.items, hasLength(2));
      expect(notifier.state.items.first.diaryId, 'diary-1');
      expect(notifier.state.items.last.diaryId, 'diary-2');
    });

    test('does not load next page when already at last page', () async {
      final api = _FakeDiaryApi(
        fetchDiaryHistoryHandler: ({
          required int page,
          required int limit,
          DateTime? startDate,
          DateTime? endDate,
        }) async {
          return DiaryHistoryResponse(
            items: [_historyItem('diary-1')],
            pagination: const DiaryHistoryPagination(
              page: 1,
              limit: 10,
              totalItems: 1,
              totalPages: 1,
            ),
          );
        },
      );
      final notifier = DiaryHistoryNotifier(api);

      await notifier.loadDiaryHistory();
      await notifier.loadNextPage();

      expect(api.fetchDiaryHistoryCalls, 1);
      expect(notifier.state.items, hasLength(1));
    });

    test('stores error when history request fails', () async {
      final notifier = DiaryHistoryNotifier(_FakeDiaryApi(
        fetchDiaryHistoryHandler: ({
          required int page,
          required int limit,
          DateTime? startDate,
          DateTime? endDate,
        }) async {
          throw Exception('Riwayat gagal dimuat');
        },
      ));

      await notifier.loadDiaryHistory();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, 'Riwayat gagal dimuat');
      expect(notifier.state.errorCause, isA<Exception>());
      expect(notifier.state.items, isEmpty);
    });

    test('loads diary detail and merges sleep data', () async {
      final diaryDate = DateTime(2026, 6, 28);
      final notifier = DiaryHistoryNotifier(_FakeDiaryApi(
        fetchDiaryDetailHandler: (date) async => _diaryDetail('diary-1', date),
        fetchSleepDiaryByDateHandler: (date) async => {
          'sleepRecordId': 'sleep-1',
          'sleepTime': '22:00',
          'wakeTime': '06:00',
          'sleepDurationHours': 8,
          'source': 'app_manual',
        },
      ));

      await notifier.loadDiaryDetail(diaryDate);

      final detail = notifier.state.detailsByDiaryId[diaryDate];
      expect(detail, isNotNull);
      expect(detail!.diaryId, 'diary-1');
      expect(detail.sleeps.single.sleepRecordId, 'sleep-1');
      expect(notifier.state.loadingDetailDiaryIds, isNot(contains(diaryDate)));
      expect(notifier.state.detailErrorsByDiaryId, isEmpty);
    });

    test('skips detail request when detail is already cached', () async {
      final diaryDate = DateTime(2026, 6, 28);
      final api = _FakeDiaryApi(
        fetchDiaryDetailHandler: (date) async => _diaryDetail('diary-1', date),
      );
      final notifier = DiaryHistoryNotifier(api);

      await notifier.loadDiaryDetail(diaryDate);
      await notifier.loadDiaryDetail(diaryDate);

      expect(api.fetchDiaryDetailCalls, 1);
    });

    test('stores detail error when detail request fails', () async {
      final diaryDate = DateTime(2026, 6, 28);
      final notifier = DiaryHistoryNotifier(_FakeDiaryApi(
        fetchDiaryDetailHandler: (date) async {
          throw Exception('Detail diary gagal');
        },
      ));

      await notifier.loadDiaryDetail(diaryDate);

      expect(notifier.state.detailsByDiaryId, isEmpty);
      expect(notifier.state.loadingDetailDiaryIds, isNot(contains(diaryDate)));
      expect(
        notifier.state.detailErrorsByDiaryId[diaryDate],
        'Detail diary gagal',
      );
      expect(
        notifier.state.detailErrorCausesByDiaryId[diaryDate],
        isA<Exception>(),
      );
    });

    test('saveMyNoteForDate upserts current user note and refreshes detail',
        () async {
      final diaryDate = DateTime(2026, 6, 28);
      late DateTime observedDate;
      late String observedContent;
      final api = _FakeDiaryApi(
        fetchDiaryDetailHandler: (date) async => _diaryDetail('diary-1', date),
        upsertCurrentNoteHandler: (date, content) async {
          observedDate = date;
          observedContent = content;
          return _note(content);
        },
      );
      final notifier = DiaryHistoryNotifier(api);

      await notifier.loadDiaryDetail(diaryDate);
      await notifier.saveMyNoteForDate(diaryDate, '  kondisi membaik  ');

      expect(observedDate, diaryDate);
      expect(observedContent, 'kondisi membaik');
      expect(api.fetchDiaryDetailCalls, 2);
      expect(notifier.state.detailsByDiaryId[diaryDate], isNotNull);
    });

    test('saveMyNoteForDate deletes current user note when content is empty',
        () async {
      final diaryDate = DateTime(2026, 6, 28);
      late DateTime observedDate;
      final api = _FakeDiaryApi(
        fetchDiaryDetailHandler: (date) async => _diaryDetail('diary-1', date),
        deleteCurrentNoteHandler: (date) async {
          observedDate = date;
          return true;
        },
      );
      final notifier = DiaryHistoryNotifier(api);

      await notifier.loadDiaryDetail(diaryDate);
      await notifier.saveMyNoteForDate(diaryDate, '   ');

      expect(observedDate, diaryDate);
      expect(api.fetchDiaryDetailCalls, 2);
    });

    test('clearCache resets state to initial values', () async {
      final notifier = DiaryHistoryNotifier(_FakeDiaryApi(
        fetchDiaryHistoryHandler: ({
          required int page,
          required int limit,
          DateTime? startDate,
          DateTime? endDate,
        }) async {
          return DiaryHistoryResponse(
            items: [_historyItem('diary-1')],
            pagination: const DiaryHistoryPagination(
              page: 1,
              limit: 10,
              totalItems: 1,
              totalPages: 1,
            ),
          );
        },
      ));

      await notifier.loadDiaryHistory();
      notifier.clearCache();

      expect(notifier.state.items, isEmpty);
      expect(notifier.state.page, 1);
      expect(notifier.state.totalItems, 0);
      expect(notifier.state.detailsByDiaryId, isEmpty);
    });
  });
}

typedef _FetchDiaryHistoryHandler = Future<DiaryHistoryResponse> Function({
  required int page,
  required int limit,
  DateTime? startDate,
  DateTime? endDate,
});

class _FakeDiaryApi extends DiaryApi {
  _FakeDiaryApi({
    this.fetchDiaryHistoryHandler,
    this.fetchDiaryDetailHandler,
    this.fetchSleepDiaryByDateHandler,
    this.upsertCurrentNoteHandler,
    this.deleteCurrentNoteHandler,
  }) : super(Dio());

  final _FetchDiaryHistoryHandler? fetchDiaryHistoryHandler;
  final Future<DiaryDetail> Function(DateTime date)? fetchDiaryDetailHandler;
  final Future<Map<String, dynamic>?> Function(DateTime date)?
      fetchSleepDiaryByDateHandler;
  final Future<DiaryNote> Function(DateTime date, String content)?
      upsertCurrentNoteHandler;
  final Future<bool> Function(DateTime date)? deleteCurrentNoteHandler;

  int fetchDiaryHistoryCalls = 0;
  int fetchDiaryDetailCalls = 0;

  @override
  Future<DiaryHistoryResponse> fetchDiaryHistory({
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    fetchDiaryHistoryCalls++;
    final handler = fetchDiaryHistoryHandler;
    if (handler != null) {
      return handler(
        page: page,
        limit: limit,
        startDate: startDate,
        endDate: endDate,
      );
    }
    return DiaryHistoryResponse(
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
  Future<DiaryDetail> fetchDiaryDetail(DateTime diaryDate) async {
    fetchDiaryDetailCalls++;
    final handler = fetchDiaryDetailHandler;
    if (handler != null) {
      return handler(diaryDate);
    }
    return _diaryDetail('diary-1', diaryDate);
  }

  @override
  Future<Map<String, dynamic>?> fetchSleepDiaryByDate(DateTime date) async {
    final handler = fetchSleepDiaryByDateHandler;
    if (handler != null) {
      return handler(date);
    }
    return null;
  }

  @override
  Future<DiaryNote> upsertMyDiaryNoteForCurrentUserByDate({
    required DateTime date,
    required String content,
  }) async {
    final handler = upsertCurrentNoteHandler;
    if (handler != null) {
      return handler(date, content);
    }
    return _note(content);
  }

  @override
  Future<bool> deleteMyDiaryNoteForCurrentUserByDate(DateTime date) async {
    final handler = deleteCurrentNoteHandler;
    if (handler != null) {
      return handler(date);
    }
    return true;
  }
}

DiaryHistoryItem _historyItem(String diaryId) {
  return DiaryHistoryItem(
    diaryId: diaryId,
    userId: 'user-1',
    diaryDate: DateTime(2026, 6, 28),
    createdAt: DateTime(2026, 6, 28, 8),
  );
}

DiaryDetail _diaryDetail(String diaryId, DateTime diaryDate) {
  return DiaryDetail(
    diaryId: diaryId,
    userId: 'user-1',
    diaryDate: diaryDate,
    createdAt: DateTime(2026, 6, 28, 8),
    heartRate: 72,
    bodyMetrics: const [],
    symptoms: const [],
    activities: const [],
    consumptions: const [],
    sleeps: const [],
  );
}

DiaryNote _note(String content) {
  return DiaryNote(
    noteId: 'note-1',
    diaryId: 'diary-1',
    authorUserId: 'user-1',
    authorRole: 'patient',
    authorName: 'Pasien',
    content: content,
    createdAt: DateTime(2026, 6, 28, 8),
    updatedAt: DateTime(2026, 6, 28, 9),
  );
}
