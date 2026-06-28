import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/medication/data/models/medication_models.dart';

void main() {
  group('MedicationListResponse', () {
    test('parses medication items with reminders and pagination', () {
      final response = MedicationListResponse.fromJson({
        'items': [
          {
            'medicationId': 'med-1',
            'userId': 'user-1',
            'name': 'Aspirin',
            'description': 'Obat harian',
            'conditionTag': 'morning',
            'form': 'tablet',
            'color': '#FFFFFF',
            'singleDose': 1.5,
            'singleDoseUnit': 'tablet',
            'startDate': '2026-06-28T00:00:00.000Z',
            'frequency': 'daily',
            'numOfDays': 7,
            'daysOfWeek': [1, 3, 5],
            'intakeTimes': ['08:00', '20:00'],
            'note': 'Sesudah makan',
            'createdAt': '2026-06-27T10:00:00.000Z',
            'reminders': [
              {
                'reminderId': 'reminder-1',
                'userId': 'user-1',
                'medicationId': 'med-1',
                'scheduleTime': '08:00',
                'dayOfWeek': 1,
                'createdAt': '2026-06-27T10:00:00.000Z',
              },
            ],
          },
        ],
        'pagination': {
          'page': 2,
          'limit': 5,
          'totalItems': 6,
          'totalPages': 2,
        },
      });

      final item = response.items.single;
      expect(item.medicationId, 'med-1');
      expect(item.singleDose, 1.5);
      expect(item.startDate, DateTime.parse('2026-06-28T00:00:00.000Z'));
      expect(item.daysOfWeek, [1, 3, 5]);
      expect(item.intakeTimes, ['08:00', '20:00']);
      expect(item.reminders.single.reminderId, 'reminder-1');
      expect(response.pagination.page, 2);
      expect(response.pagination.totalPages, 2);
    });

    test('uses defaults for missing optional fields', () {
      final response = MedicationListResponse.fromJson({
        'items': [
          {
            'medicationId': 'med-1',
            'userId': 'user-1',
            'name': 'Aspirin',
          },
        ],
      });

      final item = response.items.single;
      expect(item.description, isNull);
      expect(item.form, '');
      expect(item.color, '');
      expect(item.singleDose, 0);
      expect(item.startDate, isNull);
      expect(item.daysOfWeek, isEmpty);
      expect(item.intakeTimes, isEmpty);
      expect(item.reminders, isEmpty);
      expect(response.pagination.page, 1);
      expect(response.pagination.limit, 10);
    });
  });

  group('MedicationCalendarResponse', () {
    test('parses range and calendar items', () {
      final response = MedicationCalendarResponse.fromJson({
        'range': {
          'from': '2026-06-01T00:00:00.000Z',
          'to': '2026-06-30T00:00:00.000Z',
        },
        'totalItems': 1,
        'items': [
          {
            'eventId': 'event-1',
            'scheduledDate': '2026-06-28T00:00:00.000Z',
            'scheduledTime': '08:00',
            'reminderId': 'reminder-1',
            'medicationId': 'med-1',
            'medicationLogId': 'log-1',
            'name': 'Aspirin',
            'color': '#FFFFFF',
            'singleDose': 1,
            'singleDoseUnit': 'tablet',
            'status': 'taken',
          },
        ],
      });

      expect(response.range.from, DateTime.parse('2026-06-01T00:00:00.000Z'));
      expect(response.range.to, DateTime.parse('2026-06-30T00:00:00.000Z'));
      expect(response.totalItems, 1);
      expect(response.items.single.eventId, 'event-1');
      expect(response.items.single.status, 'taken');
    });

    test('uses defaults for empty calendar payload', () {
      final response = MedicationCalendarResponse.fromJson({});

      expect(response.range.from, isNull);
      expect(response.range.to, isNull);
      expect(response.totalItems, 0);
      expect(response.items, isEmpty);
    });
  });

  group('MedicationLogResponse', () {
    test('parses logs, summary, and pagination', () {
      final response = MedicationLogResponse.fromJson({
        'items': [
          {
            'medicationLogId': 'log-1',
            'userId': 'user-1',
            'medicationId': 'med-1',
            'status': 'taken',
            'medicationDate': '2026-06-28T00:00:00.000Z',
            'medicationTime': '08:00',
            'createdAt': '2026-06-28T08:05:00.000Z',
          },
        ],
        'pagination': {
          'page': 1,
          'limit': 10,
          'totalItems': 1,
          'totalPages': 1,
        },
        'summary': {
          'taken': 1,
          'skipped': 2,
          'missed': 3,
        },
      });

      expect(response.items.single.medicationLogId, 'log-1');
      expect(response.items.single.medicationDate,
          DateTime.parse('2026-06-28T00:00:00.000Z'));
      expect(response.summary.taken, 1);
      expect(response.summary.skipped, 2);
      expect(response.summary.missed, 3);
    });

    test('uses empty summary defaults when fields are absent', () {
      final response = MedicationLogResponse.fromJson({});

      expect(response.items, isEmpty);
      expect(response.summary.taken, 0);
      expect(response.summary.skipped, 0);
      expect(response.summary.missed, 0);
      expect(const MedicationLogSummary.empty().taken, 0);
    });
  });
}
