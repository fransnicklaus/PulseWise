import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/home_dashboard/data/datasources/dashboard_overview_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      AppSessionStore.tokenPrefsKey: 'patient-token',
      AppSessionStore.userIdPrefsKey: 'patient-1',
    });
  });

  group('DashboardOverviewApi', () {
    test('fetchDashboardVitals sends authorized request with time period',
        () async {
      late RequestOptions observedOptions;
      final api = DashboardOverviewApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return const _FakeDioResponse({
            'success': true,
            'message': 'OK',
            'data': {
              'patient': {
                'patientId': 'patient-1',
                'firstName': 'Ayu',
                'lastName': 'Putri',
              },
              'period': {
                'startAt': '2026-06-01',
                'endAt': '2026-06-29',
                'timePeriod': 'last_30_days',
              },
              'series': {
                'timestamps': ['2026-06-29'],
                'heartRate': [72],
              },
            },
          });
        },
      )));

      final response = await api.fetchDashboardVitals('last_30_days');

      expect(observedOptions.method, 'GET');
      expect(observedOptions.path, '/users/patient-1/dashboard/vitals');
      expect(observedOptions.queryParameters, {
        'timePeriod': 'last_30_days',
      });
      expect(observedOptions.headers['Authorization'], 'Bearer patient-token');
      expect(response.success, isTrue);
      expect(response.data!.series.heartRate, [72]);
    });

    test('fetchDashboardVitals throws backend message when success is false',
        () async {
      final api = DashboardOverviewApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) => const _FakeDioResponse({
          'success': false,
          'message': 'Dashboard vitals ditolak',
        }),
      )));

      await expectLater(
        api.fetchDashboardVitals('last_7_days'),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Dashboard vitals ditolak'),
          ),
        ),
      );
    });

    test('fetchQuickDashboard sends authorized request and parses response',
        () async {
      late RequestOptions observedOptions;
      final api = DashboardOverviewApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return const _FakeDioResponse({
            'success': true,
            'message': 'OK',
            'data': {
              'patient': {
                'patientId': 'patient-1',
                'firstName': 'Ayu',
                'lastName': 'Putri',
              },
              'latestVitals': {
                'heartRate': 72,
              },
              'latestVitalsByField': {
                'heartRate': {
                  'value': 72,
                  'measuredAt': '2026-06-29T08:00:00.000Z',
                },
              },
            },
          });
        },
      )));

      final response = await api.fetchQuickDashboard();

      expect(observedOptions.method, 'GET');
      expect(observedOptions.path, '/users/patient-1/dashboard');
      expect(observedOptions.headers['Authorization'], 'Bearer patient-token');
      expect(response!.success, isTrue);
      expect(response.data!.latestVitals!.heartRate, 72);
      expect(response.data!.latestVitalsByField['heartRate']!.value, 72);
    });

    test('fetchQuickDashboard returns null on not found response', () async {
      final api = DashboardOverviewApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) => const _FakeDioResponse(
          {
            'success': false,
            'message': 'Dashboard belum tersedia',
          },
          statusCode: 404,
        ),
      )));

      final response = await api.fetchQuickDashboard();

      expect(response, isNull);
    });

    test('fetchQuickDashboard maps Dio bad response message to exception',
        () async {
      final api = DashboardOverviewApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) => const _FakeDioResponse(
          {
            'success': false,
            'message': 'Akses dashboard ditolak',
          },
          statusCode: 403,
        ),
      )));

      await expectLater(
        api.fetchQuickDashboard(),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Akses dashboard ditolak'),
          ),
        ),
      );
    });
  });
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
