class MlQuestionnaireProfile {
  const MlQuestionnaireProfile({
    required this.answers,
  });

  final Map<String, dynamic> answers;

  factory MlQuestionnaireProfile.fromApiData(dynamic data) {
    if (data is Map<String, dynamic>) {
      return MlQuestionnaireProfile(answers: Map<String, dynamic>.from(data));
    }

    if (data is Map) {
      return MlQuestionnaireProfile(
        answers: data.map((key, value) => MapEntry(key.toString(), value)),
      );
    }

    return const MlQuestionnaireProfile(answers: <String, dynamic>{});
  }

  int? intAnswerFor(String fieldKey) {
    final value = answers[fieldKey];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}
