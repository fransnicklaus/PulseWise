import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/features/ml_questionnaire/data/datasources/ml_questionnaire_api.dart';

final mlQuestionnaireApiProvider = Provider<MlQuestionnaireApi>((ref) {
  return MlQuestionnaireApi(ref.watch(apiDioProvider));
});
