import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/data/ml_mapping.dart';

void main() {
  group('MlMapping field key parsing', () {
    test('splits valid field key into group and code id', () {
      expect(MlMapping.getGroupFromFieldKey('demog1_riagendr'), 'demog1');
      expect(MlMapping.getCodeIdFromFieldKey('demog1_riagendr'), 'riagendr');
    });

    test('returns null for malformed field keys', () {
      expect(MlMapping.getGroupFromFieldKey('riagendr'), isNull);
      expect(MlMapping.getCodeIdFromFieldKey('demog1_'), isNull);
      expect(MlMapping.getGroupFromFieldKey('_riagendr'), isNull);
    });

    test('validates known field keys against registered code maps', () {
      expect(MlMapping.isValidFieldKey('demog1_riagendr'), isTrue);
      expect(MlMapping.isValidFieldKey('quest22_smq020'), isTrue);
      expect(MlMapping.isValidFieldKey('demog1_unknown'), isFalse);
      expect(MlMapping.isValidFieldKey('bad-field'), isFalse);
    });
  });

  group('MlMapping selection fields', () {
    test('returns question, type, and option labels for selection code', () {
      expect(MlMapping.hasGroup('demog1'), isTrue);
      expect(MlMapping.hasCode('demog1', 'riagendr'), isTrue);
      expect(MlMapping.getQuestion('demog1', 'riagendr'), 'Gender');
      expect(MlMapping.getType('demog1', 'riagendr'), 'selection');
      expect(MlMapping.isSelection('demog1', 'riagendr'), isTrue);
      expect(MlMapping.isRange('demog1', 'riagendr'), isFalse);
      expect(MlMapping.getOptionLabel('demog1', 'riagendr', 1), 'Laki-laki');
    });

    test('returns empty options and null labels for unknown code', () {
      expect(MlMapping.getOptions('demog1', 'unknown'), isEmpty);
      expect(MlMapping.getOptionLabel('demog1', 'unknown', 1), isNull);
    });
  });

  group('MlMapping range fields', () {
    test('returns range boundaries and unit for range code', () {
      expect(MlMapping.getQuestion('exami1', 'bpxpls'), 'Detak Jantung');
      expect(MlMapping.getType('exami1', 'bpxpls'), 'range');
      expect(MlMapping.isRange('exami1', 'bpxpls'), isTrue);
      expect(MlMapping.getRangeStart('exami1', 'bpxpls'), 34);
      expect(MlMapping.getRangeEnd('exami1', 'bpxpls'), 136);
      expect(MlMapping.getRangeUnit('exami1', 'bpxpls'), 'bpm');
    });

    test('returns null range data for unknown code', () {
      expect(MlMapping.getRangeData('exami1', 'unknown'), isNull);
      expect(MlMapping.getRangeStart('exami1', 'unknown'), isNull);
      expect(MlMapping.getRangeEnd('exami1', 'unknown'), isNull);
      expect(MlMapping.getRangeUnit('exami1', 'unknown'), isNull);
    });
  });

  group('MlMapping registry helpers', () {
    test('returns registered groups and code ids', () {
      expect(MlMapping.getGroups(), containsAll(['demog1', 'quest22']));
      expect(MlMapping.getCodeIds('quest22'),
          containsAll(['smq020', 'smq890', 'smq900']));
    });

    test('returns empty code ids for unknown group', () {
      expect(MlMapping.getCodeIds('missing'), isEmpty);
    });
  });
}
