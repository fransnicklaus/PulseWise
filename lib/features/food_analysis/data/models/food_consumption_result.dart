import 'package:pulsewise/features/food_analysis/data/models/food_macro_analysis.dart';

class FoodMacroCaptureResult {
  final FoodMacroAnalysis analysis;
  final String userFoodName;
  final String userDescription;

  const FoodMacroCaptureResult({
    required this.analysis,
    required this.userFoodName,
    required this.userDescription,
  });

  Map<String, dynamic> toMap() {
    return {
      ...analysis.toJson(),
      'user_food_name': userFoodName,
      'user_description': userDescription,
    };
  }

  factory FoodMacroCaptureResult.fromMap(Map<String, dynamic> json) {
    return FoodMacroCaptureResult(
      analysis: FoodMacroAnalysis.fromJson(json),
      userFoodName: (json['user_food_name'] ?? '').toString().trim(),
      userDescription: (json['user_description'] ?? '').toString().trim(),
    );
  }
}

class ManualFoodConsumptionResult {
  final String typeLabel;
  final String type;
  final String name;
  final String portion;
  final String time;
  final bool useCurrentTime;
  final String note;
  final Map<String, dynamic> nutritionPayload;

  const ManualFoodConsumptionResult({
    required this.typeLabel,
    required this.type,
    required this.name,
    required this.portion,
    required this.time,
    required this.useCurrentTime,
    required this.note,
    required this.nutritionPayload,
  });

  Map<String, dynamic> toMap() {
    return {
      'typeLabel': typeLabel,
      'type': type,
      'name': name,
      'portion': portion,
      'time': time,
      'useCurrentTime': useCurrentTime,
      'note': note,
      'nutritionPayload': nutritionPayload,
    };
  }

  factory ManualFoodConsumptionResult.fromMap(Map<String, dynamic> json) {
    final nutritionPayloadRaw = json['nutritionPayload'];
    return ManualFoodConsumptionResult(
      typeLabel: (json['typeLabel'] ?? '').toString().trim(),
      type: (json['type'] ?? '').toString().trim(),
      name: (json['name'] ?? '').toString().trim(),
      portion: (json['portion'] ?? '').toString().trim(),
      time: (json['time'] ?? '').toString().trim(),
      useCurrentTime: json['useCurrentTime'] == true,
      note: (json['note'] ?? '').toString(),
      nutritionPayload: nutritionPayloadRaw is Map
          ? nutritionPayloadRaw.map(
              (key, value) => MapEntry(key.toString(), value),
            )
          : const {},
    );
  }
}
