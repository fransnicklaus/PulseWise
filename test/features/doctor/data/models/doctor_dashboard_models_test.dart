import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/doctor/data/models/doctor_dashboard_models.dart';

void main() {
  group('DoctorDashboardThresholds', () {
    test('uses provided numeric thresholds and defaults missing values', () {
      final thresholds = DoctorDashboardThresholds.fromJson({
        'SPO2_CRITICAL_THRESHOLD': 88,
        'HR_NORMAL_MIN': 55,
        'BP_STAGE2_DIASTOLIC_MIN': 95,
      });

      expect(thresholds.spo2CriticalThreshold, 88);
      expect(thresholds.hrNormalMin, 55);
      expect(thresholds.bpStage2DiastolicMin, 95);
      expect(thresholds.spo2CautionThreshold, 95);
      expect(thresholds.bpNormalSystolicMax, 119);
    });
  });

  group('DoctorDashboardPatientSummaryResponse', () {
    test('parses nested patient, latest vitals, and thresholds', () {
      final response = DoctorDashboardPatientSummaryResponse.fromJson({
        'success': true,
        'message': 'OK',
        'data': {
          'patient': {
            'patientId': 'patient-1',
            'firstName': 'Ayu',
            'lastName': 'Putri',
            'avatar_photo': ' avatar.png ',
            'email': 'ayu@example.com',
            'age': 41,
            'sex': 'female',
          },
          'latestVitals': {
            'measuredAt': '2026-06-28T08:00:00.000Z',
            'heartRate': 72,
            'bmi': 24.5,
          },
          'thresholds': {
            'SPO2_CAUTION_THRESHOLD': 94,
          },
        },
      });

      final data = response.data!;

      expect(response.success, isTrue);
      expect(response.message, 'OK');
      expect(data.patient.patientId, 'patient-1');
      expect(data.patient.avatarPhoto, 'avatar.png');
      expect(data.patient.age, 41);
      expect(data.latestVitals!.heartRate, 72);
      expect(data.latestVitals!.bmi, 24.5);
      expect(data.thresholds.spo2CautionThreshold, 94);
    });

    test('returns null data when payload is absent', () {
      final response = DoctorDashboardPatientSummaryResponse.fromJson({
        'success': false,
        'message': 'No data',
      });

      expect(response.success, isFalse);
      expect(response.message, 'No data');
      expect(response.data, isNull);
    });
  });

  group('DoctorDashboardPatientVitalsResponse', () {
    test('parses period, series, and latest vitals', () {
      final response = DoctorDashboardPatientVitalsResponse.fromJson({
        'success': true,
        'message': 'OK',
        'data': {
          'patient': {
            'patientId': 'patient-1',
            'firstName': 'Ayu',
            'lastName': 'Putri',
          },
          'period': {
            'startAt': '2026-06-01',
            'endAt': '2026-06-28',
            'timePeriod': 'last_30_days',
          },
          'series': {
            'timestamps': ['2026-06-27', '2026-06-28'],
            'heartRate': [70, null],
            'systolicBp': [120, 122],
            'diastolicBp': [80, 81],
          },
          'latestVitals': {
            'oxygenSaturation': 97,
          },
        },
      });

      final data = response.data!;

      expect(data.period.timePeriod, 'last_30_days');
      expect(data.series.timestamps, ['2026-06-27', '2026-06-28']);
      expect(data.series.heartRate, [70, null]);
      expect(data.series.systolicBp, [120, 122]);
      expect(data.series.weight, isEmpty);
      expect(data.latestVitals!.oxygenSaturation, 97);
    });
  });

  group('DoctorDashboardPatientsListResponse', () {
    test('parses patients and pagination metadata', () {
      final response = DoctorDashboardPatientsListResponse.fromJson({
        'items': [
          {
            'patientId': 'patient-1',
            'firstName': 'Ayu',
            'lastName': 'Putri',
            'latestVitals': {'heartRate': 72},
          },
        ],
        'pagination': {
          'page': 2,
          'limit': 5,
          'totalItems': 11,
          'totalPages': 3,
        },
      });

      expect(response.items, hasLength(1));
      expect(response.items.single.patient.patientId, 'patient-1');
      expect(response.items.single.latestVitals!.heartRate, 72);
      expect(response.pagination.page, 2);
      expect(response.pagination.limit, 5);
      expect(response.pagination.totalItems, 11);
      expect(response.pagination.totalPages, 3);
    });
  });

  group('DoctorLinkedPatient', () {
    test('parses snake and camel aliases and builds display name', () {
      final linked = DoctorLinkedPatient.fromJson({
        'doctor_id': 'doctor-1',
        'patientId': 'patient-1',
        'source': 'share_code',
        'linked_at': '2026-06-28T08:00:00.000Z',
        'is_active': true,
        'first_name': 'Ayu',
        'lastName': 'Putri',
        'email': 'ayu@example.com',
      });

      expect(linked.doctorId, 'doctor-1');
      expect(linked.patientId, 'patient-1');
      expect(linked.isActive, isTrue);
      expect(linked.displayName, 'Ayu Putri');
    });

    test('falls back display name to email when names are blank', () {
      final linked = DoctorLinkedPatient.fromJson({
        'email': 'patient@example.com',
        'isActive': true,
      });

      expect(linked.displayName, 'patient@example.com');
      expect(linked.isActive, isTrue);
    });
  });
}
