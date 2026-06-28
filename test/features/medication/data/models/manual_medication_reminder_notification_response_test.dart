import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/medication/data/models/manual_medication_reminder_notification_response.dart';

void main() {
  group('ManualMedicationReminderNotificationResponse', () {
    test('parses full response with delivery results', () {
      final response = ManualMedicationReminderNotificationResponse.fromJson({
        'success': true,
        'message': 'Reminder terkirim',
        'data': {
          'userId': 'user-1',
          'notificationType': 'medication_reminder',
          'sentCount': 2,
          'failedCount': 1,
          'results': [
            {
              'status': 'sent',
              'platform': 'android',
              'messageId': 'msg-1',
              'error': null,
            },
            {
              'status': 'failed',
              'platform': 'ios',
              'messageId': null,
              'error': 'Token invalid',
            },
          ],
        },
      });

      expect(response.success, isTrue);
      expect(response.message, 'Reminder terkirim');
      expect(response.data!.userId, 'user-1');
      expect(response.data!.sentCount, 2);
      expect(response.data!.failedCount, 1);
      expect(response.data!.results.first.status, 'sent');
      expect(response.data!.results.last.error, 'Token invalid');
    });

    test('uses default values for incomplete response', () {
      final response = ManualMedicationReminderNotificationResponse.fromJson({
        'success': false,
        'data': {
          'results': [<String, dynamic>{}],
        },
      });

      expect(response.success, isFalse);
      expect(response.message, '');
      expect(response.data!.userId, '');
      expect(response.data!.notificationType, '');
      expect(response.data!.sentCount, 0);
      expect(response.data!.failedCount, 0);
      expect(response.data!.results.single.status, '');
    });

    test('sets data to null when data payload is absent', () {
      final response = ManualMedicationReminderNotificationResponse.fromJson({
        'success': true,
        'message': 'OK',
      });

      expect(response.data, isNull);
    });
  });
}
