import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/diary/data/datasources/diary_api.dart';
import 'package:pulsewise/features/diary/data/models/diary_models.dart';
import 'package:pulsewise/features/diary/presentation/providers/current_diary_provider.dart';

void main() {
  group('CurrentDiaryNotifier', () {
    test('loads current diary and merges sleep data', () async {
      final notifier = CurrentDiaryNotifier(_FakeDiaryApi(
        fetchDiaryDetailByDateHandler: (date) async => _diaryDetail('diary-1'),
        fetchSleepDiaryByDateHandler: (date) async => {
          'sleepRecordId': 'sleep-1',
          'sleepTime': '22:00',
          'wakeTime': '06:00',
          'sleepDurationHours': 8,
          'source': 'app_manual',
        },
      ));

      await notifier.loadCurrentDiaryForToday();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.hasLoadedOnce, isTrue);
      expect(notifier.state.hasCurrentDiary, isTrue);
      expect(notifier.state.diaryId, 'diary-1');
      expect(notifier.state.diary!.sleeps.single.sleepRecordId, 'sleep-1');
      expect(notifier.state.error, isNull);
    });

    test('creates sleep-only diary state when diary detail is absent',
        () async {
      final notifier = CurrentDiaryNotifier(_FakeDiaryApi(
        fetchDiaryDetailByDateHandler: (date) async => null,
        fetchSleepDiaryByDateHandler: (date) async => {
          'sleepRecordId': 'sleep-1',
          'sleepTime': '22:00',
          'wakeTime': '06:00',
          'sleepDurationHours': 8,
        },
      ));

      await notifier.loadCurrentDiaryForToday();

      expect(notifier.state.hasLoadedOnce, isTrue);
      expect(notifier.state.hasCurrentDiary, isTrue);
      expect(notifier.state.diary, isNotNull);
      expect(notifier.state.diary!.sleeps.single.sleepRecordId, 'sleep-1');
    });

    test('marks no current diary when detail and sleep are absent', () async {
      final notifier = CurrentDiaryNotifier(_FakeDiaryApi(
        fetchDiaryDetailByDateHandler: (date) async => null,
      ));

      await notifier.loadCurrentDiaryForToday();

      expect(notifier.state.hasLoadedOnce, isTrue);
      expect(notifier.state.hasCurrentDiary, isFalse);
      expect(notifier.state.diary, isNull);
      expect(notifier.state.error, isNull);
    });

    test('treats not found error as no current diary', () async {
      final notifier = CurrentDiaryNotifier(_FakeDiaryApi(
        fetchDiaryDetailByDateHandler: (date) async {
          throw Exception('not found');
        },
      ));

      await notifier.loadCurrentDiaryForToday();

      expect(notifier.state.hasLoadedOnce, isTrue);
      expect(notifier.state.hasCurrentDiary, isFalse);
      expect(notifier.state.error, isNull);
      expect(notifier.state.errorCause, isNull);
    });

    test('stores non-404 load errors', () async {
      final notifier = CurrentDiaryNotifier(_FakeDiaryApi(
        fetchDiaryDetailByDateHandler: (date) async {
          throw Exception('Server diary gagal');
        },
      ));

      await notifier.loadCurrentDiaryForToday();

      expect(notifier.state.hasLoadedOnce, isTrue);
      expect(notifier.state.hasCurrentDiary, isFalse);
      expect(notifier.state.error, contains('Server diary gagal'));
      expect(notifier.state.errorCause, isA<Exception>());
    });

    test('ensureCurrentDiaryLoaded only loads once', () async {
      final api = _FakeDiaryApi(
        fetchDiaryDetailByDateHandler: (date) async => _diaryDetail('diary-1'),
      );
      final notifier = CurrentDiaryNotifier(api);

      await notifier.ensureCurrentDiaryLoaded();
      await notifier.ensureCurrentDiaryLoaded();

      expect(api.fetchDiaryDetailByDateCalls, 1);
    });

    test('addSleepFromModal maps payload and validates required time fields',
        () async {
      final api = _FakeDiaryApi();
      final notifier = CurrentDiaryNotifier(api);

      await notifier.addSleepFromModal({
        'sleepTime': '22:00',
        'wakeTime': '06:00',
        'duration': '8',
      });

      expect(api.addDiarySleepByDateCalls, 1);
      expect(api.lastSleepPayload!['sleepTime'], '22:00');
      expect(api.lastSleepPayload!['wakeTime'], '06:00');
      expect(api.lastSleepPayload!['sleepDurationHours'], 8.0);

      expect(
        () => notifier.addSleepFromModal({'sleepTime': '', 'wakeTime': ''}),
        throwsA(isA<Exception>()),
      );
    });

    test('addSymptomsFromModal maps each symptom and chest pain fields',
        () async {
      final api = _FakeDiaryApi();
      final notifier = CurrentDiaryNotifier(api);

      await notifier.addSymptomsFromModal({
        'time': '09:00',
        'intensity': '3',
        'description': 'Nyeri dada ringan',
        'symptomsMapped': [
          {
            'symptomName': 'Nyeri dada',
            'symptomCode': 'chest_pain',
            'bodyArea': 'chest',
            'isChestPain': true,
            'painFrequencyCode': '2',
            'painLocationCode': 5,
          },
          {
            'symptomName': 'Pusing',
            'symptomCode': 'dizzy',
            'bodyArea': 'head',
            'isChestPain': false,
            'painFrequencyCode': 2,
            'painLocationCode': 5,
          },
        ],
      });

      expect(api.addDiarySymptomByDateCalls, 2);
      expect(api.symptomPayloads.first['intensity'], 3);
      expect(api.symptomPayloads.first['painFrequencyCode'], 2);
      expect(api.symptomPayloads.first['painLocationCode'], 5);
      expect(api.symptomPayloads.last['painFrequencyCode'], isNull);
      expect(api.symptomPayloads.last['painLocationCode'], isNull);
    });

    test('addConsumptionsFromModal skips incomplete payload and maps nutrition',
        () async {
      final api = _FakeDiaryApi();
      final notifier = CurrentDiaryNotifier(api);

      await notifier.addConsumptionsFromModal({
        'type': 'breakfast',
        'name': '',
        'portion': '1 bowl',
      });
      expect(api.addDiaryConsumptionByDateCalls, 0);

      await notifier.addConsumptionsFromModal({
        'type': 'breakfast',
        'name': 'Oatmeal',
        'portion': '1 bowl',
        'time': '07:00',
        'note': 'Tanpa gula',
        'nutritionPayload': {
          'calories': 320,
          'protein': '12',
        },
      });

      expect(api.addDiaryConsumptionByDateCalls, 1);
      expect(api.lastConsumptionPayload!['type'], 'breakfast');
      expect(api.lastConsumptionPayload!['name'], 'Oatmeal');
      expect(api.lastConsumptionPayload!['nutritionPayload'], {
        'calories': 320,
        'protein': '12',
      });
    });

    test('addActivitiesFromModal calculates overnight duration', () async {
      final api = _FakeDiaryApi();
      final notifier = CurrentDiaryNotifier(api);

      await notifier.addActivitiesFromModal({
        'activity': 'Jalan malam',
        'startTime': '23:30',
        'endTime': '00:15',
        'heartRate': '92',
        'feeling': 'Baik',
        'activityCategory': 'recreation',
      });

      expect(api.addDiaryActivityByDateCalls, 1);
      expect(api.lastActivityPayload!['name'], 'Jalan malam');
      expect(api.lastActivityPayload!['duration'], 45);
      expect(api.lastActivityPayload!['heartRate'], 92);
      expect(api.lastActivityPayload!['userFeeling'], 'Baik');
    });

    test('addActivitiesFromModal throws when required data is incomplete',
        () async {
      final notifier = CurrentDiaryNotifier(_FakeDiaryApi());

      expect(
        () => notifier.addActivitiesFromModal({'name': '', 'duration': 0}),
        throwsA(isA<Exception>()),
      );
    });

    test('addBodyMetricsFromModal maps numeric fields and validates payload',
        () async {
      final api = _FakeDiaryApi();
      final notifier = CurrentDiaryNotifier(api);

      await notifier.addBodyMetricsFromModal({
        'conditionTag': 'evening',
        'timeStamp': '2026-06-28T12:00:00.000Z',
        'bodyHeight': '170.5',
        'bodyWeight': 65,
        'bmi': '22.3',
        'systolicPressure': '120',
        'diastolicPressure': 80,
        'heartRate': '72',
        'oxygenSaturation': 98,
      });

      expect(api.updateDiaryBodyMetricsByDateCalls, 1);
      expect(api.lastBodyMetricsPayload!['conditionTag'], 'evening');
      expect(api.lastBodyMetricsPayload!['bodyHeight'], 170.5);
      expect(api.lastBodyMetricsPayload!['bodyWeight'], 65.0);
      expect(api.lastBodyMetricsPayload!['systolicPressure'], 120);
      expect(api.lastBodyMetricsPayload!['oxygenSaturation'], 98);

      expect(
        () => notifier.addBodyMetricsFromModal({}),
        throwsA(isA<Exception>()),
      );
    });
  });
}

class _FakeDiaryApi extends DiaryApi {
  _FakeDiaryApi({
    this.fetchDiaryDetailByDateHandler,
    this.fetchSleepDiaryByDateHandler,
  }) : super(Dio());

  final Future<DiaryDetail?> Function(DateTime date)?
      fetchDiaryDetailByDateHandler;
  final Future<Map<String, dynamic>?> Function(DateTime date)?
      fetchSleepDiaryByDateHandler;

  int fetchDiaryDetailByDateCalls = 0;
  int addDiarySleepByDateCalls = 0;
  int addDiarySymptomByDateCalls = 0;
  int addDiaryConsumptionByDateCalls = 0;
  int addDiaryActivityByDateCalls = 0;
  int updateDiaryBodyMetricsByDateCalls = 0;

  Map<String, dynamic>? lastSleepPayload;
  final List<Map<String, dynamic>> symptomPayloads = [];
  Map<String, dynamic>? lastConsumptionPayload;
  Map<String, dynamic>? lastActivityPayload;
  Map<String, dynamic>? lastBodyMetricsPayload;

  @override
  Future<DiaryDetail?> fetchDiaryDetailByDate(DateTime date) async {
    fetchDiaryDetailByDateCalls++;
    final handler = fetchDiaryDetailByDateHandler;
    if (handler != null) {
      return handler(date);
    }
    return null;
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
  Future<void> addDiarySleepByDate({
    required String diaryDate,
    required String sleepTime,
    required String wakeTime,
    required num sleepDurationHours,
  }) async {
    addDiarySleepByDateCalls++;
    lastSleepPayload = {
      'diaryDate': diaryDate,
      'sleepTime': sleepTime,
      'wakeTime': wakeTime,
      'sleepDurationHours': sleepDurationHours,
    };
  }

  @override
  Future<void> addDiarySymptomByDate({
    required String diaryDate,
    required String symptomName,
    required String symptomCode,
    required String bodyArea,
    required bool isChestPain,
    int? painFrequencyCode,
    int? painLocationCode,
    required int intensity,
    required String time,
    required String note,
  }) async {
    addDiarySymptomByDateCalls++;
    symptomPayloads.add({
      'diaryDate': diaryDate,
      'symptomName': symptomName,
      'symptomCode': symptomCode,
      'bodyArea': bodyArea,
      'isChestPain': isChestPain,
      'painFrequencyCode': painFrequencyCode,
      'painLocationCode': painLocationCode,
      'intensity': intensity,
      'time': time,
      'note': note,
    });
  }

  @override
  Future<void> addDiaryConsumptionByDate({
    required String diaryDate,
    required String type,
    required String name,
    required String portion,
    required String time,
    required String note,
    Map<String, dynamic>? nutritionPayload,
  }) async {
    addDiaryConsumptionByDateCalls++;
    lastConsumptionPayload = {
      'diaryDate': diaryDate,
      'type': type,
      'name': name,
      'portion': portion,
      'time': time,
      'note': note,
      'nutritionPayload': nutritionPayload,
    };
  }

  @override
  Future<void> addDiaryActivityByDate({
    required String diaryDate,
    required String name,
    required String activityCategory,
    String? intensityLevel,
    String? transportMode,
    int? outdoorMinutes,
    required int duration,
    int? heartRate,
    String? userFeeling,
    String? note,
  }) async {
    addDiaryActivityByDateCalls++;
    lastActivityPayload = {
      'diaryDate': diaryDate,
      'name': name,
      'activityCategory': activityCategory,
      'intensityLevel': intensityLevel,
      'transportMode': transportMode,
      'outdoorMinutes': outdoorMinutes,
      'duration': duration,
      'heartRate': heartRate,
      'userFeeling': userFeeling,
      'note': note,
    };
  }

  @override
  Future<void> updateDiaryBodyMetricsByDate({
    required String diaryDate,
    required String conditionTag,
    required String timeStamp,
    double? bodyHeight,
    double? bodyWeight,
    double? bmi,
    int? systolicPressure,
    int? diastolicPressure,
    int? heartRate,
    int? oxygenSaturation,
  }) async {
    updateDiaryBodyMetricsByDateCalls++;
    lastBodyMetricsPayload = {
      'diaryDate': diaryDate,
      'conditionTag': conditionTag,
      'timeStamp': timeStamp,
      'bodyHeight': bodyHeight,
      'bodyWeight': bodyWeight,
      'bmi': bmi,
      'systolicPressure': systolicPressure,
      'diastolicPressure': diastolicPressure,
      'heartRate': heartRate,
      'oxygenSaturation': oxygenSaturation,
    };
  }
}

DiaryDetail _diaryDetail(String diaryId) {
  return DiaryDetail(
    diaryId: diaryId,
    userId: 'user-1',
    diaryDate: DateTime(2026, 6, 28),
    createdAt: DateTime(2026, 6, 28, 8),
    heartRate: 72,
    bodyMetrics: const [],
    symptoms: const [],
    activities: const [],
    consumptions: const [],
    sleeps: const [],
  );
}
