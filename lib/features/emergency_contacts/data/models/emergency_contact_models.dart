class EmergencyContact {
  final String emergencyContactId;
  final String userId;
  final String contactLabel;
  final String contactNumber;
  final DateTime? createdAt;
  final bool? isPrioritas;

  const EmergencyContact({
    required this.emergencyContactId,
    required this.userId,
    required this.contactLabel,
    required this.contactNumber,
    required this.createdAt,
    required this.isPrioritas,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    final dynamic priorityRaw = json['isPriority'] ?? json['isPrioritas'];

    return EmergencyContact(
      emergencyContactId: (json['emergencyContactId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      contactLabel: (json['contactLabel'] ?? '').toString(),
      contactNumber: (json['contactNumber'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      isPrioritas: priorityRaw is bool
          ? priorityRaw
          : (priorityRaw?.toString().toLowerCase() == 'true'),
    );
  }
}

class EmergencyContactsPageResult {
  final List<EmergencyContact> items;
  final int page;
  final bool hasMore;

  const EmergencyContactsPageResult({
    required this.items,
    required this.page,
    required this.hasMore,
  });
}
