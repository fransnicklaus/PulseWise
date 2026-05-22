import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/network/api_logger.dart';

const defaultApiBaseUrl = 'https://pulsewise-backend.vercel.app/api/v1';

final apiBaseUrlProvider = Provider<String>((ref) {
  return dotenv.env['API_BASE_URL'] ?? defaultApiBaseUrl;
});

final apiDioProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {
        'Accept': 'application/json',
      },
    ),
  );

  ApiLogger.attach(dio);
  return dio;
});
