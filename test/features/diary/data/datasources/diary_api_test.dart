import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/diary/data/datasources/diary_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      AppSessionStore.tokenPrefsKey: 'diary-token',
      AppSessionStore.userIdPrefsKey: 'patient-1',
    });
  });

  group('DiaryApi', () {
    test('fetchDiaryDetailByDate sends date query and parses detail', () async {
      late RequestOptions observedOptions;
      final api = DiaryApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return _successResponse(_diaryJson('diary-1'));
        },
      )));

      final detail = await api.fetchDiaryDetailByDate(DateTime(2026, 6, 29));

      expect(observedOptions.method, 'GET');
      expect(observedOptions.path, '/users/patient-1/diaries/by-date');
      expect(observedOptions.queryParameters, {'date': '2026-06-29'});
      expect(observedOptions.headers['Authorization'], 'Bearer diary-token');
      expect(detail!.diaryId, 'diary-1');
    });

    test('fetchDiaryDetailByDate returns null on not found or null data',
        () async {
      var calls = 0;
      final api = DiaryApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) {
          calls++;
          if (calls == 1) {
            return const _FakeDioResponse({
              'success': true,
              'data': null,
            });
          }
          return const _FakeDioResponse(
            {'success': false, 'message': 'Diary tidak ada'},
            statusCode: 404,
          );
        },
      )));

      final nullData = await api.fetchDiaryDetailByDate(DateTime(2026, 6, 29));
      final notFound = await api.fetchDiaryDetailByDate(DateTime(2026, 6, 30));

      expect(nullData, isNull);
      expect(notFound, isNull);
    });

    test('fetchDiaryHistoryForUser sends pagination and date filters',
        () async {
      late RequestOptions observedOptions;
      final api = DiaryApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return _successResponse({
            'items': [_diaryJson('diary-1')],
            'pagination': {
              'page': 2,
              'limit': 5,
              'totalItems': 6,
              'totalPages': 2,
            },
          });
        },
      )));

      final history = await api.fetchDiaryHistoryForUser(
        'patient-2',
        page: 2,
        limit: 5,
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 6, 29),
      );

      expect(observedOptions.path, '/users/patient-2/diaries');
      expect(observedOptions.queryParameters, {
        'page': 2,
        'limit': 5,
        'startDate': '2026-06-01',
        'endDate': '2026-06-29',
      });
      expect(history.items.single.diaryId, 'diary-1');
      expect(history.pagination.totalPages, 2);
    });

    test('fetchSleepDiaryByDateForUser returns sleep data or null', () async {
      var calls = 0;
      final api = DiaryApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) {
          calls++;
          if (calls == 1) {
            return const _FakeDioResponse({
              'success': true,
              'data': {
                'sleepTime': '22:00',
              },
            });
          }
          return const _FakeDioResponse(
            {'success': false, 'message': 'Sleep tidak ada'},
            statusCode: 404,
          );
        },
      )));

      final sleep = await api.fetchSleepDiaryByDateForUser(
        'patient-1',
        DateTime(2026, 6, 29),
      );
      final missing = await api.fetchSleepDiaryByDateForUser(
        'patient-1',
        DateTime(2026, 6, 30),
      );

      expect(sleep, {'sleepTime': '22:00'});
      expect(missing, isNull);
    });

    test('add diary section methods send expected payloads', () async {
      final observed = <RequestOptions>[];
      final api = DiaryApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observed.add(options);
          return _successResponse({});
        },
      )));

      await api.addDiarySleepByDate(
        diaryDate: '2026-06-29',
        sleepTime: '22:00',
        wakeTime: '06:00',
        sleepDurationHours: 8,
      );
      await api.addDiarySymptomByDate(
        diaryDate: '2026-06-29',
        symptomName: 'Pusing',
        symptomCode: 'headache',
        bodyArea: 'head',
        isChestPain: false,
        intensity: 2,
        time: '09:00',
        note: 'Ringan',
      );
      await api.addDiaryConsumptionByDate(
        diaryDate: '2026-06-29',
        type: 'breakfast',
        name: 'Oatmeal',
        portion: '1 bowl',
        time: '07:00',
        note: 'Less sugar',
        nutritionPayload: {
          'energyKcal': 220,
          'proteinG': '',
          'fiberG': null,
        },
      );

      expect(observed[0].method, 'PUT');
      expect(observed[0].path, '/users/patient-1/diaries/by-date/sleep');
      expect(observed[0].data, {
        'diaryDate': '2026-06-29',
        'sleepTime': '22:00',
        'wakeTime': '06:00',
        'sleepDurationHours': 8,
        'source': 'app_manual',
      });
      expect(observed[1].method, 'POST');
      expect(observed[1].path, '/users/patient-1/diaries/by-date/symptoms');
      expect((observed[1].data as Map)['symptomCode'], 'headache');
      expect(observed[2].method, 'POST');
      expect(
        observed[2].path,
        '/users/patient-1/diaries/by-date/consumptions',
      );
      expect(observed[2].data, {
        'diaryDate': '2026-06-29',
        'type': 'breakfast',
        'name': 'Oatmeal',
        'portion': '1 bowl',
        'time': '07:00',
        'note': 'Less sugar',
        'energyKcal': 220,
      });
    });

    test('activity and body metrics methods omit null optional fields',
        () async {
      final observed = <RequestOptions>[];
      final api = DiaryApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observed.add(options);
          return _successResponse({});
        },
      )));

      await api.addDiaryActivityByDate(
        diaryDate: '2026-06-29',
        name: 'Walk',
        activityCategory: 'exercise',
        duration: 30,
        heartRate: 90,
      );
      await api.updateDiaryBodyMetricsByDate(
        diaryDate: '2026-06-29',
        conditionTag: 'morning',
        timeStamp: '08:00',
        bodyWeight: 65.5,
        heartRate: 72,
      );

      expect(observed[0].path, '/users/patient-1/diaries/by-date/activities');
      expect(observed[0].data, {
        'diaryDate': '2026-06-29',
        'name': 'Walk',
        'activityCategory': 'exercise',
        'duration': 30,
        'heartRate': 90,
      });
      expect(
        observed[1].path,
        '/users/patient-1/diaries/by-date/body-metrics',
      );
      expect(observed[1].data, {
        'diaryDate': '2026-06-29',
        'conditionTag': 'morning',
        'timeStamp': '08:00',
        'bodyWeight': 65.5,
        'heartRate': 72,
      });
    });

    test('fetchDiaryHistoryForUser maps Dio backend error message', () async {
      final api = DiaryApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) => const _FakeDioResponse(
          {
            'success': false,
            'message': 'Riwayat diary ditolak',
          },
          statusCode: 403,
        ),
      )));

      await expectLater(
        api.fetchDiaryHistoryForUser('patient-1'),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Riwayat diary ditolak'),
          ),
        ),
      );
    });
  });
}

_FakeDioResponse _successResponse(Object? data) {
  return _FakeDioResponse({
    'success': true,
    'message': 'OK',
    'data': data,
  });
}

Map<String, dynamic> _diaryJson(String diaryId) {
  return {
    'diaryId': diaryId,
    'userId': 'patient-1',
    'diaryDate': '2026-06-29T00:00:00.000Z',
    'createdAt': '2026-06-29T08:00:00.000Z',
  };
}

Dio _dioWithAdapter(HttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.pulsewise.test'));
  dio.httpClientAdapter = adapter;
  return dio;
}

class _FakeDioResponse {
  const _FakeDioResponse(
    this.body, {
    this.statusCode = 200,
  });

  final Map<String, dynamic> body;
  final int statusCode;
}

class _FakeDioAdapter implements HttpClientAdapter {
  _FakeDioAdapter({required this.handler});

  final FutureOr<_FakeDioResponse> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final response = await handler(options);
    return ResponseBody.fromString(
      jsonEncode(response.body),
      response.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
