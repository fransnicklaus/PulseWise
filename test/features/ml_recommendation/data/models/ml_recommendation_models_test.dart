import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/ml_recommendation/data/models/ml_recommendation_models.dart';

void main() {
  group('MlRecommendationResponse', () {
    test('parses nested upstream body when body is encoded as JSON string', () {
      final response = MlRecommendationResponse.fromJson({
        'success': true,
        'message': 'OK',
        'data': {
          'resultId': 1001,
          'patientId': 'patient-1',
          'requestedByUserId': 'user-1',
          'inferenceType': 'daily',
          'requestContext': 'history',
          'mlVersion': 'v1',
          'payloadHash': 'hash-1',
          'generatedAt': '2026-06-28T08:00:00.000Z',
          'createdAt': '2026-06-28T08:01:00.000Z',
          'upstream': {
            'endpoint': '/recommend',
            'status': '200',
            'body': jsonEncode({
              'status': '1',
              'resultHistory': [0.72, '0.64', 'bad'],
              'statusMessage': 'generated',
              'recommendationResult': {
                'lifestyle': [
                  {
                    'variable': 'sleep',
                    'codeValue': 'SLEEP_HOURS',
                    'comparison': '<',
                    'description': 'Tidur cukup',
                    'changeStatus': 'increase',
                    'currentValue': 5,
                    'recommendedValueInterval': '7-8',
                  },
                  'ignored',
                ],
                'timeTaken': 250,
                'currentRisk': '0.72',
                'riskReduction': 0.14,
                'timeGenerated': '2026-06-28T08:00:00.000Z',
                'currentRiskThresh': '0.8',
                'riskReductionThresh': '0.1',
                'riskAfterRecommendation': '0.58',
                'riskAfterRecommendationThresh': '0.7',
              },
            }),
          },
        },
      });

      final body = response.data!.upstream!.body!;
      final result = body.recommendationResult;

      expect(response.success, isTrue);
      expect(response.message, 'OK');
      expect(response.data!.resultId, '1001');
      expect(response.data!.upstream!.endpoint, '/recommend');
      expect(response.data!.upstream!.status, 200);
      expect(body.status, 1);
      expect(body.resultHistory, [0.72, 0.64, 0.0]);
      expect(body.statusMessage, 'generated');
      expect(result.timeTaken, '250');
      expect(result.currentRisk, 0.72);
      expect(result.riskReduction, 0.14);
      expect(result.riskAfterRecommendation, 0.58);
      expect(result.lifestyle, hasLength(1));
      expect(result.lifestyle.single.variable, 'sleep');
      expect(result.lifestyle.single.currentValue, 5);
    });

    test('uses safe defaults for empty or malformed payloads', () {
      final response = MlRecommendationResponse.fromJson({
        'success': false,
        'upstream': {'body': 'not-json'},
      });
      final upstream = MlRecommendationUpstream.fromJson({
        'status': 'bad',
        'body': 'not-json',
      });
      final body = MlRecommendationBody.fromJson({});

      expect(response.success, isFalse);
      expect(response.message, '');
      expect(response.data, isNull);
      expect(upstream.status, 0);
      expect(upstream.body, isNull);
      expect(body.status, 0);
      expect(body.resultHistory, isEmpty);
      expect(body.recommendationResult.lifestyle, isEmpty);
      expect(body.recommendationResult.currentRisk, 0.0);
    });
  });

  group('MlRecommendationHistoryResponse', () {
    test('parses items and pagination metadata', () {
      final response = MlRecommendationHistoryResponse.fromJson({
        'items': [
          {
            'resultId': 7,
            'inferenceType': 'daily',
            'requestContext': 'manual',
            'mlVersion': 'v1',
            'generatedAt': '2026-06-28T08:00:00.000Z',
          },
        ],
        'pagination': {
          'page': 2,
          'limit': 5,
          'totalItems': 11,
          'totalPages': 3,
        },
      });

      expect(response.items, hasLength(1));
      expect(response.items.single.resultId, '7');
      expect(response.items.single.requestContext, 'manual');
      expect(response.pagination.page, 2);
      expect(response.pagination.limit, 5);
      expect(response.pagination.totalItems, 11);
      expect(response.pagination.totalPages, 3);
    });
  });
}
