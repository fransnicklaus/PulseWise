import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/ml_assessment/data/models/ml_assessment_models.dart';

void main() {
  group('MlAssessmentRecord', () {
    test('normalizes API maps, stringifies ids, and parses dates', () {
      final record = MlAssessmentRecord.fromApiData({
        'assessmentId': 123,
        'assessmentDate': '2026-06-28T07:30:00.000Z',
        'systolic': 120,
        42: 'answer',
      });

      expect(record.assessmentId, '123');
      expect(record.assessmentDate, DateTime.parse('2026-06-28T07:30:00.000Z'));
      expect(record.valueFor('systolic'), 120);
      expect(record.valueFor('42'), 'answer');
      expect(record.isEmpty, isFalse);
    });

    test('returns an empty record for unsupported API data', () {
      final record = MlAssessmentRecord.fromApiData('unexpected');

      expect(record.values, isEmpty);
      expect(record.assessmentId, isNull);
      expect(record.assessmentDate, isNull);
      expect(record.isEmpty, isTrue);
    });
  });

  group('MlReadinessResult', () {
    test('uses camelCase missing fields when present', () {
      final result = MlReadinessResult.fromApiData({
        'ready': true,
        'missingFields': ['age', 10],
      });

      expect(result.ready, isTrue);
      expect(result.missingFields, ['age', '10']);
      expect(result.data['ready'], isTrue);
    });

    test('falls back to snake_case missing fields and requires bool true', () {
      final result = MlReadinessResult.fromApiData({
        'ready': 'true',
        'missing_fields': ['bloodPressure'],
      });

      expect(result.ready, isFalse);
      expect(result.missingFields, ['bloodPressure']);
    });
  });

  group('MlPredictionResult', () {
    test('normalizes map keys and drops unsupported payloads', () {
      final prediction = MlPredictionResult.fromApiData({
        'risk': 0.72,
        1: 'first',
      });
      final emptyPrediction = MlPredictionResult.fromApiData(null);

      expect(prediction.data['risk'], 0.72);
      expect(prediction.data['1'], 'first');
      expect(emptyPrediction.data, isEmpty);
    });
  });
}
