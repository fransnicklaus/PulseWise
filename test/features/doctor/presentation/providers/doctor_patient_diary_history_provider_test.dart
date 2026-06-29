import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/diary/data/datasources/diary_api.dart';
import 'package:pulsewise/features/diary/data/models/diary_models.dart';
import 'package:pulsewise/features/doctor/presentation/providers/doctor_patient_diary_history_provider.dart';

void main() {
  group('DoctorPatientDiaryHistoryNotifier', () {
    test('loads diary history for selected patient and stores pagination',
        () async {
      late String observedPatientId;
      final notifier = DoctorPatientDiaryHistoryNotifier(
        _FakeDiaryApi(
          fetchHistoryForUserHandler: (
            patientId, {
            required int page,
            required int limit,
            DateTime? startDate,
            DateTime? endDate,
          }) async {
            observedPatientId = patientId;
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
        ),
        'patient-1',
      );

      await notifier.loadDiaryHistory(limit: 5);

      expect(observedPatientId, 'patient-1');
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
      expect(notifier.state.items.single.diaryId, 'diary-1');
      expect(notifier.state.limit, 5);
      expect(notifier.state.totalItems, 1);
    });

    test('loads detail for selected patient and merges optional sleep data',
        () async {
      final diaryDate = DateTime(2026, 6, 29);
      final notifier = DoctorPatientDiaryHistoryNotifier(
        _FakeDiaryApi(
          fetchDetailForUserHandler: (patientId, date) async {
            return _diaryDetail('diary-1', date);
          },
          fetchSleepForUserHandler: (patientId, date) async {
            return {
              'sleepRecordId': 'sleep-1',
              'sleepTime': '22:00',
              'wakeTime': '06:00',
              'sleepDurationHours': 8,
              'source': 'app_manual',
            };
          },
        ),
        'patient-1',
      );

      await notifier.loadDiaryDetail(diaryDate);

      final detail = notifier.state.detailsByDiaryId[diaryDate];
      expect(detail, isNotNull);
      expect(detail!.diaryId, 'diary-1');
      expect(detail.sleeps.single.sleepRecordId, 'sleep-1');
      expect(notifier.state.loadingDetailDiaryIds, isNot(contains(diaryDate)));
      expect(notifier.state.detailErrorsByDiaryId, isEmpty);
    });
  });
}

typedef _FetchHistoryForUserHandler = Future<DiaryHistoryResponse> Function(
  String patientId, {
  required int page,
  required int limit,
  DateTime? startDate,
  DateTime? endDate,
});

class _FakeDiaryApi extends DiaryApi {
  _FakeDiaryApi({
    this.fetchHistoryForUserHandler,
    this.fetchDetailForUserHandler,
    this.fetchSleepForUserHandler,
  }) : super(Dio());

  final _FetchHistoryForUserHandler? fetchHistoryForUserHandler;
  final Future<DiaryDetail> Function(String patientId, DateTime date)?
      fetchDetailForUserHandler;
  final Future<Map<String, dynamic>?> Function(String patientId, DateTime date)?
      fetchSleepForUserHandler;

  @override
  Future<DiaryHistoryResponse> fetchDiaryHistoryForUser(
    String patientId, {
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final handler = fetchHistoryForUserHandler;
    if (handler != null) {
      return handler(
        patientId,
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
  Future<DiaryDetail> fetchDiaryDetailForUser(
    String patientId,
    DateTime diaryDate,
  ) async {
    final handler = fetchDetailForUserHandler;
    if (handler != null) {
      return handler(patientId, diaryDate);
    }
    return _diaryDetail('diary-1', diaryDate);
  }

  @override
  Future<Map<String, dynamic>?> fetchSleepDiaryByDateForUser(
    String userId,
    DateTime date,
  ) async {
    final handler = fetchSleepForUserHandler;
    if (handler != null) {
      return handler(userId, date);
    }
    return null;
  }
}

DiaryHistoryItem _historyItem(String diaryId) {
  return DiaryHistoryItem(
    diaryId: diaryId,
    userId: 'patient-1',
    diaryDate: DateTime(2026, 6, 29),
    createdAt: DateTime(2026, 6, 29, 8),
  );
}

DiaryDetail _diaryDetail(String diaryId, DateTime diaryDate) {
  return DiaryDetail(
    diaryId: diaryId,
    userId: 'patient-1',
    diaryDate: diaryDate,
    createdAt: DateTime(2026, 6, 29, 8),
    heartRate: 72,
    bodyMetrics: const [],
    symptoms: const [],
    activities: const [],
    consumptions: const [],
    sleeps: const [],
  );
}
