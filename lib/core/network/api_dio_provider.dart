import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/config/app_env.dart';
import 'package:pulsewise/core/network/api_logger.dart';

const defaultApiBaseUrl = 'https://pulsewise-api.algoritme.tech';

String resolveApiBaseUrl() {
  final configuredBaseUrl = AppEnv.apiBaseUrl.trim();
  return configuredBaseUrl.isEmpty ? defaultApiBaseUrl : configuredBaseUrl;
}

Dio createApiDio(String baseUrl) {
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
}

final apiBaseUrlProvider = Provider<String>((ref) {
  return resolveApiBaseUrl();
});

final apiDioProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return createApiDio(baseUrl);
});
