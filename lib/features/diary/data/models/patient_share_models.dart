class PatientShare {
  const PatientShare({
    required this.shareId,
    required this.patientId,
    required this.shareCode,
    required this.expiresAt,
    required this.qrPayload,
  });

  final String shareId;
  final String patientId;
  final String shareCode;
  final String expiresAt;
  final String qrPayload;

  String get qrData => qrPayload.trim().isNotEmpty ? qrPayload : shareCode;

  factory PatientShare.fromJson(Map<String, dynamic> json) {
    return PatientShare(
      shareId: (json['shareId'] ?? json['share_id'] ?? '').toString(),
      patientId: (json['patientId'] ?? json['patient_id'] ?? '').toString(),
      shareCode: (json['shareCode'] ?? json['share_code'] ?? '').toString(),
      expiresAt: (json['expiresAt'] ?? json['expires_at'] ?? '').toString(),
      qrPayload: (json['qrPayload'] ?? json['qr_payload'] ?? '').toString(),
    );
  }
}
