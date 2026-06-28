import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/ml_questionnaire/data/models/ml_questionnaire_models.dart';

void main() {
  group('MlQuestionnaireProfile', () {
    test('normalizes API map keys to strings', () {
      final profile = MlQuestionnaireProfile.fromApiData({
        'smoking': 2,
        99: 'answer',
      });

      expect(profile.answers['smoking'], 2);
      expect(profile.answers['99'], 'answer');
    });

    test('returns empty answers for unsupported API data', () {
      final profile = MlQuestionnaireProfile.fromApiData(['unexpected']);

      expect(profile.answers, isEmpty);
    });

    test('intAnswerFor supports int, num, and trimmed string values', () {
      final profile = MlQuestionnaireProfile.fromApiData({
        'intValue': 4,
        'doubleValue': 3.8,
        'stringValue': ' 12 ',
        'invalidString': 'n/a',
      });

      expect(profile.intAnswerFor('intValue'), 4);
      expect(profile.intAnswerFor('doubleValue'), 3);
      expect(profile.intAnswerFor('stringValue'), 12);
      expect(profile.intAnswerFor('invalidString'), isNull);
      expect(profile.intAnswerFor('missing'), isNull);
    });
  });
}
