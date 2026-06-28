import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/features/food_analysis/data/datasources/food_nutrition_estimate_api.dart';
import 'package:pulsewise/features/food_analysis/presentation/providers/food_nutrition_estimate_api_provider.dart';
import 'package:pulsewise/features/health_connect/data/datasources/health_connect_setup_api.dart';
import 'package:pulsewise/features/health_connect/presentation/providers/health_connect_provider.dart';

void main() {
  group('food and health provider wiring', () {
    test('foodNutritionEstimateApiProvider creates API from shared Dio', () {
      final container = ProviderContainer(
        overrides: [
          apiDioProvider.overrideWithValue(Dio()),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(foodNutritionEstimateApiProvider),
        isA<FoodNutritionEstimateApi>(),
      );
    });

    test('healthConnectSetupApiProvider creates API from shared Dio', () {
      final container = ProviderContainer(
        overrides: [
          apiDioProvider.overrideWithValue(Dio()),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(healthConnectSetupApiProvider),
        isA<HealthConnectSetupApi>(),
      );
    });
  });
}
