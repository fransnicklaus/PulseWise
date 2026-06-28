import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/doctor/data/models/doctor_heart_risk_models.dart';

void main() {
  group('DoctorHeartRiskAssessmentRecord', () {
    test('parses aliases, numeric strings, mapped enums, and dates', () {
      final record = DoctorHeartRiskAssessmentRecord.fromJson({
        'assessment_id': 'assessment-1',
        'patientId': 'patient-1',
        'created_by_user_id': 'doctor-1',
        'updatedByUserId': 'doctor-2',
        'assessment_date': '2026-06-28',
        'age': '54',
        'sex': '1',
        'chest_pain_type': '2',
        'resting_bp_s': '130.5',
        'fastingBloodSugar': '0',
        'max_heart_rate': 160,
        'exercise_angina': 'yes',
        'oldPeak': '1.5',
        'st_slope': '2',
        'created_at': '2026-06-28T08:00:00.000Z',
        'updatedAt': 'not-a-date',
      });

      expect(record.assessmentId, 'assessment-1');
      expect(record.patientId, 'patient-1');
      expect(record.age, 54);
      expect(record.sex, 'male');
      expect(record.chestPainType, 'non_anginal_pain');
      expect(record.restingBpS, 130.5);
      expect(record.fastingBloodSugar, 'lte_120_mg_dl');
      expect(record.maxHeartRate, 160);
      expect(record.exerciseAngina, 'yes');
      expect(record.oldPeak, 1.5);
      expect(record.stSlope, 'downsloping');
      expect(record.createdAt, DateTime.parse('2026-06-28T08:00:00.000Z'));
      expect(record.updatedAt, isNull);
    });
  });

  group('DoctorHeartRiskReadinessResult', () {
    test('parses field lists and source summary', () {
      final readiness = DoctorHeartRiskReadinessResult.fromJson({
        'ready': true,
        'model_key': 'heart-risk',
        'missingFields': ['age', ' '],
        'resolvedFields': ['sex', 12],
        'sourceSummary': {
          'assessment_id': 'assessment-1',
          'assessmentDate': '2026-06-28',
          'latest_body_metric_measured_at': '2026-06-28T08:00:00.000Z',
          'derived': {
            'ageFromProfile': true,
            'sexFromProfile': true,
            'restingBpFromBodyMetric': false,
            'maxHeartRateFromBodyMetric': true,
          },
        },
      });

      expect(readiness.ready, isTrue);
      expect(readiness.modelKey, 'heart-risk');
      expect(readiness.missingFields, ['age']);
      expect(readiness.resolvedFields, ['sex', '12']);
      expect(readiness.sourceSummary!.assessmentId, 'assessment-1');
      expect(readiness.sourceSummary!.derived!.ageFromProfile, isTrue);
      expect(
        readiness.sourceSummary!.derived!.restingBpFromBodyMetric,
        isFalse,
      );
    });
  });

  group('DoctorHeartRiskPredictionResult', () {
    test('parses nested source, window, upstream, and assessment data', () {
      final prediction = DoctorHeartRiskPredictionResult.fromJson({
        'result_id': 'result-1',
        'patient_id': 'patient-1',
        'requested_by_user_id': 'doctor-1',
        'model_key': 'heart-risk',
        'inference_type': 'manual',
        'request_context': 'doctor_dashboard',
        'ml_version': 'v1',
        'payload_hash': 'hash-1',
        'sourceSummary': {
          'assessmentId': 'assessment-1',
          'derived': {'ageFromProfile': true},
        },
        'window': {
          'start_date': '2026-06-01',
          'endDate': '2026-06-28',
        },
        'upstream': {
          'endpoint': '/predict',
          'status': '200',
          'body': {
            'featureOrder': ['age', ' ', 77],
            'ml_version': 'v1',
            'modelKey': 'heart-risk',
            'predicted_class': '1',
            'probability': '0.85',
            'risk_level': 'high',
            'threshold': 0.7,
          },
        },
        'generated_at': '2026-06-28T08:00:00.000Z',
        'createdAt': '2026-06-28T08:01:00.000Z',
        'assessment': _assessmentJson(),
      });

      expect(prediction.resultId, 'result-1');
      expect(prediction.sourceSummary!.assessmentId, 'assessment-1');
      expect(prediction.window!.startDate, '2026-06-01');
      expect(prediction.window!.endDate, '2026-06-28');
      expect(prediction.upstream!.endpoint, '/predict');
      expect(prediction.upstream!.status, 200);
      expect(prediction.upstream!.body!.featureOrder, ['age', '77']);
      expect(prediction.upstream!.body!.predictedClass, 1);
      expect(prediction.upstream!.body!.probability, 0.85);
      expect(prediction.upstream!.body!.riskLevel, 'high');
      expect(prediction.assessment!.assessmentId, 'assessment-1');
      expect(
          prediction.generatedAt, DateTime.parse('2026-06-28T08:00:00.000Z'));
      expect(
        prediction.createdAt,
        DateTime.parse('2026-06-28T08:01:00.000Z'),
      );
    });
  });

  group('DoctorHeartRiskPredictionHistoryPageData', () {
    test('filters invalid items and reads pagination aliases', () {
      final page = DoctorHeartRiskPredictionHistoryPageData.fromJson({
        'items': [
          _predictionJson('result-1'),
          'ignored',
          _predictionJson('result-2'),
        ],
        'pagination': {
          'page': 1,
          'limit': 2,
          'total_items': 4,
          'total_pages': 2,
        },
      });

      expect(page.items, hasLength(2));
      expect(page.items.first.resultId, 'result-1');
      expect(page.limit, 2);
      expect(page.totalItems, 4);
      expect(page.totalPages, 2);
      expect(page.hasMore, isTrue);
    });

    test('uses safe defaults when pagination is absent', () {
      final page = DoctorHeartRiskPredictionHistoryPageData.fromJson({
        'items': [_predictionJson('result-1')],
      });

      expect(page.page, 1);
      expect(page.limit, 1);
      expect(page.totalItems, 0);
      expect(page.totalPages, 1);
      expect(page.hasMore, isFalse);
    });
  });

  group('heartRiskEnumLabel', () {
    test('maps known values and falls back for blank or unknown values', () {
      expect(heartRiskEnumLabel('sex', 'male'), 'Laki-laki');
      expect(
        heartRiskEnumLabel('chest_pain_type', 'typical_angina'),
        'Nyeri dada khas angina',
      );
      expect(heartRiskEnumLabel('exercise_angina', 'no'), 'Tidak');
      expect(heartRiskEnumLabel('sex', null), '-');
      expect(heartRiskEnumLabel('unknown', 'raw_value'), 'raw_value');
    });
  });
}

Map<String, dynamic> _assessmentJson() {
  return {
    'assessment_id': 'assessment-1',
    'patient_id': 'patient-1',
    'created_by_user_id': 'doctor-1',
    'updated_by_user_id': 'doctor-1',
    'assessment_date': '2026-06-28',
    'age': 54,
    'sex': 'male',
    'chest_pain_type': 'asymptomatic',
    'resting_bp_s': 130,
    'fasting_blood_sugar': 'gt_120_mg_dl',
    'max_heart_rate': 150,
    'exercise_angina': 'no',
    'old_peak': 1.2,
    'st_slope': 'flat',
    'created_at': '2026-06-28T08:00:00.000Z',
  };
}

Map<String, dynamic> _predictionJson(String resultId) {
  return {
    'result_id': resultId,
    'patient_id': 'patient-1',
    'requested_by_user_id': 'doctor-1',
    'model_key': 'heart-risk',
    'inference_type': 'manual',
    'request_context': 'doctor_dashboard',
    'ml_version': 'v1',
    'payload_hash': 'hash-1',
    'generated_at': '2026-06-28T08:00:00.000Z',
  };
}
