import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/auth/data/datasources/account_deletion_api.dart';
import 'package:pulsewise/features/auth/data/models/account_deletion_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      AppSessionStore.tokenPrefsKey: 'auth-token',
    });
  });

  group('AccountDeletionApi', () {
    test('requestAccountDeletion sends authorized request and parses result',
        () async {
      late RequestOptions observedOptions;
      Object? observedBody;
      final api = AccountDeletionApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          observedBody = options.data;
          return const _FakeDioResponse({
            'success': true,
            'data': {
              'nextStep': 'confirm',
              'requiresReauth': true,
              'reauthMethod': 'password',
              'availableReauthMethods': ['password', 'otp'],
              'deletionToken': 'delete-token',
              'warning': {
                'permanent': true,
                'recoverable': false,
              },
            },
          });
        },
      )));

      final result = await api.requestAccountDeletion(
        confirmationText: accountDeletionConfirmationText,
        reauthMethod: accountDeletionPasswordMethod,
      );

      expect(observedOptions.method, 'POST');
      expect(observedOptions.path, '/auth/account-deletion/request');
      expect(observedOptions.headers['Authorization'], 'Bearer auth-token');
      expect(observedBody, {
        'confirmationText': accountDeletionConfirmationText,
        'reauthMethod': accountDeletionPasswordMethod,
      });
      expect(result.nextStep, 'confirm');
      expect(result.deletionToken, 'delete-token');
      expect(result.availableReauthMethods, [
        accountDeletionPasswordMethod,
        accountDeletionOtpMethod,
      ]);
    });

    test('confirmAccountDeletion trims optional credentials and parses result',
        () async {
      Object? observedBody;
      final api = AccountDeletionApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedBody = options.data;
          return const _FakeDioResponse({
            'success': true,
            'data': {
              'nextStep': 'completed',
              'deleted': true,
              'reauthMethod': 'otp',
              'sessionRevoked': true,
              'deletedAt': '2026-06-29T08:00:00.000Z',
            },
          });
        },
      )));

      final result = await api.confirmAccountDeletion(
        deletionToken: 'delete-token',
        password: ' secret ',
        otp: ' 123456 ',
        googleIdToken: '   ',
      );

      expect(observedBody, {
        'deletionToken': 'delete-token',
        'password': 'secret',
        'otp': '123456',
      });
      expect(result.deleted, isTrue);
      expect(result.sessionRevoked, isTrue);
      expect(result.deletedAt, DateTime.parse('2026-06-29T08:00:00.000Z'));
    });

    test('throws AccountDeletionException with methods and field errors',
        () async {
      final api = AccountDeletionApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) => const _FakeDioResponse({
          'success': false,
          'message': 'Validasi penghapusan gagal',
          'details': {
            'availableReauthMethods': ['password', 'google'],
            'fieldErrors': {
              'confirmationText': ['Teks konfirmasi tidak sesuai'],
              'password': 'Password salah',
            },
          },
        }),
      )));

      await expectLater(
        api.requestAccountDeletion(
          confirmationText: 'SALAH',
          reauthMethod: accountDeletionPasswordMethod,
        ),
        throwsA(
          isA<AccountDeletionException>()
              .having(
            (error) => error.message,
            'message',
            'Validasi penghapusan gagal',
          )
              .having(
            (error) => error.availableReauthMethods,
            'availableReauthMethods',
            [accountDeletionPasswordMethod, accountDeletionGoogleMethod],
          ).having(
            (error) => error.firstFieldError('password'),
            'password field error',
            'Password salah',
          ),
        ),
      );
    });

    test('maps Dio bad response body to AccountDeletionException', () async {
      final api = AccountDeletionApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) => const _FakeDioResponse(
          {
            'success': false,
            'message': 'Token penghapusan kedaluwarsa',
          },
          statusCode: 400,
        ),
      )));

      await expectLater(
        api.confirmAccountDeletion(deletionToken: 'expired-token'),
        throwsA(
          isA<AccountDeletionException>().having(
            (error) => error.message,
            'message',
            'Token penghapusan kedaluwarsa',
          ),
        ),
      );
    });
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
