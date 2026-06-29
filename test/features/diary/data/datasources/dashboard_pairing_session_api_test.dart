import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/diary/data/datasources/dashboard_pairing_session_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      AppSessionStore.tokenPrefsKey: 'patient-token',
    });
  });

  group('DashboardPairingSessionApi', () {
    test('confirmPairing sends authorized request with normalized token',
        () async {
      late RequestOptions observedOptions;
      final api = DashboardPairingSessionApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return const _FakeDioResponse({
            'success': true,
            'message': 'Dashboard tersambung',
          });
        },
      )));

      final message = await api.confirmPairing(
        pairingToken: ' qr-token-1 ',
        source: 'manual_scan',
      );

      expect(observedOptions.method, 'POST');
      expect(
        observedOptions.path,
        '/dashboard/pairing-sessions/confirm',
      );
      expect(observedOptions.headers['Authorization'], 'Bearer patient-token');
      expect(observedOptions.data, {
        'pairingToken': 'qr-token-1',
        'source': 'manual_scan',
      });
      expect(message, 'Dashboard tersambung');
    });

    test(
        'confirmPairing returns fallback success message when message is blank',
        () async {
      final api = DashboardPairingSessionApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) => const _FakeDioResponse({
          'success': true,
          'message': '   ',
        }),
      )));

      final message = await api.confirmPairing(pairingToken: 'qr-token-1');

      expect(message, 'Dashboard dokter berhasil dihubungkan');
    });

    test('confirmPairing validates blank pairing token before request',
        () async {
      var called = false;
      final api = DashboardPairingSessionApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) {
          called = true;
          return const _FakeDioResponse({'success': true});
        },
      )));

      await expectLater(
        api.confirmPairing(pairingToken: '   '),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('QR pairing token tidak valid.'),
          ),
        ),
      );
      expect(called, isFalse);
    });

    test('confirmPairing maps backend error message', () async {
      final api = DashboardPairingSessionApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) => const _FakeDioResponse(
          {
            'success': false,
            'message': 'Pairing token kedaluwarsa',
          },
          statusCode: 400,
        ),
      )));

      await expectLater(
        api.confirmPairing(pairingToken: 'expired-token'),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Pairing token kedaluwarsa'),
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
