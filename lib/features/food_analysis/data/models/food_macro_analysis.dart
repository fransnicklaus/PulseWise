class FoodMacroAnalysis {
  static const defaultNutritionSource = 'openai_vision_estimate';
  static const maxPortionEstimateLength = 255;

  final bool isFoodImage;
  final String validationMessage;
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
    return FoodMacroAnalysis(
      isFoodImage: _toBool(json['is_food_image'], fallback: true),
      validationMessage: (json['validation_message'] ?? '').toString().trim(),
      detectedFoods: ((json['detected_foods'] as List?) ?? const [])
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(),
      portionEstimate:
          truncatePortionText((json['portion_estimate'] ?? '').toString()),
      portionGramsEstimate: _toDouble(json['portion_grams_estimate']),
      fdcFoodId:
          (json['fdc_food_id'] ?? json['fdcFoodId'] ?? '').toString().trim(),
      nutritionSource: _normalizeNutritionSource(
          json['nutrition_source'] ?? json['nutritionSource']),
      caloriesKcal: _toDouble(json['calories_kcal']),
      proteinG: _toDouble(json['protein_g']),
      carbsG: _toDouble(json['carbs_g']),
      sugarG: _toDouble(json['sugar_g']),
      fiberG: _toDouble(json['fiber_g']),
      fatG: _toDouble(json['fat_g']),
      saturatedFatG: _toDouble(json['saturated_fat_g']),
      monounsaturatedFatG: _toDouble(json['monounsaturated_fat_g']),
      polyunsaturatedFatG: _toDouble(json['polyunsaturated_fat_g']),
      cholesterolMg: _toDouble(json['cholesterol_mg']),
      calciumMg: _toDouble(json['calcium_mg']),
      confidence: (json['confidence'] ?? '').toString().trim(),
      notes: (json['notes'] ?? '').toString().trim(),
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

  static String _normalizeNutritionSource(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    return raw.isEmpty ? defaultNutritionSource : raw;
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

  String get suggestedName => detectedFoods.join(', ');
  bool get hasValidFoodResult => isFoodImage;
}
