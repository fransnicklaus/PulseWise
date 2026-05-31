class DashboardVitalsResponse {
  final bool success;
  final String message;
  final DashboardVitalsData? data;

  DashboardVitalsResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory DashboardVitalsResponse.fromJson(Map<String, dynamic> json) {
    return DashboardVitalsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? DashboardVitalsData.fromJson(json['data'])
          : null,
    );
  }
}

class DashboardVitalsData {
  final DashboardPatient patient;
  final DashboardPeriod period;
  final DashboardSeries series;
  final DashboardLatestVitals? latestVitals;

  DashboardVitalsData({
    required this.patient,
    required this.period,
    required this.series,
    this.latestVitals,
  });

  factory DashboardVitalsData.fromJson(Map<String, dynamic> json) {
    return DashboardVitalsData(
      patient: DashboardPatient.fromJson(json['patient']),
      period: DashboardPeriod.fromJson(json['period']),
      series: DashboardSeries.fromJson(json['series']),
      latestVitals: json['latestVitals'] != null
          ? DashboardLatestVitals.fromJson(json['latestVitals'])
          : null,
    );
  }
}

class DashboardPatient {
  final String patientId;
  final String firstName;
  final String lastName;
  final String? avatarPhoto;
  final String? email;
  final String? phone;
  final String? dateOfBirth;
  final int? age;
  final String? sex;

  DashboardPatient({
    required this.patientId,
    required this.firstName,
    required this.lastName,
    this.avatarPhoto,
    this.email,
    this.phone,
    this.dateOfBirth,
    this.age,
    this.sex,
  });

  factory DashboardPatient.fromJson(Map<String, dynamic> json) {
    return DashboardPatient(
      patientId: json['patientId'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      avatarPhoto:
          (json['avatarPhoto'] ?? json['avatar_photo'])?.toString().trim(),
      email: json['email'],
      phone: json['phone'],
      dateOfBirth: json['dateOfBirth'],
      age: json['age'],
      sex: json['sex'],
    );
  }
}

class DashboardPeriod {
  final String startAt;
  final String endAt;
  final String timePeriod;

  DashboardPeriod({
    required this.startAt,
    required this.endAt,
    required this.timePeriod,
  });

  factory DashboardPeriod.fromJson(Map<String, dynamic> json) {
    return DashboardPeriod(
      startAt: json['startAt'] ?? '',
      endAt: json['endAt'] ?? '',
      timePeriod: json['timePeriod'] ?? '',
    );
  }
}

class DashboardSeries {
  final List<String> timestamps;
  final List<num?> systolicBp;
  final List<num?> diastolicBp;
  final List<num?> heartRate;
  final List<num?> oxygenSaturation;
  final List<num?> weight;
  final List<num?> height;
  final List<num?> bmi;

  DashboardSeries({
    required this.timestamps,
    required this.systolicBp,
    required this.diastolicBp,
    required this.heartRate,
    required this.oxygenSaturation,
    required this.weight,
    required this.height,
    required this.bmi,
  });

  factory DashboardSeries.fromJson(Map<String, dynamic> json) {
    List<num?> parseList(String key) {
      if (json[key] == null) return [];
      return (json[key] as List).map((item) => item as num?).toList();
    }

    return DashboardSeries(
      timestamps: (json['timestamps'] as List?)
              ?.map((item) => item as String)
              .toList() ??
          [],
      systolicBp: parseList('systolicBp'),
      diastolicBp: parseList('diastolicBp'),
      heartRate: parseList('heartRate'),
      oxygenSaturation: parseList('oxygenSaturation'),
      weight: parseList('weight'),
      height: parseList('height'),
      bmi: parseList('bmi'),
    );
  }
}

class DashboardLatestVitals {
  final String? measuredAt;
  final num? systolicBp;
  final num? diastolicBp;
  final num? heartRate;
  final num? oxygenSaturation;
  final num? weight;
  final num? height;
  final num? bmi;

  DashboardLatestVitals({
    this.measuredAt,
    this.systolicBp,
    this.diastolicBp,
    this.heartRate,
    this.oxygenSaturation,
    this.weight,
    this.height,
    this.bmi,
  });

  factory DashboardLatestVitals.fromJson(Map<String, dynamic> json) {
    return DashboardLatestVitals(
      measuredAt: json['measuredAt'],
      systolicBp: json['systolicBp'] as num?,
      diastolicBp: json['diastolicBp'] as num?,
      heartRate: json['heartRate'] as num?,
      oxygenSaturation: json['oxygenSaturation'] as num?,
      weight: json['weight'] as num?,
      height: json['height'] as num?,
      bmi: json['bmi'] as num?,
    );
  }
}

class QuickDashboardResponse {
  final bool success;
  final String message;
  final QuickDashboardData? data;

  QuickDashboardResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory QuickDashboardResponse.fromJson(Map<String, dynamic> json) {
    return QuickDashboardResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? QuickDashboardData.fromJson(json['data'])
          : null,
    );
  }
}

class QuickDashboardData {
  final DashboardPatient patient;
  final DashboardLatestVitals? latestVitals;
  final Map<String, DashboardFieldMeasurement> latestVitalsByField;

  QuickDashboardData({
    required this.patient,
    this.latestVitals,
    required this.latestVitalsByField,
  });

  factory QuickDashboardData.fromJson(Map<String, dynamic> json) {
    final latestVitalsByFieldJson =
        (json['latestVitalsByField'] as Map<String, dynamic>?) ?? const {};

    return QuickDashboardData(
      patient: DashboardPatient.fromJson(json['patient'] ?? {}),
      latestVitals: json['latestVitals'] != null
          ? DashboardLatestVitals.fromJson(json['latestVitals'])
          : null,
      latestVitalsByField: latestVitalsByFieldJson.map(
        (key, value) => MapEntry(
          key,
          DashboardFieldMeasurement.fromJson(
            (value as Map<String, dynamic>?) ?? const {},
          ),
        ),
      ),
    );
  }
}

class DashboardFieldMeasurement {
  final num? value;
  final String? measuredAt;

  const DashboardFieldMeasurement({
    required this.value,
    required this.measuredAt,
  });

  factory DashboardFieldMeasurement.fromJson(Map<String, dynamic> json) {
    return DashboardFieldMeasurement(
      value: json['value'] as num?,
      measuredAt: json['measuredAt']?.toString(),
    );
  }
}
