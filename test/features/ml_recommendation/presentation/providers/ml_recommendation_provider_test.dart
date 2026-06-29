import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/features/ml_recommendation/data/datasources/ml_recommendation_api.dart';
import 'package:pulsewise/features/ml_recommendation/data/models/ml_recommendation_models.dart';
import 'package:pulsewise/features/ml_recommendation/presentation/providers/ml_recommendation_provider.dart';

void main() {
  group('mlRecommendation providers', () {
    test('mlRecommendationApiProvider creates API from shared Dio', () {
      final container = ProviderContainer(
        overrides: [
          apiDioProvider.overrideWithValue(Dio()),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(mlRecommendationApiProvider),
        isA<MlRecommendationApi>(),
      );
    });

    test('latestMlRecommendationProvider fetches latest recommendation',
        () async {
      final api = _FakeMlRecommendationApi(_mlRecommendationResponse());
      final container = ProviderContainer(
        overrides: [
          mlRecommendationApiProvider.overrideWithValue(api),
        ],
      );
      addTearDown(container.dispose);

      final response = await container.read(
        latestMlRecommendationProvider.future,
      );

      expect(api.fetchLatestCalls, 1);
      expect(response!.data!.resultId, 'result-1');
    });

    test('latestMlRecommendationProvider allows empty latest recommendation',
        () async {
      final api = _FakeMlRecommendationApi(null);
      final container = ProviderContainer(
        overrides: [
          mlRecommendationApiProvider.overrideWithValue(api),
        ],
      );
      addTearDown(container.dispose);

      final response = await container.read(
        latestMlRecommendationProvider.future,
      );

      expect(api.fetchLatestCalls, 1);
      expect(response, isNull);
    });
  });
}

class _FakeMlRecommendationApi extends MlRecommendationApi {
  _FakeMlRecommendationApi(this.latest) : super(Dio());

  final MlRecommendationResponse? latest;
  int fetchLatestCalls = 0;

  @override
  Future<MlRecommendationResponse?> fetchLatestMlRecommendation() async {
    fetchLatestCalls++;
    return latest;
  }
}

MlRecommendationResponse _mlRecommendationResponse() {
  return MlRecommendationResponse.fromJson({
    'success': true,
    'message': 'OK',
    'data': {
      'resultId': 'result-1',
      'patientId': 'patient-1',
      'requestedByUserId': 'user-1',
      'inferenceType': 'daily',
      'requestContext': 'latest',
      'mlVersion': 'v1',
      'payloadHash': 'hash-1',
      'generatedAt': '2026-06-29T08:00:00.000Z',
      'createdAt': '2026-06-29T08:01:00.000Z',
    },
  });
}
