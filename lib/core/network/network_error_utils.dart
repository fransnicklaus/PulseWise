import 'dart:io';

import 'package:dio/dio.dart';

bool isNetworkRequestError(Object error) {
  if (error is SocketException) {
    return true;
  }

  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return true;
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        break;
    }

    if (error.error is SocketException) {
      return true;
    }

    final message = (error.message ?? '').toLowerCase();
    if (message.contains('failed host lookup') ||
        message.contains('socketexception') ||
        message.contains('connection error')) {
      return true;
    }
  }

  return false;
}
