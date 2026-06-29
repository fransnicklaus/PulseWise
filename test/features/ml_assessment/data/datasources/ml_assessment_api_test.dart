import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/ml_assessment/data/datasources/ml_assessment_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      AppSessionStore.tokenPrefsKey: 'ml-token',
      AppSessionStore.userIdPrefsKey: 'patient-1',
    });
  });

  group('MlAssessmentApi', () {
    test('fetchLatestMlAssessment sends authorized request and parses data',
        () async {
      late RequestOptions observedOptions;
      final api = MlAssessmentApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return const _FakeDioResponse({
            'success': true,
            'data': {
              'assessmentId': 'assessment-1',
              'assessmentDate': '2026-06-29T00:00:00.000Z',
              'score': 88,
            },
          });
        },
      )));

      final record = await api.fetchLatestMlAssessment();

      expect(observedOptions.method, 'GET');
      expect(
        observedOptions.path,
        '/patients/patient-1/ml-assessments/latest',
      );
      expect(observedOptions.headers['Authorization'], 'Bearer ml-token');
      expect(observedOptions.headers['Content-Type'], 'application/json');
      expect(record!.assessmentId, 'assessment-1');
      expect(record.valueFor('score'), 88);
    });

    test('fetchLatestMlAssessment returns null on not found response',
        () async {
      final api = MlAssessmentApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) => const _FakeDioResponse(
          {'success': false, 'message': 'Tidak ada assessment'},
          statusCode: 404,
        ),
      )));

      final record = await api.fetchLatestMlAssessment();

      expect(record, isNull);
    });

    test('fetchMlAssessments sends optional date filters and parses list',
        () async {
      late RequestOptions observedOptions;
      final api = MlAssessmentApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return const _FakeDioResponse({
            'success': true,
            'data': [
              {
                'assessmentId': 'assessment-1',
                'assessmentDate': '2026-06-29',
              },
            ],
          });
        },
      )));

      final records = await api.fetchMlAssessments(
        startDate: '2026-06-01',
        endDate: '2026-06-29',
      );

      expect(observedOptions.path, '/patients/patient-1/ml-assessments');
      expect(observedOptions.queryParameters, {
        'startDate': '2026-06-01',
        'endDate': '2026-06-29',
      });
      expect(records.single.assessmentId, 'assessment-1');
    });

    test('fetchMlReadiness and prediction send expected requests', () async {
      final observed = <RequestOptions>[];
      final api = MlAssessmentApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observed.add(options);
          if (options.path.endsWith('/ml-readiness')) {
            return const _FakeDioResponse({
              'success': true,
              'data': {
                'ready': false,
                'missingFields': ['profile.bodyHeightCm'],
              },
            });
          }
          return const _FakeDioResponse({
            'success': true,
            'data': {
              'riskScore': 0.42,
            },
          });
        },
      )));

      final readiness = await api.fetchMlReadiness('2026-06-29');
      final prediction = await api.fetchMlPrediction('2026-06-29');

      expect(observed[0].method, 'GET');
      expect(observed[0].path, '/users/patient-1/ml-readiness');
      expect(observed[0].queryParameters, {'date': '2026-06-29'});
      expect(readiness.ready, isFalse);
      expect(readiness.missingFields, ['profile.bodyHeightCm']);
      expect(observed[1].method, 'POST');
      expect(observed[1].path, '/users/patient-1/ml-predictions');
      expect(observed[1].queryParameters, {
        'date': '2026-06-29',
        'includePayload': 'true',
      });
      expect(observed[1].data, isEmpty);
      expect(prediction.data['riskScore'], 0.42);
    });

    test('saveMlAssessment chooses create or update endpoint', () async {
      final observed = <RequestOptions>[];
      final api = MlAssessmentApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observed.add(options);
          return _successResponse({
            'assessmentId': options.method == 'POST'
                ? 'created-assessment'
                : 'updated-assessment',
            'score': (options.data as Map)['score'],
          });
        },
      )));

      final created = await api.saveMlAssessment(payload: {'score': 80});
      final updated = await api.saveMlAssessment(
        assessmentId: 'assessment-1',
        payload: {'score': 90},
      );

      expect(observed[0].method, 'POST');
      expect(observed[0].path, '/patients/patient-1/ml-assessments');
      expect(observed[0].data, {'score': 80});
      expect(created.assessmentId, 'created-assessment');
      expect(observed[1].method, 'PUT');
      expect(
        observed[1].path,
        '/patients/patient-1/ml-assessments/assessment-1',
      );
      expect(observed[1].data, {'score': 90});
      expect(updated.assessmentId, 'updated-assessment');
    });

    test('fetchMlAssessments maps Dio backend error message', () async {
      final api = MlAssessmentApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) => const _FakeDioResponse(
          {
            'success': false,
            'message': 'Assessment ditolak',
          },
          statusCode: 403,
        ),
      )));

      await expectLater(
        api.fetchMlAssessments(),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Assessment ditolak'),
          ),
        ),
      );
    });
  });
}

_FakeDioResponse _successResponse(Object data) {
  return _FakeDioResponse({
    'success': true,
    'message': 'OK',
    'data': data,
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
