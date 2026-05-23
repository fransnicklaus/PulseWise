import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/features/ml_recommendation/data/datasources/ml_recommendation_api.dart';
import 'package:pulsewise/features/ml_recommendation/data/models/ml_recommendation_models.dart';

final mlRecommendationApiProvider = Provider<MlRecommendationApi>((ref) {
  return MlRecommendationApi(ref.watch(apiDioProvider));
});

final latestMlRecommendationProvider =
    FutureProvider<MlRecommendationResponse?>((ref) async {
  final api = ref.watch(mlRecommendationApiProvider);
  return api.fetchLatestMlRecommendation();
});
