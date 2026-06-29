import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/ml_questionnaire/data/datasources/ml_questionnaire_api.dart';

void main() {
  group('MlQuestionnaireApi', () {
    test('submitMlProfile validates token and patient id before request',
        () async {
      var called = false;
      final api = MlQuestionnaireApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) {
          called = true;
          return _successResponse({});
        },
      )));

      await expectLater(
        api.submitMlProfile(
          token: ' ',
          patientId: 'patient-1',
          payload: const {},
        ),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        api.fetchMlProfile(token: 'token', patientId: ' '),
        throwsA(isA<Exception>()),
      );
      expect(called, isFalse);
    });

    test('submitMlProfile sends authorized put payload', () async {
      late RequestOptions observedOptions;
      final api = MlQuestionnaireApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return _successResponse({});
        },
      )));

      await api.submitMlProfile(
        token: 'questionnaire-token',
        patientId: 'patient-1',
        payload: const {'smoking_status': 1},
      );

      expect(observedOptions.method, 'PUT');
      expect(observedOptions.path, '/patients/patient-1/ml-profile');
      expect(
        observedOptions.headers['Authorization'],
        'Bearer questionnaire-token',
      );
      expect(observedOptions.headers['Content-Type'], 'application/json');
      expect(observedOptions.data, {'smoking_status': 1});
    });

    test('fetchMlProfile parses answers and returns empty profile on not found',
        () async {
      var calls = 0;
      final api = MlQuestionnaireApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) {
          calls++;
          if (calls == 1) {
            return const _FakeDioResponse({
              'success': true,
              'data': {
                'smoking_status': '2',
              },
            });
          }
          return const _FakeDioResponse(
            {'success': false, 'message': 'Belum ada profil'},
            statusCode: 404,
          );
        },
      )));

      final profile = await api.fetchMlProfile(
        token: 'token',
        patientId: 'patient-1',
      );
      final emptyProfile = await api.fetchMlProfile(
        token: 'token',
        patientId: 'patient-1',
      );

      expect(profile.intAnswerFor('smoking_status'), 2);
      expect(emptyProfile.answers, isEmpty);
    });

    test('fetchMlProfile maps Dio backend error message', () async {
      final api = MlQuestionnaireApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) => const _FakeDioResponse(
          {
            'success': false,
            'message': 'Profil ML ditolak',
          },
          statusCode: 403,
        ),
      )));

      await expectLater(
        api.fetchMlProfile(token: 'token', patientId: 'patient-1'),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Profil ML ditolak'),
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
