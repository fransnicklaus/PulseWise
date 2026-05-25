import 'package:pulsewise/features/home_dashboard/data/models/dashboard_overview_models.dart';

class DoctorDashboardThresholds {
  const DoctorDashboardThresholds({
    required this.spo2CriticalThreshold,
    required this.spo2CautionThreshold,
    required this.weightDailyIncreaseCriticalKg,
    required this.hrNormalMin,
    required this.hrNormalMax,
    required this.bpNormalSystolicMax,
    required this.bpNormalDiastolicMax,
    required this.bpElevatedSystolicMin,
    required this.bpElevatedSystolicMax,
    required this.bpElevatedDiastolicMax,
    required this.bpStage1SystolicMin,
    required this.bpStage1SystolicMax,
    required this.bpStage1DiastolicMin,
    required this.bpStage1DiastolicMax,
    required this.bpStage2SystolicMin,
    required this.bpStage2DiastolicMin,
  });

  final num spo2CriticalThreshold;
  final num spo2CautionThreshold;
  final num weightDailyIncreaseCriticalKg;
  final num hrNormalMin;
  final num hrNormalMax;
  final num bpNormalSystolicMax;
  final num bpNormalDiastolicMax;
  final num bpElevatedSystolicMin;
  final num bpElevatedSystolicMax;
  final num bpElevatedDiastolicMax;
  final num bpStage1SystolicMin;
  final num bpStage1SystolicMax;
  final num bpStage1DiastolicMin;
  final num bpStage1DiastolicMax;
  final num bpStage2SystolicMin;
  final num bpStage2DiastolicMin;

  factory DoctorDashboardThresholds.fromJson(Map<String, dynamic> json) {
    num readNum(String key, num fallback) {
      final value = json[key];
      if (value is num) return value;
      return fallback;
    }

    return DoctorDashboardThresholds(
      spo2CriticalThreshold: readNum('SPO2_CRITICAL_THRESHOLD', 90),
      spo2CautionThreshold: readNum('SPO2_CAUTION_THRESHOLD', 95),
      weightDailyIncreaseCriticalKg:
          readNum('WEIGHT_DAILY_INCREASE_CRITICAL_KG', 3),
      hrNormalMin: readNum('HR_NORMAL_MIN', 60),
      hrNormalMax: readNum('HR_NORMAL_MAX', 100),
      bpNormalSystolicMax: readNum('BP_NORMAL_SYSTOLIC_MAX', 119),
      bpNormalDiastolicMax: readNum('BP_NORMAL_DIASTOLIC_MAX', 79),
      bpElevatedSystolicMin: readNum('BP_ELEVATED_SYSTOLIC_MIN', 120),
      bpElevatedSystolicMax: readNum('BP_ELEVATED_SYSTOLIC_MAX', 129),
      bpElevatedDiastolicMax: readNum('BP_ELEVATED_DIASTOLIC_MAX', 79),
      bpStage1SystolicMin: readNum('BP_STAGE1_SYSTOLIC_MIN', 130),
      bpStage1SystolicMax: readNum('BP_STAGE1_SYSTOLIC_MAX', 139),
      bpStage1DiastolicMin: readNum('BP_STAGE1_DIASTOLIC_MIN', 80),
      bpStage1DiastolicMax: readNum('BP_STAGE1_DIASTOLIC_MAX', 89),
      bpStage2SystolicMin: readNum('BP_STAGE2_SYSTOLIC_MIN', 140),
      bpStage2DiastolicMin: readNum('BP_STAGE2_DIASTOLIC_MIN', 90),
    );
  }
}

class DoctorDashboardPatientSummaryData {
  const DoctorDashboardPatientSummaryData({
    required this.patient,
    required this.latestVitals,
    required this.thresholds,
  });

  final DashboardPatient patient;
  final DashboardLatestVitals? latestVitals;
  final DoctorDashboardThresholds thresholds;

  factory DoctorDashboardPatientSummaryData.fromJson(
      Map<String, dynamic> json) {
    return DoctorDashboardPatientSummaryData(
      patient: DashboardPatient.fromJson(
        (json['patient'] as Map<String, dynamic>?) ?? const {},
      ),
      latestVitals: json['latestVitals'] is Map<String, dynamic>
          ? DashboardLatestVitals.fromJson(
              json['latestVitals'] as Map<String, dynamic>,
            )
          : null,
      thresholds: DoctorDashboardThresholds.fromJson(
        (json['thresholds'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}

class DoctorDashboardPatientSummaryResponse {
  const DoctorDashboardPatientSummaryResponse({
    required this.success,
    required this.message,
    this.data,
  });

  final bool success;
  final String message;
  final DoctorDashboardPatientSummaryData? data;

  factory DoctorDashboardPatientSummaryResponse.fromJson(
      Map<String, dynamic> json) {
    return DoctorDashboardPatientSummaryResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      data: json['data'] is Map<String, dynamic>
          ? DoctorDashboardPatientSummaryData.fromJson(
              json['data'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class DoctorDashboardPatientVitalsData {
  const DoctorDashboardPatientVitalsData({
    required this.patient,
    required this.period,
    required this.series,
    required this.latestVitals,
    required this.thresholds,
  });

  final DashboardPatient patient;
  final DashboardPeriod period;
  final DashboardSeries series;
  final DashboardLatestVitals? latestVitals;
  final DoctorDashboardThresholds thresholds;

  factory DoctorDashboardPatientVitalsData.fromJson(Map<String, dynamic> json) {
    return DoctorDashboardPatientVitalsData(
      patient: DashboardPatient.fromJson(
        (json['patient'] as Map<String, dynamic>?) ?? const {},
      ),
      period: DashboardPeriod.fromJson(
        (json['period'] as Map<String, dynamic>?) ?? const {},
      ),
      series: DashboardSeries.fromJson(
        (json['series'] as Map<String, dynamic>?) ?? const {},
      ),
      latestVitals: json['latestVitals'] is Map<String, dynamic>
          ? DashboardLatestVitals.fromJson(
              json['latestVitals'] as Map<String, dynamic>,
            )
          : null,
      thresholds: DoctorDashboardThresholds.fromJson(
        (json['thresholds'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}

class DoctorDashboardPatientVitalsResponse {
  const DoctorDashboardPatientVitalsResponse({
    required this.success,
    required this.message,
    this.data,
  });

  final bool success;
  final String message;
  final DoctorDashboardPatientVitalsData? data;

  factory DoctorDashboardPatientVitalsResponse.fromJson(
      Map<String, dynamic> json) {
    return DoctorDashboardPatientVitalsResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      data: json['data'] is Map<String, dynamic>
          ? DoctorDashboardPatientVitalsData.fromJson(
              json['data'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
