import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/food_macro_analysis.dart';

class FoodMacroLlmService {
  FoodMacroLlmService({
    required String apiKey,
    required String model,
  })  : _apiKey = apiKey,
        _model = model,
        _dio = Dio(
          BaseOptions(
            baseUrl: 'https://api.openai.com/v1',
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 60),
          ),
        );

  final Dio _dio;
  final String _apiKey;
  final String _model;

  Future<FoodMacroAnalysis> analyzeFoodImage(
    File imageFile, {
    String? foodName,
    String? userDescription,
  }) async {
    if (_apiKey.trim().isEmpty) {
      throw Exception(
        'OPENAI_API_KEY belum diatur. Tambahkan key ke file .env terlebih dahulu.',
      );
    }

    final imageBase64 = await _imageToBase64(imageFile);
    final mimeType = _guessMimeType(imageFile.path);
    final prompt = _buildPrompt(
      foodName: foodName?.trim() ?? '',
      userDescription: userDescription?.trim() ?? '',
    );

    final response = await _dio.post<Map<String, dynamic>>(
      '/responses',
      options: Options(
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      ),
      data: {
        'model': _model,
        'input': [
          {
            'role': 'system',
            'content':
                'You analyze food photos and produce concise nutrition estimates for app workflows.',
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_text',
                'text': prompt,
              },
              {
                'type': 'input_image',
                'image_url': 'data:$mimeType;base64,$imageBase64',
                'detail': 'high',
              },
            ],
          },
        ],
        'text': {
          'format': {
            'type': 'json_schema',
            'name': 'food_macro_analysis',
            'strict': true,
            'schema': {
              'type': 'object',
              'additionalProperties': false,
              'properties': {
                'is_food_image': {
                  'type': 'boolean',
                },
                'validation_message': {
                  'type': 'string',
                },
                'detected_foods': {
                  'type': 'array',
                  'items': {
                    'type': 'string',
                  },
                },
                'portion_estimate': {
                  'type': 'string',
                  'maxLength': FoodMacroAnalysis.maxPortionEstimateLength,
                },
                'portion_grams_estimate': {
                  'type': 'number',
                },
                'fdc_food_id': {
                  'type': 'string',
                },
                'nutrition_source': {
                  'type': 'string',
                  'enum': [FoodMacroAnalysis.defaultNutritionSource],
                },
                'calories_kcal': {
                  'type': 'number',
                },
                'protein_g': {
                  'type': 'number',
                },
                'carbs_g': {
                  'type': 'number',
                },
                'sugar_g': {
                  'type': 'number',
                },
                'fiber_g': {
                  'type': 'number',
                },
                'fat_g': {
                  'type': 'number',
                },
                'saturated_fat_g': {
                  'type': 'number',
                },
                'monounsaturated_fat_g': {
                  'type': 'number',
                },
                'polyunsaturated_fat_g': {
                  'type': 'number',
                },
                'cholesterol_mg': {
                  'type': 'number',
                },
                'calcium_mg': {
                  'type': 'number',
                },
                'confidence': {
                  'type': 'string',
                  'enum': ['low', 'medium', 'high'],
                },
                'notes': {
                  'type': 'string',
                },
              },
              'required': [
                'is_food_image',
                'validation_message',
                'detected_foods',
                'portion_estimate',
                'portion_grams_estimate',
                'fdc_food_id',
                'nutrition_source',
                'calories_kcal',
                'protein_g',
                'carbs_g',
                'sugar_g',
                'fiber_g',
                'fat_g',
                'saturated_fat_g',
                'monounsaturated_fat_g',
                'polyunsaturated_fat_g',
                'cholesterol_mg',
                'calcium_mg',
                'confidence',
                'notes',
              ],
            },
          },
        },
        'max_output_tokens': 600,
      },
    );

    final body = response.data;
    if (body == null) {
      throw Exception('Respons OpenAI kosong.');
    }

    final outputText = _extractOutputText(body);
    final decoded = jsonDecode(_stripCodeFence(outputText));

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format hasil analisis makanan tidak valid.');
    }

    return FoodMacroAnalysis.fromJson(decoded);
  }

  Future<String> _imageToBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return base64Encode(bytes);
  }

  String _guessMimeType(String filePath) {
    final dotIndex = filePath.lastIndexOf('.');
    final extension =
        dotIndex >= 0 ? filePath.substring(dotIndex).toLowerCase() : '';
    switch (extension) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.heic':
      case '.heif':
        return 'image/heic';
      case '.jpg':
      case '.jpeg':
      default:
        return 'image/jpeg';
    }
  }

  String _buildPrompt({
    required String foodName,
    required String userDescription,
  }) {
    final foodNameLine = foodName.isEmpty
        ? 'No food name hint was provided.'
        : 'User-provided food name hint: $foodName';
    final descriptionLine = userDescription.isEmpty
        ? 'No additional user description was provided.'
        : 'User description: $userDescription';

    return '''
Analyze this food image and estimate the total macros for all visible food and drink items.

$foodNameLine
$descriptionLine

Return only JSON that matches the schema.

Rules:
- First decide whether the image primarily shows edible food or drink.
- If the image does not clearly show food or drink, return:
  is_food_image = false
  validation_message = a short user-facing message explaining that the image does not look like food or drink and the user should retake the photo
  detected_foods = []
  portion_estimate = ""
  portion_grams_estimate = 0
  all nutrition numbers = 0
  fdc_food_id = ""
  confidence = "low"
  notes = "Non-food image."
- If the image does show food or drink, return is_food_image = true and validation_message = "".
- Estimate total nutrition for the visible portion only.
- If multiple foods are visible, combine the totals.
- Use your best estimate for grams and nutrition even when portions are uncertain.
- Treat the user-provided food name and description as helpful hints, but still verify against the image.
- Keep portion_estimate short, human-readable, and at most ${FoodMacroAnalysis.maxPortionEstimateLength} characters.
- Return all gram-based nutrients in grams and cholesterol_mg/calcium_mg in milligrams.
- Keep sugar_g less than or equal to carbs_g when possible.
- Keep saturated_fat_g + monounsaturated_fat_g + polyunsaturated_fat_g less than or equal to fat_g when possible.
- If you cannot confidently map the food to a USDA FoodData Central item, return an empty string for fdc_food_id.
- Always return nutrition_source as ${FoodMacroAnalysis.defaultNutritionSource}.
- Use 0 only when a value is negligible or truly impossible to infer from the image and description.
- Keep detected_foods short and specific.
- Mention uncertainty honestly in notes.
- Do not give medical advice.
''';
  }

  String _extractOutputText(Map<String, dynamic> body) {
    final direct = body['output_text'];
    if (direct is String && direct.trim().isNotEmpty) {
      return direct;
    }

    final buffer = StringBuffer();
    final output = body['output'];
    if (output is List) {
      for (final item in output) {
        if (item is! Map) continue;
        final content = item['content'];
        if (content is! List) continue;

        for (final segment in content) {
          if (segment is! Map) continue;
          if (segment['type']?.toString() != 'output_text') continue;
          final text = segment['text']?.toString() ?? '';
          if (text.isNotEmpty) {
            buffer.write(text);
          }
        }
      }
    }

    final text = buffer.toString().trim();
    if (text.isEmpty) {
      debugPrint('[FoodMacroLlmService] Unexpected response: $body');
      throw Exception('Respons OpenAI tidak berisi output JSON.');
    }

    return text;
  }

  String _stripCodeFence(String value) {
    final trimmed = value.trim();
    if (!trimmed.startsWith('```')) return trimmed;

    return trimmed
        .replaceFirst(RegExp(r'^```[a-zA-Z0-9_-]*\s*'), '')
        .replaceFirst(RegExp(r'\s*```$'), '')
        .trim();
  }
}
