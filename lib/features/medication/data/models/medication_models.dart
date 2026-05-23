class MedicationListResponse {
  final List<MedicationItem> items;
  final MedicationPagination pagination;

  const MedicationListResponse({
    required this.items,
    required this.pagination,
  });

  factory MedicationListResponse.fromJson(Map<String, dynamic> json) {
    return MedicationListResponse(
      items: ((json['items'] as List?) ?? const [])
          .map((e) => MedicationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: MedicationPagination.fromJson(
        (json['pagination'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}

class MedicationItem {
  final String medicationId;
  final String userId;
  final String name;
  final String? description;
  final String? conditionTag;
  final String form;
  final String color;
  final num singleDose;
  final String singleDoseUnit;
  final DateTime? startDate;
  final String frequency;
  final int? numOfDays;
  final List<int> daysOfWeek;
  final List<String> intakeTimes;
  final String? note;
  final DateTime? createdAt;
  final List<MedicationReminder> reminders;

  const MedicationItem({
    required this.medicationId,
    required this.userId,
    required this.name,
    required this.description,
    required this.conditionTag,
    required this.form,
    required this.color,
    required this.singleDose,
    required this.singleDoseUnit,
    required this.startDate,
    required this.frequency,
    required this.numOfDays,
    required this.daysOfWeek,
    required this.intakeTimes,
    required this.note,
    required this.createdAt,
    required this.reminders,
  });

  factory MedicationItem.fromJson(Map<String, dynamic> json) {
    return MedicationItem(
      medicationId: (json['medicationId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      conditionTag: json['conditionTag']?.toString(),
      form: (json['form'] ?? '').toString(),
      color: (json['color'] ?? '').toString(),
      singleDose: (json['singleDose'] as num?) ?? 0,
      singleDoseUnit: (json['singleDoseUnit'] ?? '').toString(),
      startDate: DateTime.tryParse((json['startDate'] ?? '').toString()),
      frequency: (json['frequency'] ?? '').toString(),
      numOfDays: (json['numOfDays'] as num?)?.toInt(),
      daysOfWeek: ((json['daysOfWeek'] as List?) ?? const [])
          .map((e) => (e as num).toInt())
          .toList(),
      intakeTimes: ((json['intakeTimes'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      note: json['note']?.toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      reminders: ((json['reminders'] as List?) ?? const [])
          .map((e) => MedicationReminder.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MedicationReminder {
  final String reminderId;
  final String userId;
  final String medicationId;
  final String scheduleTime;
  final int? dayOfWeek;
  final DateTime? createdAt;

  const MedicationReminder({
    required this.reminderId,
    required this.userId,
    required this.medicationId,
    required this.scheduleTime,
    required this.dayOfWeek,
    required this.createdAt,
  });

  factory MedicationReminder.fromJson(Map<String, dynamic> json) {
    return MedicationReminder(
      reminderId: (json['reminderId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      medicationId: (json['medicationId'] ?? '').toString(),
      scheduleTime: (json['scheduleTime'] ?? '').toString(),
      dayOfWeek: (json['dayOfWeek'] as num?)?.toInt(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }
}

class MedicationPagination {
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;

  const MedicationPagination({
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
  });

  factory MedicationPagination.fromJson(Map<String, dynamic> json) {
    return MedicationPagination(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 10,
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}

class MedicationCalendarResponse {
  final MedicationCalendarRange range;
  final int totalItems;
  final List<MedicationCalendarItem> items;

  const MedicationCalendarResponse({
    required this.range,
    required this.totalItems,
    required this.items,
  });

  factory MedicationCalendarResponse.fromJson(Map<String, dynamic> json) {
    return MedicationCalendarResponse(
      range: MedicationCalendarRange.fromJson(
        (json['range'] as Map<String, dynamic>?) ?? const {},
      ),
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      items: ((json['items'] as List?) ?? const [])
          .map(
            (e) => MedicationCalendarItem.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class MedicationCalendarRange {
  final DateTime? from;
  final DateTime? to;

  const MedicationCalendarRange({
    required this.from,
    required this.to,
  });

  factory MedicationCalendarRange.fromJson(Map<String, dynamic> json) {
    return MedicationCalendarRange(
      from: DateTime.tryParse((json['from'] ?? '').toString()),
      to: DateTime.tryParse((json['to'] ?? '').toString()),
    );
  }
}

class MedicationLogResponse {
  final List<MedicationLogItem> items;
  final MedicationPagination pagination;

  const MedicationLogResponse({
    required this.items,
    required this.pagination,
  });

  factory MedicationLogResponse.fromJson(Map<String, dynamic> json) {
    return MedicationLogResponse(
      items: ((json['items'] as List?) ?? const [])
          .map((e) => MedicationLogItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: MedicationPagination.fromJson(
        (json['pagination'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}

class MedicationLogItem {
  final String medicationLogId;
  final String userId;
  final String medicationId;
  final String status;
  final DateTime? medicationDate;
  final String medicationTime;
  final DateTime? createdAt;

  const MedicationLogItem({
    required this.medicationLogId,
    required this.userId,
    required this.medicationId,
    required this.status,
    required this.medicationDate,
    required this.medicationTime,
    required this.createdAt,
  });

  factory MedicationLogItem.fromJson(Map<String, dynamic> json) {
    return MedicationLogItem(
      medicationLogId: (json['medicationLogId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      medicationId: (json['medicationId'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      medicationDate:
          DateTime.tryParse((json['medicationDate'] ?? '').toString()),
      medicationTime: (json['medicationTime'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }
}

class MedicationCalendarItem {
  final String eventId;
  final DateTime? scheduledDate;
  final String scheduledTime;
  final String reminderId;
  final String medicationId;
  final String? medicationLogId;
  final String name;
  final String color;
  final num singleDose;
  final String singleDoseUnit;
  final String? status;

  const MedicationCalendarItem({
    required this.eventId,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.reminderId,
    required this.medicationId,
    required this.medicationLogId,
    required this.name,
    required this.color,
    required this.singleDose,
    required this.singleDoseUnit,
    required this.status,
  });

  factory MedicationCalendarItem.fromJson(Map<String, dynamic> json) {
    return MedicationCalendarItem(
      eventId: (json['eventId'] ?? '').toString(),
      scheduledDate:
          DateTime.tryParse((json['scheduledDate'] ?? '').toString()),
      scheduledTime: (json['scheduledTime'] ?? '').toString(),
      reminderId: (json['reminderId'] ?? '').toString(),
      medicationId: (json['medicationId'] ?? '').toString(),
      medicationLogId: json['medicationLogId']?.toString(),
      name: (json['name'] ?? '').toString(),
      color: (json['color'] ?? '').toString(),
      singleDose: (json['singleDose'] as num?) ?? 0,
      singleDoseUnit: (json['singleDoseUnit'] ?? '').toString(),
      status: json['status']?.toString(),
    );
  }
}
