import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';

import '../models/food_macro_analysis.dart';

class FoodNutritionEstimateApi {
  FoodNutritionEstimateApi(this._dio);

  final Dio _dio;

  Future<FoodMacroAnalysis> estimateNutrition({
    required Uint8List imageBytes,
    required String mealName,
    required String imageMimeType,
    String? mealDescription,
  }) async {
    final normalizedMealName = mealName.trim();
    final normalizedMealDescription = mealDescription?.trim() ?? '';
    if (normalizedMealName.isEmpty) {
      throw Exception('Nama makanan wajib diisi.');
    }

    final token = await _readBearerToken();
    final userId = await _readUserId();
    final imageBase64 = base64Encode(imageBytes);
    final payload = <String, dynamic>{
      'mealName': normalizedMealName,
      'imageBase64': imageBase64,
      'imageMimeType': imageMimeType,
    };
    if (normalizedMealDescription.isNotEmpty) {
      payload['mealDescription'] = normalizedMealDescription;
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/users/$userId/nutrition-estimates',
        data: payload,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final body = response.data;
      if (body == null) {
        throw Exception('Respons estimasi nutrisi tidak valid dari server.');
      }

      if (body['success'] == false) {
        throw Exception(
          (body['message'] ?? 'Gagal menghitung estimasi nutrisi').toString(),
        );
      }

      final estimatePayload = _extractEstimatePayload(body);
      return FoodMacroAnalysis.fromJson(estimatePayload);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<String> _readBearerToken() async {
    return AppSessionStore.requireToken();
  }

  Future<String> _readUserId() async {
    return AppSessionStore.requireUserId();
  }

  Map<String, dynamic> _extractEstimatePayload(Map<String, dynamic> body) {
    final directData = body['data'];
    if (directData is Map<String, dynamic>) {
      return directData;
    }

    if (directData is Map) {
      return directData.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    return body;
  }

  String _extractErrorMessage(DioException error) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message;
      }
    }

    if (data is Map) {
      final message = data['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message;
      }
    }

    final fallback = error.message?.trim() ?? '';
    if (fallback.isNotEmpty) {
      return fallback;
    }

    return 'Gagal menghitung estimasi nutrisi';
  }
}
