class DiaryDetail {
  final String diaryId;
  final String userId;
  final DateTime? diaryDate;
  final DateTime? createdAt;
  final num? heartRate;
  final num? latestHeartRate;
  final DateTime? latestHeartRateMeasuredAt;
  final num? latestOxygenSaturation;
  final DateTime? latestOxygenSaturationMeasuredAt;
  final List<DiaryBodyMetric> bodyMetrics;
  final List<DiarySymptom> symptoms;
  final List<DiaryActivity> activities;
  final List<DiaryConsumption> consumptions;
  final List<DiarySleep> sleeps;
  final List<DiaryNote> notes;

  const DiaryDetail({
    required this.diaryId,
    required this.userId,
    required this.diaryDate,
    required this.createdAt,
    required this.heartRate,
    this.latestHeartRate,
    this.latestHeartRateMeasuredAt,
    this.latestOxygenSaturation,
    this.latestOxygenSaturationMeasuredAt,
    required this.bodyMetrics,
    required this.symptoms,
    required this.activities,
    required this.consumptions,
    required this.sleeps,
    this.notes = const [],
  });

  factory DiaryDetail.fromJson(Map<String, dynamic> json) {
    return DiaryDetail(
      diaryId: (json['diaryId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      diaryDate: DateTime.tryParse((json['diaryDate'] ?? '').toString()),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      heartRate: json['heartRate'] as num?,
      latestHeartRate: json['latestHeartRate'] as num?,
      latestHeartRateMeasuredAt: json['latestHeartRateMeasuredAt'] != null
          ? DateTime.tryParse(json['latestHeartRateMeasuredAt'].toString())
          : null,
      latestOxygenSaturation: json['latestOxygenSaturation'] as num?,
      latestOxygenSaturationMeasuredAt:
          json['latestOxygenSaturationMeasuredAt'] != null
              ? DateTime.tryParse(
                  json['latestOxygenSaturationMeasuredAt'].toString(),
                )
              : null,
      bodyMetrics: ((json['bodyMetrics'] as List?) ?? const [])
          .map((e) => DiaryBodyMetric.fromJson(e as Map<String, dynamic>))
          .toList(),
      symptoms: ((json['symptoms'] as List?) ?? const [])
          .map((e) => DiarySymptom.fromJson(e as Map<String, dynamic>))
          .toList(),
      activities: ((json['activities'] as List?) ?? const [])
          .map((e) => DiaryActivity.fromJson(e as Map<String, dynamic>))
          .toList(),
      consumptions: ((json['consumptions'] as List?) ?? const [])
          .map((e) => DiaryConsumption.fromJson(e as Map<String, dynamic>))
          .toList(),
      sleeps: ((json['sleeps'] as List?) ?? const [])
          .map((e) => DiarySleep.fromJson(e as Map<String, dynamic>))
          .toList(),
      notes: ((json['notes'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => DiaryNote.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }

  DiaryDetail copyWith({
    String? diaryId,
    String? userId,
    DateTime? diaryDate,
    DateTime? createdAt,
    num? heartRate,
    num? latestHeartRate,
    DateTime? latestHeartRateMeasuredAt,
    num? latestOxygenSaturation,
    DateTime? latestOxygenSaturationMeasuredAt,
    List<DiaryBodyMetric>? bodyMetrics,
    List<DiarySymptom>? symptoms,
    List<DiaryActivity>? activities,
    List<DiaryConsumption>? consumptions,
    List<DiarySleep>? sleeps,
    List<DiaryNote>? notes,
  }) {
    return DiaryDetail(
      diaryId: diaryId ?? this.diaryId,
      userId: userId ?? this.userId,
      diaryDate: diaryDate ?? this.diaryDate,
      createdAt: createdAt ?? this.createdAt,
      heartRate: heartRate ?? this.heartRate,
      latestHeartRate: latestHeartRate ?? this.latestHeartRate,
      latestHeartRateMeasuredAt:
          latestHeartRateMeasuredAt ?? this.latestHeartRateMeasuredAt,
      latestOxygenSaturation:
          latestOxygenSaturation ?? this.latestOxygenSaturation,
      latestOxygenSaturationMeasuredAt: latestOxygenSaturationMeasuredAt ??
          this.latestOxygenSaturationMeasuredAt,
      bodyMetrics: bodyMetrics ?? this.bodyMetrics,
      symptoms: symptoms ?? this.symptoms,
      activities: activities ?? this.activities,
      consumptions: consumptions ?? this.consumptions,
      sleeps: sleeps ?? this.sleeps,
      notes: notes ?? this.notes,
    );
  }
}

class DiaryNote {
  final String noteId;
  final String diaryId;
  final String authorUserId;
  final String authorRole;
  final String authorName;
  final String content;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DiaryNote({
    required this.noteId,
    required this.diaryId,
    required this.authorUserId,
    required this.authorRole,
    required this.authorName,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DiaryNote.fromJson(Map<String, dynamic> json) {
    return DiaryNote(
      noteId: (json['noteId'] ?? '').toString(),
      diaryId: (json['diaryId'] ?? '').toString(),
      authorUserId: (json['authorUserId'] ?? '').toString(),
      authorRole: (json['authorRole'] ?? '').toString(),
      authorName: (json['authorName'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()),
    );
  }
}

class DiarySleep {
  final String sleepRecordId;
  final String sleepTime;
  final String wakeTime;
  final num? sleepDurationHours;
  final String? source;

  const DiarySleep({
    required this.sleepRecordId,
    required this.sleepTime,
    required this.wakeTime,
    required this.sleepDurationHours,
    required this.source,
  });

  factory DiarySleep.fromJson(Map<String, dynamic> json) {
    return DiarySleep(
      sleepRecordId: (json['sleepRecordId'] ?? '').toString(),
      sleepTime: (json['sleepTime'] ?? '').toString(),
      wakeTime: (json['wakeTime'] ?? '').toString(),
      sleepDurationHours: json['sleepDurationHours'] as num?,
      source: json['source']?.toString(),
    );
  }
}

class DiaryBodyMetric {
  final String metricId;
  final String? conditionTag;
  final num? bodyHeight;
  final num? bodyWeight;
  final num? bmi;
  final num? heartRate;
  final num? latestHeartRate;
  final DateTime? latestHeartRateMeasuredAt;
  final num? latestOxygenSaturation;
  final DateTime? latestOxygenSaturationMeasuredAt;
  final num? systolicPressure;
  final num? diastolicPressure;
  final DateTime? timeStamp;

  const DiaryBodyMetric({
    required this.metricId,
    required this.conditionTag,
    required this.bodyHeight,
    required this.bodyWeight,
    required this.bmi,
    required this.heartRate,
    this.latestHeartRate,
    this.latestHeartRateMeasuredAt,
    this.latestOxygenSaturation,
    this.latestOxygenSaturationMeasuredAt,
    required this.systolicPressure,
    required this.diastolicPressure,
    required this.timeStamp,
  });

  factory DiaryBodyMetric.fromJson(Map<String, dynamic> json) {
    return DiaryBodyMetric(
      metricId: (json['metricId'] ?? '').toString(),
      conditionTag: json['conditionTag']?.toString(),
      bodyHeight: json['bodyHeight'] as num?,
      bodyWeight: json['bodyWeight'] as num?,
      bmi: json['bmi'] as num?,
      heartRate: json['heartRate'] as num?,
      latestHeartRate: json['latestHeartRate'] as num?,
      latestHeartRateMeasuredAt: json['latestHeartRateMeasuredAt'] != null
          ? DateTime.tryParse(json['latestHeartRateMeasuredAt'].toString())
          : null,
      latestOxygenSaturation: json['latestOxygenSaturation'] as num?,
      latestOxygenSaturationMeasuredAt:
          json['latestOxygenSaturationMeasuredAt'] != null
              ? DateTime.tryParse(
                  json['latestOxygenSaturationMeasuredAt'].toString(),
                )
              : null,
      systolicPressure: json['systolicPressure'] as num?,
      diastolicPressure: json['diastolicPressure'] as num?,
      timeStamp: DateTime.tryParse((json['timeStamp'] ?? '').toString()),
    );
  }
}

class DiarySymptom {
  final String symptomId;
  final String symptomName;
  final num? intensity;
  final String? note;
  final DateTime? timeStamp;

  const DiarySymptom({
    required this.symptomId,
    required this.symptomName,
    required this.intensity,
    required this.note,
    required this.timeStamp,
  });

  factory DiarySymptom.fromJson(Map<String, dynamic> json) {
    return DiarySymptom(
      symptomId: (json['symptomId'] ?? '').toString(),
      symptomName: (json['symptomName'] ?? '').toString(),
      intensity: json['intensity'] as num?,
      note: json['note']?.toString(),
      timeStamp: DateTime.tryParse((json['timeStamp'] ?? '').toString()),
    );
  }
}

class DiaryActivity {
  final String activityId;
  final String name;
  final num? duration;
  final num? heartRate;
  final String? userFeeling;
  final String? note;
  final DateTime? timeStamp;

  const DiaryActivity({
    required this.activityId,
    required this.name,
    required this.duration,
    required this.heartRate,
    required this.userFeeling,
    required this.note,
    required this.timeStamp,
  });

  factory DiaryActivity.fromJson(Map<String, dynamic> json) {
    return DiaryActivity(
      activityId: (json['activityId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      duration: json['duration'] as num?,
      heartRate: json['heartRate'] as num?,
      userFeeling: json['userFeeling']?.toString(),
      note: json['note']?.toString(),
      timeStamp: DateTime.tryParse((json['timeStamp'] ?? '').toString()),
    );
  }
}

class DiaryConsumption {
  final String consumptionId;
  final String type;
  final String name;
  final String? portion;
  final String? note;
  final DateTime? timeStamp;

  const DiaryConsumption({
    required this.consumptionId,
    required this.type,
    required this.name,
    required this.portion,
    required this.note,
    required this.timeStamp,
  });

  factory DiaryConsumption.fromJson(Map<String, dynamic> json) {
    return DiaryConsumption(
      consumptionId: (json['consumptionId'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      portion: json['portion']?.toString(),
      note: json['note']?.toString(),
      timeStamp: DateTime.tryParse((json['timeStamp'] ?? '').toString()),
    );
  }
}

class DiaryHistoryResponse {
  final List<DiaryHistoryItem> items;
  final DiaryHistoryPagination pagination;

  const DiaryHistoryResponse({
    required this.items,
    required this.pagination,
  });

  factory DiaryHistoryResponse.fromJson(Map<String, dynamic> json) {
    return DiaryHistoryResponse(
      items: ((json['items'] as List?) ?? const [])
          .map((e) => DiaryHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: DiaryHistoryPagination.fromJson(
        (json['pagination'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}

class DiaryHistoryItem {
  final String diaryId;
  final String userId;
  final DateTime? diaryDate;
  final DateTime? createdAt;

  const DiaryHistoryItem({
    required this.diaryId,
    required this.userId,
    required this.diaryDate,
    required this.createdAt,
  });

  factory DiaryHistoryItem.fromJson(Map<String, dynamic> json) {
    return DiaryHistoryItem(
      diaryId: (json['diaryId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      diaryDate: DateTime.tryParse((json['diaryDate'] ?? '').toString()),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }
}

class DiaryHistoryPagination {
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;

  const DiaryHistoryPagination({
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
  });

  factory DiaryHistoryPagination.fromJson(Map<String, dynamic> json) {
    return DiaryHistoryPagination(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 10,
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}
