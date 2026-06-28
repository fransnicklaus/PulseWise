import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/health_connect/data/datasources/health_connect_setup_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      AppSessionStore.tokenPrefsKey: 'health-token',
      AppSessionStore.userIdPrefsKey: 'patient-1',
    });
  });

  group('HealthConnectSetupApi', () {
    test('updateHealthConnectSetup sends preference only when status omitted',
        () async {
      late RequestOptions observedOptions;
      final api = HealthConnectSetupApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return _successResponse();
        },
      )));

      await api.updateHealthConnectSetup(
        healthConnectPreference: 'connect_later',
      );

      expect(observedOptions.method, 'PUT');
      expect(observedOptions.path, '/patients/patient-1/profile');
      expect(observedOptions.headers['Authorization'], 'Bearer health-token');
      expect(observedOptions.data, {
        'healthConnectPreference': 'connect_later',
      });
    });

    test('updateHealthConnectSetup includes explicit null and concrete status',
        () async {
      final observedBodies = <Map<String, dynamic>>[];
      final api = HealthConnectSetupApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedBodies.add(Map<String, dynamic>.from(options.data as Map));
          return _successResponse();
        },
      )));

      await api.updateHealthConnectSetup(
        healthConnectPreference: 'connect_now',
        healthConnectStatus: null,
      );
      await api.updateHealthConnectSetup(
        healthConnectPreference: 'connect_now',
        healthConnectStatus: 'connected',
      );

      expect(observedBodies, [
        {
          'healthConnectPreference': 'connect_now',
          'healthConnectStatus': null,
        },
        {
          'healthConnectPreference': 'connect_now',
          'healthConnectStatus': 'connected',
        },
      ]);
    });

    test('updateHealthConnectSetup maps unsuccessful response message',
        () async {
      final api = HealthConnectSetupApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) => const _FakeDioResponse({
          'success': false,
          'message': 'Tidak dapat menyimpan preferensi',
        }),
      )));

      await expectLater(
        api.updateHealthConnectSetup(
          healthConnectPreference: 'connect_now',
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Tidak dapat menyimpan preferensi'),
          ),
        ),
      );
    });
  });
}

_FakeDioResponse _successResponse() {
  return const _FakeDioResponse({
    'success': true,
    'message': 'OK',
  });
}

Dio _dioWithAdapter(HttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.pulsewise.test'));
  dio.httpClientAdapter = adapter;
  return dio;
}

class _FakeDioResponse {
  const _FakeDioResponse(this.body);

  final Map<String, dynamic> body;
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
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
