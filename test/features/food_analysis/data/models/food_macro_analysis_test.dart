import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/food_analysis/data/models/food_macro_analysis.dart';

void main() {
  group('FoodMacroAnalysis', () {
    test('fromJson parses aliases and normalizes meal analysis values', () {
      final longPortion = List.filled(
        FoodMacroAnalysis.maxPortionEstimateLength + 5,
        'x',
      ).join();

      final analysis = FoodMacroAnalysis.fromJson({
        'isFoodImage': 'true',
        'validationMessage': ' valid food ',
        'mealCategory': 'Minuman',
        'detectedFoods': [' jus apel ', '', 42],
        'portionDescription': ' $longPortion ',
        'portionGrams': '123.6',
        'fdcFoodId': 777,
        'nutritionSource': '',
        'energyKcal': '180.5',
        'proteinG': 3,
        'carbohydrateG': '44.2',
        'sugarG': '21',
        'fiberG': 2.5,
        'totalFatG': '1.2',
        'saturatedFatG': '0.4',
        'monounsaturatedFatG': '0.2',
        'polyunsaturatedFatG': '0.1',
        'cholesterolMg': '0',
        'calciumMg': 45,
        'confidenceLevel': 'high',
        'note': 'Fresh estimate',
      });

      expect(analysis.isFoodImage, isTrue);
      expect(analysis.validationMessage, 'valid food');
      expect(analysis.mealCategory, 'drink');
      expect(analysis.mealCategoryLabel, 'Minuman');
      expect(analysis.detectedFoods, ['jus apel', '42']);
      expect(analysis.suggestedName, 'jus apel, 42');
      expect(
        analysis.portionEstimate,
        hasLength(FoodMacroAnalysis.maxPortionEstimateLength),
      );
      expect(analysis.portionGramsEstimate, 123.6);
      expect(analysis.fdcFoodId, '777');
      expect(
        analysis.nutritionSource,
        FoodMacroAnalysis.defaultNutritionSource,
      );
      expect(analysis.caloriesKcal, 180.5);
      expect(analysis.proteinG, 3);
      expect(analysis.carbsG, 44.2);
      expect(analysis.sugarG, 21);
      expect(analysis.fiberG, 2.5);
      expect(analysis.fatG, 1.2);
      expect(analysis.saturatedFatG, 0.4);
      expect(analysis.monounsaturatedFatG, 0.2);
      expect(analysis.polyunsaturatedFatG, 0.1);
      expect(analysis.cholesterolMg, 0);
      expect(analysis.calciumMg, 45);
      expect(analysis.confidence, 'high');
      expect(analysis.notes, 'Fresh estimate');
      expect(analysis.hasValidFoodResult, isTrue);
    });

    test('toJson and toNutritionPayload serialize normalized fields', () {
      final analysis = FoodMacroAnalysis.fromJson({
        'meal_name': 'Oatmeal',
        'meal_category': 'Makanan Berat',
        'portion_grams_estimate': 99.6,
        'fdc_food_id': 'fdc-1',
        'nutrition_source': 'usda',
        'calories_kcal': 240,
        'protein_g': 9,
        'carbs_g': 38,
        'sugar_g': 4,
        'fiber_g': 5,
        'fat_g': 6,
        'saturated_fat_g': 1,
        'monounsaturated_fat_g': 2,
        'polyunsaturated_fat_g': 3,
        'cholesterol_mg': 10,
        'calcium_mg': 120,
      });

      expect(analysis.detectedFoods, ['Oatmeal']);
      expect(analysis.mealCategory, 'breakfast');
      expect(analysis.mealCategoryLabel, 'Makanan Berat');
      expect(analysis.toJson(), {
        'is_food_image': true,
        'validation_message': '',
        'meal_category': 'breakfast',
        'detected_foods': ['Oatmeal'],
        'portion_estimate': '',
        'portion_grams_estimate': 99.6,
        'fdc_food_id': 'fdc-1',
        'nutrition_source': 'usda',
        'calories_kcal': 240,
        'protein_g': 9,
        'carbs_g': 38,
        'sugar_g': 4,
        'fiber_g': 5,
        'fat_g': 6,
        'saturated_fat_g': 1,
        'monounsaturated_fat_g': 2,
        'polyunsaturated_fat_g': 3,
        'cholesterol_mg': 10,
        'calcium_mg': 120,
        'confidence': '',
        'notes': '',
      });
      expect(analysis.toNutritionPayload(), {
        'nutritionSource': 'usda',
        'energyKcal': 240,
        'proteinG': 9,
        'carbohydrateG': 38,
        'sugarG': 4,
        'fiberG': 5,
        'totalFatG': 6,
        'saturatedFatG': 1,
        'monounsaturatedFatG': 2,
        'polyunsaturatedFatG': 3,
        'cholesterolMg': 10,
        'calciumMg': 120,
        'portionGrams': 100,
        'fdcFoodId': 'fdc-1',
      });
    });

    test('returns safe fallbacks for invalid categories and non-food images',
        () {
      final analysis = FoodMacroAnalysis.fromJson({
        'is_food_image': false,
        'mealName': 'Medicine bottle',
        'meal_category': 'unknown',
        'energyKcal': 100,
      });

      expect(analysis.isFoodImage, isFalse);
      expect(analysis.hasValidFoodResult, isFalse);
      expect(analysis.detectedFoods, ['Medicine bottle']);
      expect(analysis.mealCategory, 'other');
      expect(analysis.mealCategoryLabel, 'Makanan Ringan');
      expect(analysis.toNutritionPayload(), isEmpty);
    });
  });
}
