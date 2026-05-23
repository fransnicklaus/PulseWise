import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/features/ml_assessment/data/datasources/ml_assessment_api.dart';

final mlAssessmentApiProvider = Provider<MlAssessmentApi>((ref) {
  return MlAssessmentApi(ref.watch(apiDioProvider));
});
