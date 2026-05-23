class MlAssessmentRecord {
  const MlAssessmentRecord({
    required this.values,
    this.assessmentId,
    this.assessmentDate,
  });

  final String? assessmentId;
  final DateTime? assessmentDate;
  final Map<String, dynamic> values;

  bool get isEmpty => values.isEmpty && (assessmentId == null || assessmentId!.isEmpty);

  dynamic valueFor(String fieldKey) => values[fieldKey];

  factory MlAssessmentRecord.fromApiData(dynamic data) {
    final values = _normalizeApiMap(data);
    return MlAssessmentRecord(
      assessmentId: values['assessmentId']?.toString(),
      assessmentDate: _parseDate(values['assessmentDate']),
      values: values,
    );
  }
}

class MlReadinessResult {
  const MlReadinessResult({
    required this.ready,
    required this.missingFields,
    required this.data,
  });

  final bool ready;
  final List<String> missingFields;
  final Map<String, dynamic> data;

  factory MlReadinessResult.fromApiData(dynamic data) {
    final normalized = _normalizeApiMap(data);
    final missingRaw =
        normalized['missingFields'] ?? normalized['missing_fields'];
    final missingFields =
        (missingRaw as List?)?.map((item) => item.toString()).toList() ??
            const <String>[];

    return MlReadinessResult(
      ready: normalized['ready'] == true,
      missingFields: missingFields,
      data: normalized,
    );
  }
}

class MlPredictionResult {
  const MlPredictionResult({
    required this.data,
  });

  final Map<String, dynamic> data;

  factory MlPredictionResult.fromApiData(dynamic data) {
    return MlPredictionResult(data: _normalizeApiMap(data));
  }
}

Map<String, dynamic> _normalizeApiMap(dynamic data) {
  if (data is Map<String, dynamic>) {
    return Map<String, dynamic>.from(data);
  }

  if (data is Map) {
    return data.map((key, value) => MapEntry(key.toString(), value));
  }

  return <String, dynamic>{};
}

DateTime? _parseDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value.trim());
  }
  return null;
}
