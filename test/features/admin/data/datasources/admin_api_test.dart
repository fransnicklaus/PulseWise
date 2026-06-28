import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/admin/data/datasources/admin_api.dart';
import 'package:pulsewise/features/admin/data/models/admin_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      AppSessionStore.tokenPrefsKey: 'admin-token',
    });
  });

  group('AdminApi', () {
    test('fetchUsers sends authorized request with trimmed filters', () async {
      late RequestOptions observedOptions;
      final api = AdminApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          return const _FakeDioResponse({
            'success': true,
            'data': {
              'items': [
                {
                  'userId': 'user-1',
                  'username': 'patientone',
                  'email': 'patient@pulsewise.local',
                  'accountStatus': AdminAccountStatuses.active,
                  'role': AdminManagedRoles.patient,
                },
              ],
              'pagination': {
                'page': 2,
                'limit': 10,
                'totalItems': 11,
                'totalPages': 2,
              },
            },
          });
        },
      )));

      final data = await api.fetchUsers(
        page: 2,
        limit: 10,
        query: ' doctor ',
        role: ' admin ',
        accountStatus: ' active ',
      );

      expect(observedOptions.method, 'GET');
      expect(observedOptions.path, '/admin/users');
      expect(observedOptions.headers['Authorization'], 'Bearer admin-token');
      expect(observedOptions.queryParameters, {
        'page': 2,
        'limit': 10,
        'q': 'doctor',
        'role': 'admin',
        'accountStatus': 'active',
      });
      expect(data.items.single.userId, 'user-1');
      expect(data.pagination.totalPages, 2);
    });

    test('updateUserStatus sends request body and parses mutation result',
        () async {
      Object? observedBody;
      late RequestOptions observedOptions;
      final api = AdminApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (options) {
          observedOptions = options;
          observedBody = options.data;
          return const _FakeDioResponse({
            'success': true,
            'message': 'Status pengguna diperbarui',
          });
        },
      )));

      final result = await api.updateUserStatus(
        'user-1',
        const AdminUpdateUserStatusRequest(
          accountStatus: AdminAccountStatuses.suspended,
        ),
      );

      expect(observedOptions.method, 'PATCH');
      expect(observedOptions.path, '/admin/users/user-1/status');
      expect(observedBody, {
        'accountStatus': AdminAccountStatuses.suspended,
      });
      expect(result.success, isTrue);
      expect(result.message, 'Status pengguna diperbarui');
    });

    test('fetchOverview throws backend message when success is false',
        () async {
      final api = AdminApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) => const _FakeDioResponse({
          'success': false,
          'message': 'Admin overview ditolak',
        }),
      )));

      expect(
        api.fetchOverview,
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Admin overview ditolak'),
          ),
        ),
      );
    });

    test('fetchDoctors maps Dio bad response message to exception', () async {
      final api = AdminApi(_dioWithAdapter(_FakeDioAdapter(
        handler: (_) => const _FakeDioResponse(
          {
            'success': false,
            'message': 'Akses admin diperlukan',
          },
          statusCode: 403,
        ),
      )));

      expect(
        () => api.fetchDoctors(),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Akses admin diperlukan'),
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
