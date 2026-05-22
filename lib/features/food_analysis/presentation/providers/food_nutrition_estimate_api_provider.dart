import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/features/food_analysis/data/datasources/food_nutrition_estimate_api.dart';

final foodNutritionEstimateApiProvider = Provider<FoodNutritionEstimateApi>(
  (ref) {
    return FoodNutritionEstimateApi(ref.watch(apiDioProvider));
  },
);
