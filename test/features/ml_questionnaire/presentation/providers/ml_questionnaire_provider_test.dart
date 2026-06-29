import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/features/ml_questionnaire/data/datasources/ml_questionnaire_api.dart';
import 'package:pulsewise/features/ml_questionnaire/presentation/providers/ml_questionnaire_provider.dart';

void main() {
  group('mlQuestionnaireApiProvider', () {
    test('creates API from shared Dio', () {
      final container = ProviderContainer(
        overrides: [
          apiDioProvider.overrideWithValue(Dio()),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(mlQuestionnaireApiProvider),
        isA<MlQuestionnaireApi>(),
      );
    });
  });
}
