import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/ml_recommendation/data/datasources/ml_recommendation_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      AppSessionStore.tokenPrefsKey: 'ml-token',
      AppSessionStore.userIdPrefsKey: 'patient-1',
    });
  });

  group('MlRecommendationApi', () {
    test('fetchLatestMlRecommendation parses latest response and handles 404',
        () async {
      var calls = 0;
      final api = MlRecommendationApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) {
          calls++;
          if (calls == 1) return _recommendationResponse('result-latest');
          return const _FakeDioResponse(
            {'success': false, 'message': 'Belum ada rekomendasi'},
            statusCode: 404,
          );
        },
      )));

      final latest = await api.fetchLatestMlRecommendation();
      final missing = await api.fetchLatestMlRecommendation();

      expect(latest!.data!.resultId, 'result-latest');
      expect(missing, isNull);
    });

    test('fetchMlRecommendations sends prediction date and include payload',
        () async {
      late RequestOptions observedOptions;
      final api = MlRecommendationApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return _recommendationResponse('result-1');
        },
      )));

      final response = await api.fetchMlRecommendations('2026-06-29');

      expect(observedOptions.method, 'POST');
      expect(observedOptions.path, '/users/patient-1/ml-recommendations/');
      expect(observedOptions.queryParameters, {
        'date': '2026-06-29',
        'includePayload': 'true',
      });
      expect(observedOptions.data, isEmpty);
      expect(response.data!.resultId, 'result-1');
    });

    test('fetchMlRecommendationHistory sends pagination and date filters',
        () async {
      late RequestOptions observedOptions;
      final api = MlRecommendationApi(_dioWithAdapter(_FakeDioAdapter(
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

      final history = await api.fetchMlRecommendationHistory(
        page: 2,
        limit: 5,
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 6, 29),
      );

      expect(
        observedOptions.path,
        '/users/patient-1/ml-recommendations/history',
      );
      expect(observedOptions.queryParameters, {
        'page': 2,
        'limit': 5,
        'startDate': '2026-06-01',
        'endDate': '2026-06-29',
      });
      expect(history.items.single.resultId, 'history-1');
      expect(history.pagination.totalPages, 2);
    });

    test('fetchMlRecommendationHistoryDetail parses detail response', () async {
      late RequestOptions observedOptions;
      final api = MlRecommendationApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return _recommendationResponse('detail-1');
        },
      )));

      final detail = await api.fetchMlRecommendationHistoryDetail('detail-1');

      expect(observedOptions.method, 'GET');
      expect(
        observedOptions.path,
        '/users/patient-1/ml-recommendations/history/detail-1',
      );
      expect(observedOptions.data, isEmpty);
      expect(detail.data!.resultId, 'detail-1');
    });

    test('fetchMlRecommendationHistory maps Dio backend error message',
        () async {
      final api = MlRecommendationApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) => const _FakeDioResponse(
          {
            'success': false,
            'message': 'History rekomendasi ditolak',
          },
          statusCode: 403,
        ),
      )));

      await expectLater(
        api.fetchMlRecommendationHistory(),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('History rekomendasi ditolak'),
          ),
        ),
      );
    });
  });
}

_FakeDioResponse _recommendationResponse(String resultId) {
  return _FakeDioResponse({
    'success': true,
    'message': 'OK',
    'data': {
      'resultId': resultId,
      'patientId': 'patient-1',
      'requestedByUserId': 'patient-1',
      'inferenceType': 'daily',
      'requestContext': 'patient',
      'mlVersion': 'v1',
      'payloadHash': 'hash',
      'generatedAt': '2026-06-29T00:00:00.000Z',
      'createdAt': '2026-06-29T00:00:00.000Z',
    },
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
