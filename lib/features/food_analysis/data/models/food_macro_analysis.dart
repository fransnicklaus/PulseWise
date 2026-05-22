class FoodMacroAnalysis {
  static const defaultNutritionSource = 'backend_nutrition_estimate';
  static const maxPortionEstimateLength = 255;

  final bool isFoodImage;
  final String validationMessage;
  final String mealCategory;
  final List<String> detectedFoods;
  final String portionEstimate;
  final double portionGramsEstimate;
  final String fdcFoodId;
  final String nutritionSource;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double sugarG;
  final double fiberG;
  final double fatG;
  final double saturatedFatG;
  final double monounsaturatedFatG;
  final double polyunsaturatedFatG;
  final double cholesterolMg;
  final double calciumMg;
  final String confidence;
  final String notes;

  const FoodMacroAnalysis({
    required this.isFoodImage,
    required this.validationMessage,
    required this.mealCategory,
    required this.detectedFoods,
    required this.portionEstimate,
    required this.portionGramsEstimate,
    required this.fdcFoodId,
    required this.nutritionSource,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.sugarG,
    required this.fiberG,
    required this.fatG,
    required this.saturatedFatG,
    required this.monounsaturatedFatG,
    required this.polyunsaturatedFatG,
    required this.cholesterolMg,
    required this.calciumMg,
    required this.confidence,
    required this.notes,
  });

  factory FoodMacroAnalysis.fromJson(Map<String, dynamic> json) {
    final detectedFoodsRaw = _firstList(
      json,
      const ['detected_foods', 'detectedFoods'],
    );
    final fallbackMealName =
        _firstNonEmptyString(json, const ['meal_name', 'mealName']);

    return FoodMacroAnalysis(
      isFoodImage: _toBool(
        _firstValue(json, const ['is_food_image', 'isFoodImage']),
        fallback: true,
      ),
      validationMessage: _firstNonEmptyString(
        json,
        const ['validation_message', 'validationMessage'],
      ),
      mealCategory: _normalizeMealCategory(
        _firstValue(json, const ['meal_category', 'mealCategory']),
      ),
      detectedFoods: (detectedFoodsRaw ??
              (fallbackMealName.isEmpty
                  ? const []
                  : <String>[fallbackMealName]))
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(),
      portionEstimate: truncatePortionText(_firstNonEmptyString(json, const [
        'portion_estimate',
        'portionEstimate',
        'portion_description',
        'portionDescription',
        'portion',
      ])),
      portionGramsEstimate: _toDouble(
        _firstValue(
          json,
          const [
            'portion_grams_estimate',
            'portionGramsEstimate',
            'portionGrams'
          ],
        ),
      ),
      fdcFoodId: _firstNonEmptyString(
        json,
        const ['fdc_food_id', 'fdcFoodId'],
      ),
      nutritionSource: _normalizeNutritionSource(
        _firstValue(json, const ['nutrition_source', 'nutritionSource']),
      ),
      caloriesKcal: _toDouble(
        _firstValue(
            json, const ['calories_kcal', 'caloriesKcal', 'energyKcal']),
      ),
      proteinG: _toDouble(
        _firstValue(json, const ['protein_g', 'proteinG']),
      ),
      carbsG: _toDouble(
        _firstValue(json, const ['carbs_g', 'carbsG', 'carbohydrateG']),
      ),
      sugarG: _toDouble(
        _firstValue(json, const ['sugar_g', 'sugarG']),
      ),
      fiberG: _toDouble(
        _firstValue(json, const ['fiber_g', 'fiberG']),
      ),
      fatG: _toDouble(
        _firstValue(json, const ['fat_g', 'fatG', 'totalFatG']),
      ),
      saturatedFatG: _toDouble(
        _firstValue(json, const ['saturated_fat_g', 'saturatedFatG']),
      ),
      monounsaturatedFatG: _toDouble(
        _firstValue(
          json,
          const ['monounsaturated_fat_g', 'monounsaturatedFatG'],
        ),
      ),
      polyunsaturatedFatG: _toDouble(
        _firstValue(
          json,
          const ['polyunsaturated_fat_g', 'polyunsaturatedFatG'],
        ),
      ),
      cholesterolMg: _toDouble(
        _firstValue(json, const ['cholesterol_mg', 'cholesterolMg']),
      ),
      calciumMg: _toDouble(
        _firstValue(json, const ['calcium_mg', 'calciumMg']),
      ),
      confidence:
          _firstNonEmptyString(json, const ['confidence', 'confidenceLevel']),
      notes: _firstNonEmptyString(
        json,
        const ['notes', 'note'],
      ),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _toBool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    final raw = value?.toString().trim().toLowerCase() ?? '';
    if (raw == 'true') return true;
    if (raw == 'false') return false;
    return fallback;
  }

  static dynamic _firstValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json.containsKey(key)) {
        return json[key];
      }
    }
    return null;
  }

  static String _firstNonEmptyString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    final value = _firstValue(json, keys);
    return value?.toString().trim() ?? '';
  }

  static List? _firstList(Map<String, dynamic> json, List<String> keys) {
    final value = _firstValue(json, keys);
    return value is List ? value : null;
  }

  static String _normalizeNutritionSource(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    return raw.isEmpty ? defaultNutritionSource : raw;
  }

  static String _normalizeMealCategory(dynamic value) {
    switch ((value?.toString().trim().toLowerCase() ?? '')) {
      case 'makanan berat':
      case 'breakfast':
      case 'sarapan':
      case 'lunch':
      case 'makan siang':
      case 'dinner':
      case 'makan malam':
      case 'food':
      case 'makanan':
        return 'breakfast';
      case 'makanan ringan':
      case 'snack':
      case 'cemilan':
      case 'camilan':
      case 'lainnya':
      case 'other':
        return 'snack';
      case 'minuman':
      case 'drink':
        return 'drink';
      default:
        return 'other';
    }
  }

  static String truncatePortionText(String value) {
    final trimmed = value.trim();
    if (trimmed.length <= maxPortionEstimateLength) return trimmed;
    return trimmed.substring(0, maxPortionEstimateLength);
  }

  Map<String, dynamic> toJson() {
    return {
      'is_food_image': isFoodImage,
      'validation_message': validationMessage,
      'meal_category': mealCategory,
      'detected_foods': detectedFoods,
      'portion_estimate': portionEstimate,
      'portion_grams_estimate': portionGramsEstimate,
      'fdc_food_id': fdcFoodId,
      'nutrition_source': nutritionSource,
      'calories_kcal': caloriesKcal,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'sugar_g': sugarG,
      'fiber_g': fiberG,
      'fat_g': fatG,
      'saturated_fat_g': saturatedFatG,
      'monounsaturated_fat_g': monounsaturatedFatG,
      'polyunsaturated_fat_g': polyunsaturatedFatG,
      'cholesterol_mg': cholesterolMg,
      'calcium_mg': calciumMg,
      'confidence': confidence,
      'notes': notes,
    };
  }

  Map<String, dynamic> toDiaryNutritionPayload() {
    if (!isFoodImage) {
      return const {};
    }

    final payload = <String, dynamic>{
      'nutritionSource': nutritionSource,
      'energyKcal': caloriesKcal,
      'proteinG': proteinG,
      'carbohydrateG': carbsG,
      'sugarG': sugarG,
      'fiberG': fiberG,
      'totalFatG': fatG,
      'saturatedFatG': saturatedFatG,
      'monounsaturatedFatG': monounsaturatedFatG,
      'polyunsaturatedFatG': polyunsaturatedFatG,
      'cholesterolMg': cholesterolMg,
      'calciumMg': calciumMg,
    };

    if (portionGramsEstimate > 0) {
      payload['portionGrams'] = portionGramsEstimate.round();
    }
    if (fdcFoodId.isNotEmpty) {
      payload['fdcFoodId'] = fdcFoodId;
    }

    return payload;
  }

  String get mealCategoryLabel {
    switch (mealCategory) {
      case 'breakfast':
      case 'lunch':
      case 'dinner':
        return 'Makanan Berat';
      case 'snack':
      case 'other':
        return 'Makanan Ringan';
      case 'drink':
        return 'Minuman';
      default:
        return 'Makanan Ringan';
    }
  }

  String get suggestedName => detectedFoods.join(', ');
  bool get hasValidFoodResult => isFoodImage;
}
