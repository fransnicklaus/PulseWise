import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/data/ml_readiness_mapping.dart';

void main() {
  group('buildMlReadinessGroups', () {
    test('groups missing fields by type in stable display order', () {
      final groups = buildMlReadinessGroups([
        'unknown-field',
        ' dieta1_dr1tkcal ',
        'demog1-riagendr',
        'EXAMI2_BMXHT',
        'exami1_bpxpls',
      ]);

      expect(
        groups.map((group) => group.type),
        [
          MlReadinessGroupType.profile,
          MlReadinessGroupType.mlQuestionnaire,
          MlReadinessGroupType.mlAssessment,
          MlReadinessGroupType.diaryConsumption,
          MlReadinessGroupType.unknown,
        ],
      );
    });

    test('normalizes field codes and removes duplicates', () {
      final groups = buildMlReadinessGroups([
        'demog1-riagendr',
        ' DEMOG1_RIAGENDR ',
      ]);

      expect(groups, hasLength(1));
      expect(groups.single.type, MlReadinessGroupType.mlQuestionnaire);
      expect(groups.single.fieldCodes, ['DEMOG1_RIAGENDR']);
      expect(groups.single.fieldLabels, ['Gender']);
    });

    test('uses manual labels and action metadata for profile fields', () {
      final groups = buildMlReadinessGroups(['exami2_bmxht']);

      expect(groups.single.type, MlReadinessGroupType.profile);
      expect(groups.single.title, 'Profil Dasar');
      expect(groups.single.fieldLabels, ['Tinggi badan']);
      expect(groups.single.hasAction, isTrue);
      expect(groups.single.buttonLabel, 'Edit profil');
    });

    test('uses MlMapping question labels for questionnaire and assessment', () {
      final groups = buildMlReadinessGroups([
        'demog1_riagendr',
        'exami1_bpxpls',
      ]);

      final questionnaire = groups.firstWhere(
        (group) => group.type == MlReadinessGroupType.mlQuestionnaire,
      );
      final assessment = groups.firstWhere(
        (group) => group.type == MlReadinessGroupType.mlAssessment,
      );

      expect(questionnaire.fieldLabels, ['Gender']);
      expect(assessment.fieldLabels, ['Detak Jantung']);
    });

    test('keeps unknown fields without action metadata', () {
      final groups = buildMlReadinessGroups([' custom_missing_field ']);

      expect(groups.single.type, MlReadinessGroupType.unknown);
      expect(groups.single.title, 'Data Lainnya');
      expect(groups.single.fieldCodes, ['CUSTOM_MISSING_FIELD']);
      expect(groups.single.fieldLabels, ['CUSTOM_MISSING_FIELD']);
      expect(groups.single.hasAction, isFalse);
      expect(groups.single.buttonLabel, isNull);
    });

    test('skips empty field codes', () {
      expect(buildMlReadinessGroups(['', '   ']), isEmpty);
    });
  });
}
