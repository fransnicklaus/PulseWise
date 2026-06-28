import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/food_analysis/data/models/food_consumption_result.dart';
import 'package:pulsewise/features/food_analysis/data/models/food_macro_analysis.dart';

void main() {
  group('FoodMacroCaptureResult', () {
    test('toMap and fromMap preserve analysis and trim user input', () {
      final result = FoodMacroCaptureResult(
        analysis: _analysis(),
        userFoodName: 'Nasi goreng',
        userDescription: 'Dinner portion',
      );

      final map = result.toMap();

      expect(map['calories_kcal'], 320);
      expect(map['detected_foods'], ['Nasi goreng']);
      expect(map['user_food_name'], 'Nasi goreng');
      expect(map['user_description'], 'Dinner portion');

      final restored = FoodMacroCaptureResult.fromMap({
        ...map,
        'user_food_name': ' Soto ayam ',
        'user_description': ' Sup hangat ',
      });

      expect(restored.userFoodName, 'Soto ayam');
      expect(restored.userDescription, 'Sup hangat');
      expect(restored.analysis.detectedFoods, ['Nasi goreng']);
      expect(restored.analysis.caloriesKcal, 320);
    });
  });

  group('ManualFoodConsumptionResult', () {
    test('toMap serializes manual entry fields', () {
      const result = ManualFoodConsumptionResult(
        typeLabel: 'Makanan Berat',
        type: 'breakfast',
        name: 'Oatmeal',
        portion: '1 bowl',
        time: '08:00',
        useCurrentTime: true,
        note: 'Less sugar',
        nutritionPayload: {
          'energyKcal': 220,
          'proteinG': 8,
        },
      );

      expect(result.toMap(), {
        'typeLabel': 'Makanan Berat',
        'type': 'breakfast',
        'name': 'Oatmeal',
        'portion': '1 bowl',
        'time': '08:00',
        'useCurrentTime': true,
        'note': 'Less sugar',
        'nutritionPayload': {
          'energyKcal': 220,
          'proteinG': 8,
        },
      });
    });

    test('fromMap trims strings and normalizes nutrition payload keys', () {
      final result = ManualFoodConsumptionResult.fromMap({
        'typeLabel': ' Makanan Ringan ',
        'type': ' snack ',
        'name': ' Pisang ',
        'portion': ' 1 buah ',
        'time': ' 10:30 ',
        'useCurrentTime': 'true',
        'note': '  before workout  ',
        'nutritionPayload': {
          'energyKcal': 90,
          2: 'two',
        },
      });

      expect(result.typeLabel, 'Makanan Ringan');
      expect(result.type, 'snack');
      expect(result.name, 'Pisang');
      expect(result.portion, '1 buah');
      expect(result.time, '10:30');
      expect(result.useCurrentTime, isFalse);
      expect(result.note, '  before workout  ');
      expect(result.nutritionPayload, {
        'energyKcal': 90,
        '2': 'two',
      });
    });

    test('fromMap falls back to an empty nutrition payload for invalid input',
        () {
      final result = ManualFoodConsumptionResult.fromMap({
        'nutritionPayload': 'not-a-map',
      });

      expect(result.nutritionPayload, isEmpty);
      expect(result.typeLabel, isEmpty);
      expect(result.useCurrentTime, isFalse);
    });
  });
}

FoodMacroAnalysis _analysis() {
  return FoodMacroAnalysis.fromJson({
    'meal_name': 'Nasi goreng',
    'meal_category': 'Makanan Berat',
    'portion_estimate': '1 plate',
    'portion_grams_estimate': 250,
    'calories_kcal': 320,
    'protein_g': 12,
  });
}
