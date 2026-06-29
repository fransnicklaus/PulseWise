import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/medication/data/datasources/medication_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      AppSessionStore.tokenPrefsKey: 'med-token',
      AppSessionStore.userIdPrefsKey: 'patient-1',
    });
  });

  group('MedicationApi', () {
    test('addMedication sends daily payload with trimmed optional note',
        () async {
      late RequestOptions observedOptions;
      final api = MedicationApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return _successResponse();
        },
      )));

      await api.addMedication(
        name: 'Aspirin',
        form: 'tablet',
        color: '#FFFFFF',
        singleDose: 1,
        singleDoseUnit: 'tablet',
        startDate: '2026-06-29',
        frequency: 'DAILY',
        numOfDays: 7,
        daysOfWeek: const [1, 3],
        intakeTimes: const ['08:00'],
        note: ' setelah makan ',
      );

      expect(observedOptions.method, 'POST');
      expect(observedOptions.path, '/users/patient-1/medications');
      expect(observedOptions.headers['Authorization'], 'Bearer med-token');
      expect(observedOptions.data, {
        'name': 'Aspirin',
        'form': 'tablet',
        'color': '#FFFFFF',
        'singleDose': 1,
        'singleDoseUnit': 'tablet',
        'startDate': '2026-06-29',
        'frequency': 'daily',
        'numOfDays': 7,
        'intakeTimes': ['08:00'],
        'note': 'setelah makan',
      });
    });

    test('addMedication sends weekly payload without blank note', () async {
      late Map<String, dynamic> observedBody;
      final api = MedicationApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedBody = Map<String, dynamic>.from(options.data as Map);
          return _successResponse();
        },
      )));

      await api.addMedication(
        name: 'Vitamin D',
        form: 'capsule',
        color: '#FACC15',
        singleDose: 1,
        singleDoseUnit: 'capsule',
        startDate: '2026-06-29',
        frequency: 'Weekly',
        numOfDays: 30,
        daysOfWeek: const [1, 5],
        intakeTimes: const ['09:00'],
        note: '   ',
      );

      expect(observedBody['frequency'], 'weekly');
      expect(observedBody['daysOfWeek'], [1, 5]);
      expect(observedBody.containsKey('numOfDays'), isFalse);
      expect(observedBody.containsKey('note'), isFalse);
    });

    test('fetchMedications sends pagination and parses response', () async {
      late RequestOptions observedOptions;
      final api = MedicationApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return const _FakeDioResponse({
            'success': true,
            'message': 'OK',
            'data': {
              'items': [
                {
                  'medicationId': 'med-1',
                  'userId': 'patient-1',
                  'name': 'Aspirin',
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

      final response = await api.fetchMedications(page: 2, limit: 5);

      expect(observedOptions.method, 'GET');
      expect(observedOptions.path, '/users/patient-1/medications');
      expect(observedOptions.queryParameters, {'page': 2, 'limit': 5});
      expect(response.items.single.medicationId, 'med-1');
      expect(response.pagination.totalPages, 2);
    });

    test('fetchMedicationDetail parses detail data', () async {
      late RequestOptions observedOptions;
      final api = MedicationApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return const _FakeDioResponse({
            'success': true,
            'data': {
              'medicationId': 'med-1',
              'userId': 'patient-1',
              'name': 'Aspirin',
            },
          });
        },
      )));

      final medication = await api.fetchMedicationDetail('med-1');

      expect(observedOptions.path, '/users/patient-1/medications/med-1');
      expect(medication.medicationId, 'med-1');
      expect(medication.name, 'Aspirin');
    });

    test('updateMedication sends weekly patch payload', () async {
      late RequestOptions observedOptions;
      final api = MedicationApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return _successResponse();
        },
      )));

      await api.updateMedication(
        medicationId: 'med-1',
        form: 'tablet',
        color: '#FFFFFF',
        singleDose: 2,
        singleDoseUnit: 'tablet',
        startDate: '2026-06-29',
        frequency: 'WEEKLY',
        daysOfWeek: const [2, 4],
        intakeTimes: const ['08:00', '20:00'],
        note: ' update note ',
      );

      expect(observedOptions.method, 'PATCH');
      expect(observedOptions.path, '/users/patient-1/medications/med-1');
      expect(observedOptions.data, {
        'form': 'tablet',
        'color': '#FFFFFF',
        'singleDose': 2,
        'singleDoseUnit': 'tablet',
        'startDate': '2026-06-29',
        'frequency': 'weekly',
        'daysOfWeek': [2, 4],
        'intakeTimes': ['08:00', '20:00'],
        'note': 'update note',
      });
    });

    test('deleteMedication sends authorized delete request', () async {
      late RequestOptions observedOptions;
      final api = MedicationApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return _successResponse();
        },
      )));

      await api.deleteMedication('med-1');

      expect(observedOptions.method, 'DELETE');
      expect(observedOptions.path, '/users/patient-1/medications/med-1');
      expect(observedOptions.headers['Authorization'], 'Bearer med-token');
    });

    test('takeMedication uses supplied scheduled date and time', () async {
      late RequestOptions observedOptions;
      final api = MedicationApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return _successResponse();
        },
      )));

      await api.takeMedication(
        'taken',
        'med-1',
        DateTime(2026, 6, 29, 13),
        '08:30',
      );

      expect(observedOptions.method, 'POST');
      expect(observedOptions.path, '/users/patient-1/medications/med-1/logs');
      expect(observedOptions.data, {
        'medicationDate': '2026-06-29',
        'medicationTime': '08:30',
        'status': 'taken',
      });
    });

    test('fetchMedicationLogs validates required ids before request', () async {
      var called = false;
      final api = MedicationApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) {
          called = true;
          return _successResponse();
        },
      )));

      await expectLater(
        api.fetchMedicationLogs(
          patientId: ' ',
          medicationId: 'med-1',
          page: 1,
          limit: 10,
          startDate: DateTime(2026, 6),
          endDate: DateTime(2026, 6, 29),
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('patientId tidak ditemukan. Silakan login ulang.'),
          ),
        ),
      );
      expect(called, isFalse);
    });

    test('fetchMedicationLogs sends date range query and parses response',
        () async {
      late RequestOptions observedOptions;
      final api = MedicationApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return const _FakeDioResponse({
            'success': true,
            'data': {
              'items': [
                {
                  'medicationLogId': 'log-1',
                  'userId': 'patient-1',
                  'medicationId': 'med-1',
                  'status': 'taken',
                },
              ],
              'summary': {'taken': 1},
            },
          });
        },
      )));

      final response = await api.fetchMedicationLogs(
        patientId: 'patient-2',
        medicationId: 'med-1',
        page: 3,
        limit: 20,
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 6, 29),
      );

      expect(
        observedOptions.path,
        '/users/patient-2/medications/med-1/logs',
      );
      expect(observedOptions.queryParameters, {
        'page': 3,
        'limit': 20,
        'startDate': '2026-06-01',
        'endDate': '2026-06-29',
      });
      expect(response.items.single.medicationLogId, 'log-1');
      expect(response.summary.taken, 1);
    });

    test('fetchMedicationCalendar sends formatted range and parses response',
        () async {
      late RequestOptions observedOptions;
      final api = MedicationApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return const _FakeDioResponse({
            'success': true,
            'data': {
              'range': {
                'from': '2026-06-01',
                'to': '2026-06-29',
              },
              'totalItems': 1,
              'items': [
                {
                  'eventId': 'event-1',
                  'medicationId': 'med-1',
                  'name': 'Aspirin',
                },
              ],
            },
          });
        },
      )));

      final response = await api.fetchMedicationCalendar(
        from: DateTime(2026, 6, 1, 9),
        to: DateTime(2026, 6, 29, 18),
      );

      expect(observedOptions.path, '/users/patient-1/medications/calendar');
      expect(observedOptions.queryParameters, {
        'from': '2026-06-01',
        'to': '2026-06-29',
      });
      expect(response.totalItems, 1);
      expect(response.items.single.eventId, 'event-1');
    });

    test('fetchMedications maps Dio backend error message', () async {
      final api = MedicationApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) => const _FakeDioResponse(
          {
            'success': false,
            'message': 'Medication ditolak',
          },
          statusCode: 403,
        ),
      )));

      await expectLater(
        api.fetchMedications(),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Medication ditolak'),
          ),
        ),
      );
    });
  });
}

_FakeDioResponse _successResponse() {
  return const _FakeDioResponse({
    'success': true,
    'message': 'OK',
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
