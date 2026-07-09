import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/food_analysis/data/datasources/food_nutrition_estimate_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      AppSessionStore.tokenPrefsKey: 'food-token',
      AppSessionStore.userIdPrefsKey: 'patient-1',
    });
  });

  group('FoodNutritionEstimateApi', () {
    test('estimateNutrition sends authorized image payload and parses data',
        () async {
      late RequestOptions observedOptions;
      final imageBytes = Uint8List.fromList([1, 2, 3, 4]);
      final api = FoodNutritionEstimateApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return _successResponse({
            'is_food_image': true,
            'meal_category': 'Makanan Berat',
            'detected_foods': ['Nasi goreng'],
            'calories_kcal': 320,
            'protein_g': 12,
          });
        },
      )));

      final analysis = await api.estimateNutrition(
        imageBytes: imageBytes,
        mealName: ' Nasi Goreng ',
        imageMimeType: 'image/jpeg',
        mealDescription: ' Pedas ',
      );

      expect(observedOptions.method, 'POST');
      expect(observedOptions.path, '/users/patient-1/nutrition-estimates');
      expect(
        observedOptions.receiveTimeout,
        FoodNutritionEstimateApi.nutritionEstimateTimeout,
      );
      expect(observedOptions.headers['Authorization'], 'Bearer food-token');
      expect(observedOptions.data, {
        'mealName': 'Nasi Goreng',
        'imageBase64': base64Encode(imageBytes),
        'imageMimeType': 'image/jpeg',
        'mealDescription': 'Pedas',
      });
      expect(analysis.detectedFoods, ['Nasi goreng']);
      expect(analysis.caloriesKcal, 320);
      expect(analysis.proteinG, 12);
    });

    test('estimateNutrition omits blank descriptions and accepts direct body',
        () async {
      late Map<String, dynamic> observedBody;
      final api = FoodNutritionEstimateApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedBody = Map<String, dynamic>.from(options.data as Map);
          return const _FakeDioResponse({
            'success': true,
            'mealName': 'Apple',
            'mealCategory': 'snack',
            'energyKcal': 95,
          });
        },
      )));

      final analysis = await api.estimateNutrition(
        imageBytes: Uint8List.fromList([5, 6]),
        mealName: 'Apple',
        imageMimeType: 'image/png',
        mealDescription: '   ',
      );

      expect(observedBody.containsKey('mealDescription'), isFalse);
      expect(analysis.detectedFoods, ['Apple']);
      expect(analysis.mealCategory, 'snack');
      expect(analysis.caloriesKcal, 95);
    });

    test('estimateNutrition validates meal name before sending request',
        () async {
      var called = false;
      final api = FoodNutritionEstimateApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) {
          called = true;
          return _successResponse({});
        },
      )));

      await expectLater(
        api.estimateNutrition(
          imageBytes: Uint8List.fromList([1]),
          mealName: '   ',
          imageMimeType: 'image/jpeg',
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Nama makanan wajib diisi.'),
          ),
        ),
      );
      expect(called, isFalse);
    });

    test('estimateNutrition maps backend error messages', () async {
      final api = FoodNutritionEstimateApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) => const _FakeDioResponse(
          {
            'success': false,
            'message': 'Foto makanan tidak jelas',
          },
          statusCode: 400,
        ),
      )));

      await expectLater(
        api.estimateNutrition(
          imageBytes: Uint8List.fromList([1]),
          mealName: 'Soup',
          imageMimeType: 'image/jpeg',
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Foto makanan tidak jelas'),
          ),
        ),
      );
    });
  });
}

_FakeDioResponse _successResponse(Object data) {
  return _FakeDioResponse({
    'success': true,
    'message': 'OK',
    'data': data,
  });
}

Dio _dioWithAdapter(HttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.pulsewise.test'));
  dio.httpClientAdapter = adapter;
  return dio;
}

class _FakeDioResponse {
  const _FakeDioResponse(
    this.body, {
    this.statusCode = 200,
  });

  final Map<String, dynamic> body;
  final int statusCode;
}

class _FakeDioAdapter implements HttpClientAdapter {
  _FakeDioAdapter({required this.handler});

  final FutureOr<_FakeDioResponse> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final response = await handler(options);
    return ResponseBody.fromString(
      jsonEncode(response.body),
      response.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
