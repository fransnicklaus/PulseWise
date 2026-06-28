import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/diary/data/models/diary_models.dart';

void main() {
  group('DiaryDetail', () {
    test('parses full diary detail with nested sections', () {
      final detail = DiaryDetail.fromJson({
        'diaryId': 'diary-1',
        'userId': 'user-1',
        'diaryDate': '2026-06-28T00:00:00.000Z',
        'createdAt': '2026-06-28T08:00:00.000Z',
        'heartRate': 72,
        'latestHeartRate': 74,
        'latestHeartRateMeasuredAt': '2026-06-28T09:00:00.000Z',
        'latestOxygenSaturation': 98,
        'latestOxygenSaturationMeasuredAt': '2026-06-28T09:05:00.000Z',
        'bodyMetrics': [
          {
            'metricId': 'metric-1',
            'conditionTag': 'morning',
            'bodyHeight': 170,
            'bodyWeight': 65.5,
            'bmi': 22.7,
            'heartRate': 72,
            'latestHeartRate': 74,
            'latestHeartRateMeasuredAt': '2026-06-28T09:00:00.000Z',
            'latestOxygenSaturation': 98,
            'latestOxygenSaturationMeasuredAt': '2026-06-28T09:05:00.000Z',
            'systolicPressure': 120,
            'diastolicPressure': 80,
            'timeStamp': '2026-06-28T09:10:00.000Z',
          },
        ],
        'symptoms': [
          {
            'symptomId': 'symptom-1',
            'symptomName': 'Pusing',
            'intensity': 2,
            'note': 'Ringan',
            'timeStamp': '2026-06-28T10:00:00.000Z',
          },
        ],
        'activities': [
          {
            'activityId': 'activity-1',
            'name': 'Jalan pagi',
            'duration': 30,
            'heartRate': 90,
            'userFeeling': 'Baik',
            'note': 'Santai',
            'timeStamp': '2026-06-28T06:30:00.000Z',
          },
        ],
        'consumptions': [
          {
            'consumptionId': 'consumption-1',
            'type': 'breakfast',
            'name': 'Oatmeal',
            'portion': '1 bowl',
            'note': 'Tanpa gula',
            'timeStamp': '2026-06-28T07:00:00.000Z',
          },
        ],
        'sleeps': [
          {
            'sleepRecordId': 'sleep-1',
            'sleepTime': '22:00',
            'wakeTime': '05:30',
            'sleepDurationHours': 7.5,
            'source': 'app_manual',
          },
        ],
      });

      expect(detail.diaryId, 'diary-1');
      expect(detail.userId, 'user-1');
      expect(detail.diaryDate, DateTime.parse('2026-06-28T00:00:00.000Z'));
      expect(detail.latestHeartRate, 74);
      expect(detail.latestOxygenSaturation, 98);
      expect(detail.bodyMetrics.single.metricId, 'metric-1');
      expect(detail.bodyMetrics.single.latestOxygenSaturation, 98);
      expect(detail.symptoms.single.symptomName, 'Pusing');
      expect(detail.activities.single.name, 'Jalan pagi');
      expect(detail.consumptions.single.name, 'Oatmeal');
      expect(detail.sleeps.single.sleepDurationHours, 7.5);
    });

    test('uses empty defaults for optional nested lists and invalid dates', () {
      final detail = DiaryDetail.fromJson({
        'diaryId': null,
        'userId': null,
        'diaryDate': 'not-a-date',
        'createdAt': null,
        'heartRate': null,
      });

      expect(detail.diaryId, '');
      expect(detail.userId, '');
      expect(detail.diaryDate, isNull);
      expect(detail.createdAt, isNull);
      expect(detail.bodyMetrics, isEmpty);
      expect(detail.symptoms, isEmpty);
      expect(detail.activities, isEmpty);
      expect(detail.consumptions, isEmpty);
      expect(detail.sleeps, isEmpty);
    });

    test('copyWith replaces provided fields and preserves others', () {
      final original = _diaryDetail('diary-1');
      final updated = original.copyWith(
        diaryId: 'diary-2',
        latestHeartRate: 80,
        sleeps: const [
          DiarySleep(
            sleepRecordId: 'sleep-1',
            sleepTime: '22:00',
            wakeTime: '06:00',
            sleepDurationHours: 8,
            source: 'app_manual',
          ),
        ],
      );

      expect(updated.diaryId, 'diary-2');
      expect(updated.userId, original.userId);
      expect(updated.latestHeartRate, 80);
      expect(updated.sleeps.single.sleepRecordId, 'sleep-1');
    });
  });

  group('DiaryHistoryResponse', () {
    test('parses history items and pagination', () {
      final response = DiaryHistoryResponse.fromJson({
        'items': [
          {
            'diaryId': 'diary-1',
            'userId': 'user-1',
            'diaryDate': '2026-06-28T00:00:00.000Z',
            'createdAt': '2026-06-28T08:00:00.000Z',
          },
        ],
        'pagination': {
          'page': 2,
          'limit': 5,
          'totalItems': 9,
          'totalPages': 2,
        },
      });

      expect(response.items.single.diaryId, 'diary-1');
      expect(response.items.single.diaryDate,
          DateTime.parse('2026-06-28T00:00:00.000Z'));
      expect(response.pagination.page, 2);
      expect(response.pagination.limit, 5);
      expect(response.pagination.totalItems, 9);
      expect(response.pagination.totalPages, 2);
    });

    test('uses pagination defaults when payload is empty', () {
      final response = DiaryHistoryResponse.fromJson({});

      expect(response.items, isEmpty);
      expect(response.pagination.page, 1);
      expect(response.pagination.limit, 10);
      expect(response.pagination.totalItems, 0);
      expect(response.pagination.totalPages, 1);
    });
  });
}

DiaryDetail _diaryDetail(String diaryId) {
  return DiaryDetail(
    diaryId: diaryId,
    userId: 'user-1',
    diaryDate: DateTime.parse('2026-06-28T00:00:00.000Z'),
    createdAt: DateTime.parse('2026-06-28T08:00:00.000Z'),
    heartRate: 72,
    bodyMetrics: const [],
    symptoms: const [],
    activities: const [],
    consumptions: const [],
    sleeps: const [],
  );
}
