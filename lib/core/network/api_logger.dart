import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiLogger {
  static void attach(Dio dio) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (kDebugMode) {
            final uri = _fullUri(options);
            debugPrint('[API][REQUEST] ${options.method} $uri');
            if (options.queryParameters.isNotEmpty) {
              debugPrint('[API][QUERY] ${options.queryParameters}');
            }
            if (options.data != null) {
              debugPrint('[API][PAYLOAD] ${options.data}');
            }
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            final uri = _fullUri(response.requestOptions);
            debugPrint('[API][RESPONSE] ${response.statusCode} $uri');
            debugPrint('[API][BODY] ${response.data}');
          }
          handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            final uri = _fullUri(error.requestOptions);
            debugPrint(
              '[API][ERROR] ${error.response?.statusCode ?? '-'} '
              '${error.requestOptions.method} $uri',
            );
            debugPrint('[API][ERROR_BODY] ${error.response?.data}');
            debugPrint('[API][ERROR_MESSAGE] ${error.message}');
          }
          handler.next(error);
        },
      ),
    );
  }

  static String _fullUri(RequestOptions options) {
    return options.uri.toString();
  }
}
