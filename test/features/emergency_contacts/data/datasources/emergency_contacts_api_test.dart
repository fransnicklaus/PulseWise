import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/emergency_contacts/data/datasources/emergency_contacts_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      AppSessionStore.tokenPrefsKey: 'contact-token',
      AppSessionStore.userIdPrefsKey: 'patient-1',
    });
  });

  group('EmergencyContactsApi', () {
    test('addEmergencyContact sends authorized payload', () async {
      late RequestOptions observedOptions;
      final api = EmergencyContactsApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return _successResponse();
        },
      )));

      await api.addEmergencyContact(
        contactLabel: 'Ibu',
        contactNumber: '08123',
        isPriority: true,
      );

      expect(observedOptions.method, 'POST');
      expect(observedOptions.path, '/users/patient-1/emergency-contacts');
      expect(observedOptions.headers['Authorization'], 'Bearer contact-token');
      expect(observedOptions.data, {
        'contactLabel': 'Ibu',
        'contactNumber': '08123',
        'isPriority': true,
      });
    });

    test('update, priority update, and delete use expected requests', () async {
      final observed = <RequestOptions>[];
      final api = EmergencyContactsApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observed.add(options);
          return _successResponse();
        },
      )));

      await api.updateEmergencyContact(
        emergencyContactId: 'contact-1',
        contactLabel: 'Ayah',
        contactNumber: '08456',
        isPriority: false,
      );
      await api.updateEmergencyContactPriority(
        emergencyContactId: 'contact-1',
        contactLabel: 'Ayah',
        isPriority: true,
      );
      await api.deleteEmergencyContact('contact-1');

      expect(observed[0].method, 'PUT');
      expect(
        observed[0].path,
        '/users/patient-1/emergency-contacts/contact-1',
      );
      expect(observed[0].data, {
        'contactLabel': 'Ayah',
        'contactNumber': '08456',
        'isPriority': false,
      });
      expect(observed[1].method, 'PUT');
      expect(observed[1].data, {
        'contactLabel': 'Ayah',
        'isPriority': true,
      });
      expect(observed[2].method, 'DELETE');
      expect(
        observed[2].path,
        '/users/patient-1/emergency-contacts/contact-1',
      );
    });

    test('fetchPage sends pagination and computes hasMore', () async {
      late RequestOptions observedOptions;
      final api = EmergencyContactsApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return const _FakeDioResponse({
            'success': true,
            'data': {
              'items': [
                {
                  'emergencyContactId': 'contact-1',
                  'userId': 'patient-1',
                  'contactLabel': 'Ibu',
                  'contactNumber': '08123',
                  'isPriority': true,
                },
              ],
              'pagination': {
                'page': 1,
                'limit': 10,
                'totalPages': 2,
              },
            },
          });
        },
      )));

      final page = await api.fetchPage(page: 1, limit: 10);

      expect(observedOptions.method, 'GET');
      expect(observedOptions.path, '/users/patient-1/emergency-contacts');
      expect(observedOptions.queryParameters, {'page': 1, 'limit': 10});
      expect(page.items.single.emergencyContactId, 'contact-1');
      expect(page.page, 1);
      expect(page.hasMore, isTrue);
    });

    test('fetchPage maps Dio backend error message', () async {
      final api = EmergencyContactsApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) => const _FakeDioResponse(
          {
            'success': false,
            'message': 'Kontak darurat ditolak',
          },
          statusCode: 403,
        ),
      )));

      await expectLater(
        api.fetchPage(page: 1, limit: 10),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Kontak darurat ditolak'),
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
