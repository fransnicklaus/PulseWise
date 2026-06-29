import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/doctor/data/datasources/doctor_dashboard_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      AppSessionStore.tokenPrefsKey: 'doctor-token',
      AppSessionStore.userIdPrefsKey: 'doctor-1',
    });
  });

  group('DoctorDashboardApi', () {
    test('fetchPatients sends pagination and parses list', () async {
      late RequestOptions observedOptions;
      final api = DoctorDashboardApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return const _FakeDioResponse({
            'success': true,
            'data': {
              'items': [
                {
                  'patientId': 'patient-1',
                  'firstName': 'Ayu',
                  'lastName': 'Putri',
                },
              ],
              'pagination': {
                'page': 2,
                'limit': 5,
                'totalItems': 6,
                'totalPages': 2,
              },
            },
          });
        },
      )));

      final response = await api.fetchPatients(page: 2, limit: 5);

      expect(observedOptions.method, 'GET');
      expect(observedOptions.path, '/doctors/doctor-1/dashboard/patients');
      expect(observedOptions.queryParameters, {'page': 2, 'limit': 5});
      expect(observedOptions.headers['Authorization'], 'Bearer doctor-token');
      expect(response.items.single.patient.patientId, 'patient-1');
      expect(response.pagination.totalPages, 2);
    });

    test('fetchPatientSummary and vitals send expected paths', () async {
      final observed = <RequestOptions>[];
      final api = DoctorDashboardApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observed.add(options);
          if (options.path.endsWith('/vitals')) {
            return _successResponse({
              'patient': {
                'patientId': 'patient-1',
                'firstName': 'Ayu',
              },
              'period': {
                'timePeriod': 'last_7_days',
              },
              'series': {
                'heartRate': [72],
              },
            });
          }
          return _successResponse({
            'patient': {
              'patientId': 'patient-1',
              'firstName': 'Ayu',
            },
            'latestVitals': {
              'heartRate': 72,
            },
          });
        },
      )));

      final summary = await api.fetchPatientSummary('patient-1');
      final vitals = await api.fetchPatientVitals(
        'patient-1',
        timePeriod: 'last_7_days',
      );

      expect(
        observed[0].path,
        '/doctors/doctor-1/dashboard/patients/patient-1',
      );
      expect(summary.data!.patient.patientId, 'patient-1');
      expect(
        observed[1].path,
        '/doctors/doctor-1/dashboard/patients/patient-1/vitals',
      );
      expect(observed[1].queryParameters, {'timePeriod': 'last_7_days'});
      expect(vitals.data!.series.heartRate, [72]);
    });

    test('linkPatientByShare validates and sends trimmed share code', () async {
      late RequestOptions observedOptions;
      final api = DoctorDashboardApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return _successResponse({
            'doctorId': 'doctor-1',
            'patientId': 'patient-1',
            'source': 'qr',
            'firstName': 'Ayu',
          });
        },
      )));

      final linked = await api.linkPatientByShare(shareCode: ' SHARE-1 ');

      expect(observedOptions.method, 'POST');
      expect(
        observedOptions.path,
        '/doctors/doctor-1/patients/link-by-share',
      );
      expect(observedOptions.data, {'shareCode': 'SHARE-1'});
      expect(linked.patientId, 'patient-1');

      await expectLater(
        api.linkPatientByShare(shareCode: ' '),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Kode share pasien tidak valid.'),
          ),
        ),
      );
    });

    test('fetchLatestPatientMlRecommendation returns null on not found',
        () async {
      var calls = 0;
      final api = DoctorDashboardApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) {
          calls++;
          if (calls == 1) return _recommendationResponse('result-1');
          return const _FakeDioResponse(
            {'success': false, 'message': 'Belum ada rekomendasi'},
            statusCode: 404,
          );
        },
      )));

      final latest = await api.fetchLatestPatientMlRecommendation('patient-1');
      final missing = await api.fetchLatestPatientMlRecommendation('patient-1');

      expect(latest!.data!.resultId, 'result-1');
      expect(missing, isNull);
    });

    test('fetchPatientMlRecommendationHistory sends pagination', () async {
      late RequestOptions observedOptions;
      final api = DoctorDashboardApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return const _FakeDioResponse({
            'success': true,
            'data': {
              'items': [
                {
                  'resultId': 'history-1',
                  'inferenceType': 'daily',
                },
              ],
              'pagination': {
                'page': 2,
                'limit': 5,
                'totalItems': 6,
                'totalPages': 2,
              },
            },
          });
        },
      )));

      final response = await api.fetchPatientMlRecommendationHistory(
        'patient-1',
        page: 2,
        limit: 5,
      );

      expect(
        observedOptions.path,
        '/doctors/doctor-1/dashboard/patients/patient-1/ml-recommendations/history',
      );
      expect(observedOptions.queryParameters, {'page': 2, 'limit': 5});
      expect(response.items.single.resultId, 'history-1');
    });

    test('heart risk latest endpoints handle empty and not found data',
        () async {
      final api = DoctorDashboardApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          if (options.path.endsWith('/assessment/latest')) {
            return const _FakeDioResponse({
              'success': true,
              'data': {},
            });
          }
          return const _FakeDioResponse(
            {'success': false, 'message': 'Belum ada prediksi'},
            statusCode: 404,
          );
        },
      )));

      final assessment =
          await api.fetchLatestPatientHeartRiskAssessment('patient-1');
      final prediction =
          await api.fetchLatestPatientHeartRiskPrediction('patient-1');

      expect(assessment, isNull);
      expect(prediction, isNull);
    });

    test('savePatientHeartRiskAssessment chooses create and update endpoint',
        () async {
      final observed = <RequestOptions>[];
      final api = DoctorDashboardApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observed.add(options);
          return _successResponse({
            'assessmentId': options.method == 'POST'
                ? 'created-assessment'
                : 'updated-assessment',
            'patientId': 'patient-1',
          });
        },
      )));

      final created = await api.savePatientHeartRiskAssessment(
        'patient-1',
        payload: const {'age': 50},
      );
      final updated = await api.savePatientHeartRiskAssessment(
        'patient-1',
        assessmentId: 'assessment-1',
        payload: const {'age': 51},
      );

      expect(observed[0].method, 'POST');
      expect(
        observed[0].path,
        '/doctors/doctor-1/dashboard/patients/patient-1/heart-risk-model/assessments',
      );
      expect(observed[0].headers['Content-Type'], 'application/json');
      expect(observed[0].data, {'age': 50});
      expect(created.assessmentId, 'created-assessment');
      expect(observed[1].method, 'PUT');
      expect(
        observed[1].path,
        '/doctors/doctor-1/dashboard/patients/patient-1/heart-risk-model/assessments/assessment-1',
      );
      expect(observed[1].data, {'age': 51});
      expect(updated.assessmentId, 'updated-assessment');
    });

    test('run heart risk prediction and history send expected queries',
        () async {
      final observed = <RequestOptions>[];
      final api = DoctorDashboardApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observed.add(options);
          if (options.method == 'POST') {
            return _successResponse(_heartRiskPrediction('result-1'));
          }
          return _successResponse({
            'items': [
              _heartRiskPrediction('history-1'),
            ],
            'pagination': {
              'page': 2,
              'limit': 5,
              'totalItems': 6,
              'totalPages': 2,
            },
          });
        },
      )));

      final prediction = await api.runPatientHeartRiskPrediction(
        'patient-1',
        includePayload: false,
      );
      final history = await api.fetchPatientHeartRiskPredictionHistory(
        'patient-1',
        page: 2,
        limit: 5,
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 6, 29),
      );

      expect(observed[0].method, 'POST');
      expect(
        observed[0].path,
        '/doctors/doctor-1/dashboard/patients/patient-1/heart-risk-model/predictions',
      );
      expect(observed[0].queryParameters, {'includePayload': 'false'});
      expect(observed[0].data, isEmpty);
      expect(prediction.resultId, 'result-1');
      expect(
        observed[1].path,
        '/doctors/doctor-1/dashboard/patients/patient-1/heart-risk-model/predictions/history',
      );
      expect(observed[1].queryParameters, {
        'page': 2,
        'limit': 5,
        'startDate': '2026-06-01',
        'endDate': '2026-06-29',
      });
      expect(history.items.single.resultId, 'history-1');
    });

    test('fetchPatients maps Dio backend error message', () async {
      final api = DoctorDashboardApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) => const _FakeDioResponse(
          {
            'success': false,
            'message': 'Daftar pasien ditolak',
          },
          statusCode: 403,
        ),
      )));

      await expectLater(
        api.fetchPatients(),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Daftar pasien ditolak'),
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

_FakeDioResponse _recommendationResponse(String resultId) {
  return _successResponse({
    'resultId': resultId,
    'patientId': 'patient-1',
    'requestedByUserId': 'doctor-1',
    'inferenceType': 'daily',
    'requestContext': 'doctor',
    'mlVersion': 'v1',
    'payloadHash': 'hash',
    'generatedAt': '2026-06-29T00:00:00.000Z',
    'createdAt': '2026-06-29T00:00:00.000Z',
  });
}

Map<String, dynamic> _heartRiskPrediction(String resultId) {
  return {
    'resultId': resultId,
    'patientId': 'patient-1',
    'requestedByUserId': 'doctor-1',
    'modelKey': 'heart_risk',
    'inferenceType': 'daily',
    'requestContext': 'doctor',
    'mlVersion': 'v1',
    'payloadHash': 'hash',
    'generatedAt': '2026-06-29T00:00:00.000Z',
    'createdAt': '2026-06-29T00:00:00.000Z',
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
