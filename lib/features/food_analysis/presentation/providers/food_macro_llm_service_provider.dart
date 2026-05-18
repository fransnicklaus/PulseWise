import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/features/food_analysis/data/services/food_macro_llm_service.dart';

final foodMacroLlmServiceProvider = Provider<FoodMacroLlmService>((ref) {
  return FoodMacroLlmService(
    apiKey: dotenv.env['OPENAI_API_KEY'] ?? '',
    model: dotenv.env['OPENAI_FOOD_ANALYSIS_MODEL'] ?? 'gpt-5.4-mini',
  );
});
