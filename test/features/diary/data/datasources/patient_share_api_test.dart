import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/diary/data/datasources/patient_share_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      AppSessionStore.tokenPrefsKey: 'patient-token',
      AppSessionStore.userIdPrefsKey: 'patient-1',
    });
  });

  group('PatientShareApi', () {
    test('createShare sends authorized request and parses share payload',
        () async {
      late RequestOptions observedOptions;
      final api = PatientShareApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return const _FakeDioResponse({
            'success': true,
            'message': 'OK',
            'data': {
              'shareId': 'share-1',
              'patientId': 'patient-1',
              'shareCode': 'CODE-1',
              'expiresAt': '2026-06-30T08:00:00.000Z',
              'qrPayload': 'pulsewise://share/CODE-1',
            },
          });
        },
      )));

      final share = await api.createShare(expiresInHours: 12);

      expect(observedOptions.method, 'POST');
      expect(observedOptions.path, '/patients/patient-1/shares');
      expect(observedOptions.headers['Authorization'], 'Bearer patient-token');
      expect(observedOptions.data, {'expiresInHours': 12});
      expect(share.shareId, 'share-1');
      expect(share.patientId, 'patient-1');
      expect(share.qrData, 'pulsewise://share/CODE-1');
    });

    test('createShare accepts snake case payload and qrData fallback',
        () async {
      final api = PatientShareApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) => const _FakeDioResponse({
          'success': true,
          'message': 'OK',
          'data': {
            'share_id': 'share-2',
            'patient_id': 'patient-1',
            'share_code': 'CODE-2',
            'expires_at': '2026-06-30T08:00:00.000Z',
            'qr_payload': '   ',
          },
        }),
      )));

      final share = await api.createShare();

      expect(share.shareId, 'share-2');
      expect(share.shareCode, 'CODE-2');
      expect(share.qrData, 'CODE-2');
    });

    test('createShare rejects successful responses without QR data', () async {
      final api = PatientShareApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) => const _FakeDioResponse({
          'success': true,
          'message': 'OK',
          'data': {
            'shareId': 'share-3',
            'shareCode': '   ',
            'qrPayload': '',
          },
        }),
      )));

      await expectLater(
        api.createShare(),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Payload QR share pasien tidak tersedia.'),
          ),
        ),
      );
    });

    test('createShare maps Dio backend error message', () async {
      final api = PatientShareApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) => const _FakeDioResponse(
          {
            'success': false,
            'message': 'Share pasien ditolak',
          },
          statusCode: 403,
        ),
      )));

      await expectLater(
        api.createShare(),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Share pasien ditolak'),
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
