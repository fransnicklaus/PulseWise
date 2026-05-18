class ManualMedicationReminderNotificationResponse {
  final bool success;
  final String message;
  final ManualMedicationReminderNotificationData? data;

  const ManualMedicationReminderNotificationResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ManualMedicationReminderNotificationResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return ManualMedicationReminderNotificationResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      data: json['data'] is Map<String, dynamic>
          ? ManualMedicationReminderNotificationData.fromJson(
              json['data'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class ManualMedicationReminderNotificationData {
  final String userId;
  final String notificationType;
  final int sentCount;
  final int failedCount;
  final List<ManualMedicationReminderNotificationResult> results;

  const ManualMedicationReminderNotificationData({
    required this.userId,
    required this.notificationType,
    required this.sentCount,
    required this.failedCount,
    required this.results,
  });

  factory ManualMedicationReminderNotificationData.fromJson(
    Map<String, dynamic> json,
  ) {
    return ManualMedicationReminderNotificationData(
      userId: (json['userId'] ?? '').toString(),
      notificationType: (json['notificationType'] ?? '').toString(),
      sentCount: (json['sentCount'] as num?)?.toInt() ?? 0,
      failedCount: (json['failedCount'] as num?)?.toInt() ?? 0,
      results: ((json['results'] as List?) ?? const [])
          .map(
            (item) => ManualMedicationReminderNotificationResult.fromJson(
              (item as Map<String, dynamic>?) ?? const {},
            ),
          )
          .toList(),
    );
  }
}

class ManualMedicationReminderNotificationResult {
  final String status;
  final String? platform;
  final String? messageId;
  final String? error;

  const ManualMedicationReminderNotificationResult({
    required this.status,
    required this.platform,
    required this.messageId,
    required this.error,
  });

  factory ManualMedicationReminderNotificationResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return ManualMedicationReminderNotificationResult(
      status: (json['status'] ?? '').toString(),
      platform: json['platform']?.toString(),
      messageId: json['messageId']?.toString(),
      error: json['error']?.toString(),
    );
  }
}
