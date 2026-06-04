import 'package:pulsewise/features/home_dashboard/data/models/dashboard_overview_models.dart';

class DoctorHeartRiskEntryData {
  const DoctorHeartRiskEntryData({
    this.patient,
    this.latestVitals,
  });

  final DashboardPatient? patient;
  final DashboardLatestVitals? latestVitals;
}

class DoctorHeartRiskAssessmentRecord {
  const DoctorHeartRiskAssessmentRecord({
    required this.assessmentId,
    required this.patientId,
    required this.createdByUserId,
    required this.updatedByUserId,
    required this.assessmentDate,
    required this.age,
    required this.sex,
    required this.chestPainType,
    required this.restingBpS,
    required this.fastingBloodSugar,
    required this.maxHeartRate,
    required this.exerciseAngina,
    required this.oldPeak,
    required this.stSlope,
    required this.createdAt,
    required this.updatedAt,
  });

  final String assessmentId;
  final String patientId;
  final String createdByUserId;
  final String updatedByUserId;
  final String? assessmentDate;
  final int? age;
  final String? sex;
  final String? chestPainType;
  final num? restingBpS;
  final String? fastingBloodSugar;
  final num? maxHeartRate;
  final String? exerciseAngina;
  final num? oldPeak;
  final String? stSlope;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory DoctorHeartRiskAssessmentRecord.fromJson(Map<String, dynamic> json) {
    return DoctorHeartRiskAssessmentRecord(
      assessmentId: _readString(json, const ['assessmentId', 'assessment_id']),
      patientId: _readString(json, const ['patientId', 'patient_id']),
      createdByUserId:
          _readString(json, const ['createdByUserId', 'created_by_user_id']),
      updatedByUserId:
          _readString(json, const ['updatedByUserId', 'updated_by_user_id']),
      assessmentDate: _readNullableString(
          json, const ['assessmentDate', 'assessment_date']),
      age: _readInt(json, const ['age']),
      sex: _readMappedEnum(json, const ['sex'], _sexEnumLookup),
      chestPainType: _readMappedEnum(
        json,
        const ['chest_pain_type', 'chestPainType'],
        _chestPainTypeEnumLookup,
      ),
      restingBpS: _readNum(json, const ['resting_bp_s', 'restingBpS']),
      fastingBloodSugar: _readMappedEnum(
        json,
        const ['fasting_blood_sugar', 'fastingBloodSugar'],
        _fastingBloodSugarEnumLookup,
      ),
      maxHeartRate: _readNum(json, const ['max_heart_rate', 'maxHeartRate']),
      exerciseAngina: _readMappedEnum(
        json,
        const ['exercise_angina', 'exerciseAngina'],
        _exerciseAnginaEnumLookup,
      ),
      oldPeak: _readNum(json, const ['old_peak', 'oldPeak']),
      stSlope: _readMappedEnum(
        json,
        const ['st_slope', 'stSlope'],
        _stSlopeEnumLookup,
      ),
      createdAt: _readDateTime(json, const ['createdAt', 'created_at']),
      updatedAt: _readDateTime(json, const ['updatedAt', 'updated_at']),
    );
  }
}

class DoctorHeartRiskDerivedFlags {
  const DoctorHeartRiskDerivedFlags({
    required this.ageFromProfile,
    required this.sexFromProfile,
    required this.restingBpFromBodyMetric,
    required this.maxHeartRateFromBodyMetric,
  });

  final bool ageFromProfile;
  final bool sexFromProfile;
  final bool restingBpFromBodyMetric;
  final bool maxHeartRateFromBodyMetric;

  factory DoctorHeartRiskDerivedFlags.fromJson(Map<String, dynamic> json) {
    return DoctorHeartRiskDerivedFlags(
      ageFromProfile: json['ageFromProfile'] == true,
      sexFromProfile: json['sexFromProfile'] == true,
      restingBpFromBodyMetric: json['restingBpFromBodyMetric'] == true,
      maxHeartRateFromBodyMetric: json['maxHeartRateFromBodyMetric'] == true,
    );
  }
}

class DoctorHeartRiskSourceSummary {
  const DoctorHeartRiskSourceSummary({
    required this.assessmentId,
    required this.assessmentDate,
    required this.derived,
    required this.latestBodyMetricMeasuredAt,
  });

  final String? assessmentId;
  final String? assessmentDate;
  final DoctorHeartRiskDerivedFlags? derived;
  final String? latestBodyMetricMeasuredAt;

  factory DoctorHeartRiskSourceSummary.fromJson(Map<String, dynamic> json) {
    return DoctorHeartRiskSourceSummary(
      assessmentId: _readNullableString(
        json,
        const ['assessmentId', 'assessment_id'],
      ),
      assessmentDate: _readNullableString(
          json, const ['assessmentDate', 'assessment_date']),
      derived: json['derived'] is Map<String, dynamic>
          ? DoctorHeartRiskDerivedFlags.fromJson(
              json['derived'] as Map<String, dynamic>,
            )
          : null,
      latestBodyMetricMeasuredAt: _readNullableString(
        json,
        const ['latestBodyMetricMeasuredAt', 'latest_body_metric_measured_at'],
      ),
    );
  }
}

class DoctorHeartRiskReadinessResult {
  const DoctorHeartRiskReadinessResult({
    required this.ready,
    required this.modelKey,
    required this.missingFields,
    required this.resolvedFields,
    required this.sourceSummary,
  });

  final bool ready;
  final String modelKey;
  final List<String> missingFields;
  final List<String> resolvedFields;
  final DoctorHeartRiskSourceSummary? sourceSummary;

  factory DoctorHeartRiskReadinessResult.fromJson(Map<String, dynamic> json) {
    return DoctorHeartRiskReadinessResult(
      ready: json['ready'] == true,
      modelKey: _readString(json, const ['modelKey', 'model_key']),
      missingFields: _readStringList(json['missingFields']),
      resolvedFields: _readStringList(json['resolvedFields']),
      sourceSummary: json['sourceSummary'] is Map<String, dynamic>
          ? DoctorHeartRiskSourceSummary.fromJson(
              json['sourceSummary'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class DoctorHeartRiskPredictionWindow {
  const DoctorHeartRiskPredictionWindow({
    required this.startDate,
    required this.endDate,
  });

  final String? startDate;
  final String? endDate;

  factory DoctorHeartRiskPredictionWindow.fromJson(Map<String, dynamic> json) {
    return DoctorHeartRiskPredictionWindow(
      startDate: _readNullableString(json, const ['startDate', 'start_date']),
      endDate: _readNullableString(json, const ['endDate', 'end_date']),
    );
  }
}

class DoctorHeartRiskPredictionUpstreamBody {
  const DoctorHeartRiskPredictionUpstreamBody({
    required this.featureOrder,
    required this.mlVersion,
    required this.modelKey,
    required this.predictedClass,
    required this.probability,
    required this.riskLevel,
    required this.threshold,
  });

  final List<String> featureOrder;
  final String? mlVersion;
  final String? modelKey;
  final int? predictedClass;
  final num? probability;
  final String? riskLevel;
  final num? threshold;

  factory DoctorHeartRiskPredictionUpstreamBody.fromJson(
    Map<String, dynamic> json,
  ) {
    return DoctorHeartRiskPredictionUpstreamBody(
      featureOrder: _readStringList(json['featureOrder']),
      mlVersion: _readNullableString(json, const ['mlVersion', 'ml_version']),
      modelKey: _readNullableString(json, const ['modelKey', 'model_key']),
      predictedClass:
          _readInt(json, const ['predictedClass', 'predicted_class']),
      probability: _readNum(json, const ['probability']),
      riskLevel: _readNullableString(json, const ['riskLevel', 'risk_level']),
      threshold: _readNum(json, const ['threshold']),
    );
  }
}

class DoctorHeartRiskPredictionUpstream {
  const DoctorHeartRiskPredictionUpstream({
    required this.endpoint,
    required this.status,
    required this.body,
  });

  final String? endpoint;
  final int? status;
  final DoctorHeartRiskPredictionUpstreamBody? body;

  factory DoctorHeartRiskPredictionUpstream.fromJson(
    Map<String, dynamic> json,
  ) {
    return DoctorHeartRiskPredictionUpstream(
      endpoint: _readNullableString(json, const ['endpoint']),
      status: _readInt(json, const ['status']),
      body: json['body'] is Map<String, dynamic>
          ? DoctorHeartRiskPredictionUpstreamBody.fromJson(
              json['body'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class DoctorHeartRiskPredictionResult {
  const DoctorHeartRiskPredictionResult({
    required this.resultId,
    required this.patientId,
    required this.requestedByUserId,
    required this.modelKey,
    required this.inferenceType,
    required this.requestContext,
    required this.mlVersion,
    required this.payloadHash,
    required this.sourceSummary,
    required this.window,
    required this.upstream,
    required this.generatedAt,
    required this.createdAt,
    required this.assessment,
  });

  final String resultId;
  final String patientId;
  final String requestedByUserId;
  final String modelKey;
  final String inferenceType;
  final String requestContext;
  final String mlVersion;
  final String payloadHash;
  final DoctorHeartRiskSourceSummary? sourceSummary;
  final DoctorHeartRiskPredictionWindow? window;
  final DoctorHeartRiskPredictionUpstream? upstream;
  final DateTime? generatedAt;
  final DateTime? createdAt;
  final DoctorHeartRiskAssessmentRecord? assessment;

  factory DoctorHeartRiskPredictionResult.fromJson(Map<String, dynamic> json) {
    return DoctorHeartRiskPredictionResult(
      resultId: _readString(json, const ['resultId', 'result_id']),
      patientId: _readString(json, const ['patientId', 'patient_id']),
      requestedByUserId: _readString(
        json,
        const ['requestedByUserId', 'requested_by_user_id'],
      ),
      modelKey: _readString(json, const ['modelKey', 'model_key']),
      inferenceType:
          _readString(json, const ['inferenceType', 'inference_type']),
      requestContext:
          _readString(json, const ['requestContext', 'request_context']),
      mlVersion: _readString(json, const ['mlVersion', 'ml_version']),
      payloadHash: _readString(json, const ['payloadHash', 'payload_hash']),
      sourceSummary: json['sourceSummary'] is Map<String, dynamic>
          ? DoctorHeartRiskSourceSummary.fromJson(
              json['sourceSummary'] as Map<String, dynamic>,
            )
          : null,
      window: json['window'] is Map<String, dynamic>
          ? DoctorHeartRiskPredictionWindow.fromJson(
              json['window'] as Map<String, dynamic>,
            )
          : null,
      upstream: json['upstream'] is Map<String, dynamic>
          ? DoctorHeartRiskPredictionUpstream.fromJson(
              json['upstream'] as Map<String, dynamic>,
            )
          : null,
      generatedAt: _readDateTime(json, const ['generatedAt', 'generated_at']),
      createdAt: _readDateTime(json, const ['createdAt', 'created_at']),
      assessment: json['assessment'] is Map<String, dynamic>
          ? DoctorHeartRiskAssessmentRecord.fromJson(
              json['assessment'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class DoctorHeartRiskPredictionHistoryPageData {
  const DoctorHeartRiskPredictionHistoryPageData({
    required this.items,
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
  });

  final List<DoctorHeartRiskPredictionResult> items;
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;

  bool get hasMore => page < totalPages;

  factory DoctorHeartRiskPredictionHistoryPageData.fromJson(
    Map<String, dynamic> json,
  ) {
    final pagination =
        (json['pagination'] as Map<String, dynamic>?) ?? const {};
    final itemsRaw = json['items'];
    final items = itemsRaw is List
        ? itemsRaw
            .whereType<Map<String, dynamic>>()
            .map(DoctorHeartRiskPredictionResult.fromJson)
            .toList()
        : const <DoctorHeartRiskPredictionResult>[];

    return DoctorHeartRiskPredictionHistoryPageData(
      items: items,
      page: _readInt(pagination, const ['page']) ?? 1,
      limit: _readInt(pagination, const ['limit']) ?? items.length,
      totalItems:
          _readInt(pagination, const ['totalItems', 'total_items']) ?? 0,
      totalPages:
          _readInt(pagination, const ['totalPages', 'total_pages']) ?? 1,
    );
  }
}

const Map<String, String> sexLabels = {
  'female': 'Perempuan',
  'male': 'Laki-laki',
};

const Map<String, String> chestPainTypeLabels = {
  'typical_angina': 'Nyeri dada khas angina',
  'atypical_angina': 'Nyeri dada tidak khas angina',
  'non_anginal_pain': 'Nyeri dada non-angina',
  'asymptomatic': 'Tanpa gejala nyeri dada',
};

const Map<String, String> fastingBloodSugarLabels = {
  'lte_120_mg_dl': 'Gula darah puasa ≤ 120 mg/dL',
  'gt_120_mg_dl': 'Gula darah puasa > 120 mg/dL',
};

const Map<String, String> exerciseAnginaLabels = {
  'no': 'Tidak',
  'yes': 'Ya',
};

const Map<String, String> stSlopeLabels = {
  'upsloping': 'Naik',
  'flat': 'Datar',
  'downsloping': 'Menurun',
};

String heartRiskEnumLabel(String field, String? value) {
  final normalized = value?.trim() ?? '';
  if (normalized.isEmpty) return '-';

  final labels = switch (field) {
    'sex' => sexLabels,
    'chest_pain_type' => chestPainTypeLabels,
    'fasting_blood_sugar' => fastingBloodSugarLabels,
    'exercise_angina' => exerciseAnginaLabels,
    'st_slope' => stSlopeLabels,
    _ => const <String, String>{},
  };

  return labels[normalized] ?? normalized;
}

const Map<String, String> _sexEnumLookup = {
  '0': 'female',
  'female': 'female',
  '1': 'male',
  'male': 'male',
};

const Map<String, String> _chestPainTypeEnumLookup = {
  '0': 'typical_angina',
  'typical_angina': 'typical_angina',
  '1': 'atypical_angina',
  'atypical_angina': 'atypical_angina',
  '2': 'non_anginal_pain',
  'non_anginal_pain': 'non_anginal_pain',
  '3': 'asymptomatic',
  'asymptomatic': 'asymptomatic',
};

const Map<String, String> _fastingBloodSugarEnumLookup = {
  '0': 'lte_120_mg_dl',
  'lte_120_mg_dl': 'lte_120_mg_dl',
  '1': 'gt_120_mg_dl',
  'gt_120_mg_dl': 'gt_120_mg_dl',
};

const Map<String, String> _exerciseAnginaEnumLookup = {
  '0': 'no',
  'no': 'no',
  '1': 'yes',
  'yes': 'yes',
};

const Map<String, String> _stSlopeEnumLookup = {
  '0': 'upsloping',
  'upsloping': 'upsloping',
  '1': 'flat',
  'flat': 'flat',
  '2': 'downsloping',
  'downsloping': 'downsloping',
};

String _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final normalized = value.toString().trim();
    if (normalized.isNotEmpty) return normalized;
  }
  return '';
}

String? _readNullableString(Map<String, dynamic> json, List<String> keys) {
  final value = _readString(json, keys);
  return value.isEmpty ? null : value;
}

int? _readInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
  }
  return null;
}

num? _readNum(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value;
    if (value is String) {
      final parsed = num.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
  }
  return null;
}

String? _readMappedEnum(
  Map<String, dynamic> json,
  List<String> keys,
  Map<String, String> lookup,
) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;

    final normalized = value.toString().trim().toLowerCase();
    if (normalized.isEmpty) return null;

    return lookup[normalized] ?? normalized;
  }

  return null;
}

DateTime? _readDateTime(Map<String, dynamic> json, List<String> keys) {
  final raw = _readNullableString(json, keys);
  if (raw == null) return null;
  return DateTime.tryParse(raw);
}

List<String> _readStringList(Object? raw) {
  if (raw is List) {
    return raw
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return const [];
}
