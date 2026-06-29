import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/features/ml_assessment/data/datasources/ml_assessment_api.dart';
import 'package:pulsewise/features/ml_assessment/presentation/providers/ml_assessment_provider.dart';

void main() {
  group('mlAssessmentApiProvider', () {
    test('creates API from shared Dio', () {
      final container = ProviderContainer(
        overrides: [
          apiDioProvider.overrideWithValue(Dio()),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(mlAssessmentApiProvider), isA<MlAssessmentApi>());
    });
  });
}
