import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/food_macro_analysis.dart';

class FoodNutritionEstimateApi {
  FoodNutritionEstimateApi(this._dio);

  final Dio _dio;

  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'auth_user_id';

  Future<FoodMacroAnalysis> estimateNutrition({
    required File imageFile,
    required String mealName,
    String? mealDescription,
  }) async {
    final normalizedMealName = mealName.trim();
    final normalizedMealDescription = mealDescription?.trim() ?? '';
    if (normalizedMealName.isEmpty) {
      throw Exception('Nama makanan wajib diisi.');
    }

    final token = await _readBearerToken();
    final userId = await _readUserId();
    final imageBase64 = await _imageToBase64(imageFile);
    final imageMimeType = _guessMimeType(imageFile.path);
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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey) ??
        dotenv.env['AUTH_TOKEN'] ??
        dotenv.env['BEARER_TOKEN'] ??
        '';

    if (token.isEmpty) {
      throw Exception('Bearer token tidak ditemukan. Silakan login ulang.');
    }

    return token;
  }

  Future<String> _readUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId =
        prefs.getString(_userIdKey) ?? dotenv.env['PATIENT_ID'] ?? '';

    if (userId.isEmpty) {
      throw Exception('userId tidak ditemukan. Silakan login ulang.');
    }

    return userId;
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
