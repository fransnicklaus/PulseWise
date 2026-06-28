import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/home_dashboard/data/models/dashboard_overview_models.dart';

void main() {
  group('DashboardVitalsResponse', () {
    test('parses patient, period, series, and latest vitals', () {
      final response = DashboardVitalsResponse.fromJson({
        'success': true,
        'message': 'OK',
        'data': {
          'patient': {
            'patientId': 'patient-1',
            'firstName': 'Ayu',
            'lastName': 'Putri',
            'avatar_photo': ' avatar.png ',
            'email': 'ayu@example.com',
            'phone': '+62812345678',
            'dateOfBirth': '1990-01-02',
            'age': 36,
            'sex': 'female',
          },
          'period': {
            'startAt': '2026-06-01',
            'endAt': '2026-06-29',
            'timePeriod': 'last_30_days',
          },
          'series': {
            'timestamps': ['2026-06-28', '2026-06-29'],
            'systolicBp': [120, 121],
            'diastolicBp': [80, null],
            'heartRate': [70, 72],
            'oxygenSaturation': [98, 97],
            'weight': [60.5],
            'height': [165],
            'bmi': [22.2],
          },
          'latestVitals': {
            'measuredAt': '2026-06-29T08:00:00.000Z',
            'systolicBp': 121,
            'diastolicBp': 80,
            'heartRate': 72,
            'oxygenSaturation': 97,
            'weight': 60.5,
            'height': 165,
            'bmi': 22.2,
          },
        },
      });

      final data = response.data!;

      expect(response.success, isTrue);
      expect(response.message, 'OK');
      expect(data.patient.patientId, 'patient-1');
      expect(data.patient.avatarPhoto, 'avatar.png');
      expect(data.patient.age, 36);
      expect(data.period.timePeriod, 'last_30_days');
      expect(data.series.timestamps, ['2026-06-28', '2026-06-29']);
      expect(data.series.diastolicBp, [80, null]);
      expect(data.latestVitals!.measuredAt, '2026-06-29T08:00:00.000Z');
      expect(data.latestVitals!.heartRate, 72);
    });

    test('returns null data and defaults failed response fields', () {
      final response = DashboardVitalsResponse.fromJson({});

      expect(response.success, isFalse);
      expect(response.message, '');
      expect(response.data, isNull);
    });
  });

  group('DashboardSeries', () {
    test('uses empty lists for absent series fields', () {
      final series = DashboardSeries.fromJson({});

      expect(series.timestamps, isEmpty);
      expect(series.systolicBp, isEmpty);
      expect(series.diastolicBp, isEmpty);
      expect(series.heartRate, isEmpty);
      expect(series.oxygenSaturation, isEmpty);
      expect(series.weight, isEmpty);
      expect(series.height, isEmpty);
      expect(series.bmi, isEmpty);
    });
  });

  group('QuickDashboardResponse', () {
    test('parses latest vitals and field measurements', () {
      final response = QuickDashboardResponse.fromJson({
        'success': true,
        'message': 'OK',
        'data': {
          'patient': {
            'patientId': 'patient-1',
            'firstName': 'Ayu',
            'lastName': 'Putri',
          },
          'latestVitals': {
            'heartRate': 72,
            'oxygenSaturation': 97,
          },
          'latestVitalsByField': {
            'heartRate': {
              'value': 72,
              'measuredAt': '2026-06-29T08:00:00.000Z',
            },
            'weight': {
              'value': 60.5,
              'measuredAt': null,
            },
            'empty': null,
          },
        },
      });

      final data = response.data!;

      expect(response.success, isTrue);
      expect(data.patient.patientId, 'patient-1');
      expect(data.latestVitals!.oxygenSaturation, 97);
      expect(data.latestVitalsByField['heartRate']!.value, 72);
      expect(
        data.latestVitalsByField['heartRate']!.measuredAt,
        '2026-06-29T08:00:00.000Z',
      );
      expect(data.latestVitalsByField['weight']!.value, 60.5);
      expect(data.latestVitalsByField['empty']!.value, isNull);
    });

    test('uses empty dashboard data defaults', () {
      final response = QuickDashboardResponse.fromJson({
        'success': true,
        'data': <String, dynamic>{},
      });

      expect(response.success, isTrue);
      expect(response.message, '');
      expect(response.data!.patient.patientId, '');
      expect(response.data!.latestVitals, isNull);
      expect(response.data!.latestVitalsByField, isEmpty);
    });
  });
}
