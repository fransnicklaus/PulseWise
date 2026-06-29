import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/medication/data/datasources/manual_medication_reminder_notification_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      AppSessionStore.tokenPrefsKey: 'med-token',
    });
  });

  group('ManualMedicationReminderNotificationApi', () {
    test('sendReminder sends authorized request with formatted schedule',
        () async {
      late RequestOptions observedOptions;
      final api = ManualMedicationReminderNotificationApi(
        _dioWithAdapter(_FakeDioAdapter(
          handler: (options) {
            observedOptions = options;
            return const _FakeDioResponse({
              'success': true,
              'message': 'Reminder sent',
              'data': {
                'userId': 'patient-1',
                'notificationType': 'manual_medication_reminder',
                'sentCount': 1,
                'failedCount': 0,
                'results': [
                  {
                    'status': 'sent',
                    'platform': 'android',
                    'messageId': 'msg-1',
                  },
                ],
              },
            });
          },
        )),
      );

      final response = await api.sendReminder(
        userId: 'patient-1',
        medicationId: 'med-1',
        reminderId: 'rem-1',
        scheduledAt: DateTime(2026, 6, 29, 8, 5),
        status: 'Open',
      );

      expect(observedOptions.method, 'POST');
      expect(
        observedOptions.path,
        '/users/patient-1/medications/med-1/reminder-notification',
      );
      expect(observedOptions.headers['Authorization'], 'Bearer med-token');
      expect(observedOptions.data, {
        'reminderId': 'rem-1',
        'scheduledDate': '2026-06-29',
        'scheduledTime': '08:05',
        'status': 'Open',
      });
      expect(response.success, isTrue);
      expect(response.data!.sentCount, 1);
      expect(response.data!.results.single.messageId, 'msg-1');
    });

    test('sendReminder maps unsuccessful backend response message', () async {
      final api = ManualMedicationReminderNotificationApi(
        _dioWithAdapter(_FakeDioAdapter(
          handler: (_) => const _FakeDioResponse({
            'success': false,
            'message': 'Reminder tidak dapat dikirim',
          }),
        )),
      );

      await expectLater(
        api.sendReminder(
          userId: 'patient-1',
          medicationId: 'med-1',
          reminderId: 'rem-1',
          scheduledAt: DateTime(2026, 6, 29, 8),
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Reminder tidak dapat dikirim'),
          ),
        ),
      );
    });

    test('sendReminder maps Dio backend error message', () async {
      final api = ManualMedicationReminderNotificationApi(
        _dioWithAdapter(_FakeDioAdapter(
          handler: (_) => const _FakeDioResponse(
            {
              'success': false,
              'message': 'Token reminder invalid',
            },
            statusCode: 401,
          ),
        )),
      );

      await expectLater(
        api.sendReminder(
          userId: 'patient-1',
          medicationId: 'med-1',
          reminderId: 'rem-1',
          scheduledAt: DateTime(2026, 6, 29, 8),
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Token reminder invalid'),
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
