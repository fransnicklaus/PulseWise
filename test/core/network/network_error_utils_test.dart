import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/network/network_error_utils.dart';

void main() {
  group('isNetworkRequestError', () {
    test('returns true for SocketException', () {
      expect(isNetworkRequestError(const SocketException('offline')), isTrue);
    });

    test('returns true for Dio timeout and connection errors', () {
      final requestOptions = RequestOptions(path: '/health');

      expect(
        isNetworkRequestError(DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionTimeout,
        )),
        isTrue,
      );
      expect(
        isNetworkRequestError(DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionError,
        )),
        isTrue,
      );
    });

    test('returns true when Dio error wraps a SocketException', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/health'),
        type: DioExceptionType.unknown,
        error: const SocketException('failed host lookup'),
      );

      expect(isNetworkRequestError(error), isTrue);
    });

    test('returns true when Dio message looks like network failure', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/health'),
        type: DioExceptionType.unknown,
        message: 'Failed host lookup: api.example.test',
      );

      expect(isNetworkRequestError(error), isTrue);
    });

    test('returns false for HTTP bad response and non-network errors', () {
      final requestOptions = RequestOptions(path: '/health');
      final response = Response<void>(
        requestOptions: requestOptions,
        statusCode: 500,
      );

      expect(
        isNetworkRequestError(DioException(
          requestOptions: requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        )),
        isFalse,
      );
      expect(isNetworkRequestError(Exception('validation failed')), isFalse);
    });
  });
}
