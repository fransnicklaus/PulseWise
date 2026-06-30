import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiLogger {
  static const _maxStringPreviewLength = 240;
  static const _maxListPreviewLength = 10;

  static void attach(Dio dio) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (kDebugMode) {
            final uri = _fullUri(options);
            if (!_shouldSkipLog(uri)) {
              debugPrint('[API][REQUEST] ${options.method} $uri');
              if (options.queryParameters.isNotEmpty) {
                debugPrint(
                  '[API][QUERY] ${_summarizeValue(options.queryParameters)}',
                );
              }
              if (options.data != null) {
                debugPrint('[API][PAYLOAD] ${_summarizeValue(options.data)}');
              }
            }
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            final uri = _fullUri(response.requestOptions);
            if (!_shouldSkipLog(uri)) {
              debugPrint('[API][RESPONSE] ${response.statusCode} $uri');
              debugPrint('[API][BODY] ${_summarizeValue(response.data)}');
            }
          }
          handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            final uri = _fullUri(error.requestOptions);
            if (!_shouldSkipLog(uri)) {
              debugPrint(
                '[API][ERROR] ${error.response?.statusCode ?? '-'} '
                '${error.requestOptions.method} $uri',
              );
              debugPrint(
                '[API][ERROR_BODY] ${_summarizeValue(error.response?.data)}',
              );
              debugPrint('[API][ERROR_MESSAGE] ${error.message}');
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  static String _fullUri(RequestOptions options) {
    return options.uri.toString();
  }

  static bool _shouldSkipLog(String uri) {
    final path = Uri.tryParse(uri)?.path.toLowerCase() ?? uri.toLowerCase();
    return path.contains('/education') || path.contains('/edukasi');
  }

  static Object? _summarizeValue(dynamic value, {String? key}) {
    if (value is Map) {
      return value.map(
        (entryKey, entryValue) => MapEntry(
          entryKey,
          _summarizeValue(entryValue, key: entryKey.toString()),
        ),
      );
    }

    if (value is List) {
      final preview = value
          .take(_maxListPreviewLength)
          .map((item) => _summarizeValue(item))
          .toList();
      if (value.length > _maxListPreviewLength) {
        preview.add('...(+${value.length - _maxListPreviewLength} items)');
      }
      return preview;
    }

    if (value is String) {
      final normalizedKey = (key ?? '').toLowerCase();
      if (normalizedKey.contains('base64')) {
        return '<base64 ${value.length} chars>';
      }
      if (value.length > _maxStringPreviewLength) {
        return '${value.substring(0, _maxStringPreviewLength)}... '
            '<${value.length} chars>';
      }
      return value;
    }

    return value;
  }
}
