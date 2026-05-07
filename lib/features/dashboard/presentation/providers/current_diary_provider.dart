import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'profile_provider.dart';

final currentDiaryProvider =
    StateNotifierProvider<CurrentDiaryNotifier, CurrentDiaryState>(
  (ref) => CurrentDiaryNotifier(ref.watch(profileApiProvider)),
);

class CurrentDiaryNotifier extends StateNotifier<CurrentDiaryState> {
  CurrentDiaryNotifier(this._profileApi) : super(const CurrentDiaryState());

  final ProfileApi _profileApi;

  Future<void> ensureCurrentDiaryLoaded() async {
    if (state.hasLoadedOnce) return;
    await loadCurrentDiaryForToday();
  }

  Future<void> loadCurrentDiaryForToday(
      {bool preserveCurrentData = false}) async {
    final hasCurrentData = state.diary != null;
    final shouldPreserve = preserveCurrentData && hasCurrentData;

    state = state.copyWith(
      isLoading: !shouldPreserve,
      isRefreshing: shouldPreserve,
      error: null,
    );

    try {
      var diary = await _profileApi.fetchDiaryDetailByDate(DateTime.now());
      final sleepData = await _profileApi.fetchSleepDiaryByDate(DateTime.now());

      if (diary == null) {
        if (sleepData != null) {
          diary = DiaryDetail(
            diaryId: '',
            userId: '',
            diaryDate: DateTime.now(),
            createdAt: DateTime.now(),
            heartRate: null,
            bodyMetrics: const [],
            symptoms: const [],
            activities: const [],
            consumptions: const [],
            sleeps: [DiarySleep.fromJson(sleepData)],
          );
        } else {
          state = CurrentDiaryState(
            isLoading: false,
            isRefreshing: false,
            hasLoadedOnce: true,
            hasCurrentDiary: false,
            diary: shouldPreserve ? state.diary : null,
          );
          return;
        }
      } else if (sleepData != null) {
        diary = diary.copyWith(
          sleeps: [DiarySleep.fromJson(sleepData)],
        );
      }

      state = CurrentDiaryState(
        isLoading: false,
        isRefreshing: false,
        hasLoadedOnce: true,
        hasCurrentDiary: true,
        diaryId: diary.diaryId,
        diary: diary,
      );
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('not found') ||
          message.contains('404') ||
          message.contains('tidak ditemukan')) {
        state = CurrentDiaryState(
          isLoading: false,
          isRefreshing: false,
          hasLoadedOnce: true,
          hasCurrentDiary: false,
          diary: shouldPreserve ? state.diary : null,
        );
        return;
      }

      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        hasLoadedOnce: true,
        error: e.toString(),
        hasCurrentDiary: shouldPreserve ? state.hasCurrentDiary : false,
      );
    }
  }

  Future<void> invalidateCurrentDiaryQuery() async {
    await loadCurrentDiaryForToday(preserveCurrentData: true);
  }

  Future<void> addSleepFromModal(Map<String, dynamic> payload) async {
    final sleepTime = (payload['sleepTime'] ?? '').toString();
    final wakeTime = (payload['wakeTime'] ?? '').toString();
    var duration = payload['duration'] is num
        ? (payload['duration'] as num).toDouble()
        : double.tryParse(payload['duration']?.toString() ?? '') ?? 0.0;

    if (sleepTime.isEmpty || wakeTime.isEmpty) {
      throw Exception('Waktu tidur dan bangun harus diisi.');
    }

    final now = DateTime.now();
    final diaryDate =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await _profileApi.addDiarySleepByDate(
      diaryDate: diaryDate,
      sleepTime: sleepTime,
      wakeTime: wakeTime,
      sleepDurationHours: duration,
    );
  }

  Future<void> addSymptomsFromModal(Map<String, dynamic> payload) async {
    final symptomsMapped =
        (payload['symptomsMapped'] as List?)?.cast<Map<String, dynamic>>() ??
            [];

    if (symptomsMapped.isEmpty) return;

    final now = DateTime.now();
    final diaryDate =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final time = (payload['time'] ?? '').toString();

    for (final symptom in symptomsMapped) {
      final symptomCode = symptom['symptomCode']?.toString() ?? 'other';
      final bodyArea = symptom['bodyArea']?.toString() ?? 'other';
      final isChestPain =
          bool.tryParse(symptom['isChestPain']?.toString() ?? 'false') ?? false;
      final intensity = payload['intensity'] is num
          ? (payload['intensity'] as num).toInt()
          : int.tryParse(payload['intensity']?.toString() ?? '') ?? 1;
      final painFrequencyCode = symptom['painFrequencyCode'] is num
          ? (symptom['painFrequencyCode'] as num).toInt()
          : int.tryParse(symptom['painFrequencyCode']?.toString() ?? '');
      final painLocationCode = symptom['painLocationCode'] is num
          ? (symptom['painLocationCode'] as num).toInt()
          : int.tryParse(symptom['painLocationCode']?.toString() ?? '');

      await _profileApi.addDiarySymptomByDate(
        diaryDate: diaryDate,
        symptomName: symptom['symptomName']?.toString() ?? '',
        symptomCode: symptomCode,
        bodyArea: bodyArea,
        isChestPain: isChestPain,
        painFrequencyCode: isChestPain ? painFrequencyCode : null,
        painLocationCode: isChestPain ? painLocationCode : null,
        intensity: intensity,
        time: time,
        note: (payload['description'] ?? '').toString(),
      );
    }
  }

  Future<void> addConsumptionsFromModal(Map<String, dynamic> payload) async {
    final type = (payload['type'] ?? '').toString().trim();
    final name = (payload['name'] ?? '').toString().trim();
    final portion = (payload['portion'] ?? '').toString().trim();
    if (type.isEmpty || name.isEmpty || portion.isEmpty) return;

    final now = DateTime.now();
    final diaryDate =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final time = (payload['time'] ?? '').toString();
    final note = (payload['note'] ?? '').toString();

    await _profileApi.addDiaryConsumptionByDate(
      diaryDate: diaryDate,
      type: type,
      name: name,
      portion: portion,
      time: time,
      note: note,
    );
  }

  Future<void> addActivitiesFromModal(Map<String, dynamic> payload) async {
    final name =
        ((payload['name'] ?? payload['activity']) ?? '').toString().trim();

    final activityCategory =
        (payload['activityCategory'] ?? 'other').toString();
    final intensityLevel = payload['intensityLevel']?.toString();
    final transportMode = payload['transportMode']?.toString();
    final outdoorMinutes = payload['outdoorMinutes'] is num
        ? (payload['outdoorMinutes'] as num).toInt()
        : int.tryParse(payload['outdoorMinutes']?.toString() ?? '');
    final note = payload['note']?.toString();

    var duration = payload['duration'] is num
        ? (payload['duration'] as num).toInt()
        : int.tryParse(payload['duration']?.toString() ?? '') ?? 0;
    if (duration <= 0) {
      final startTime = (payload['startTime'] ?? '').toString();
      final endTime = (payload['endTime'] ?? '').toString();
      final startParts = startTime.split(':');
      final endParts = endTime.split(':');
      if (startParts.length == 2 && endParts.length == 2) {
        final startHour = int.tryParse(startParts[0]) ?? 0;
        final startMinute = int.tryParse(startParts[1]) ?? 0;
        final endHour = int.tryParse(endParts[0]) ?? 0;
        final endMinute = int.tryParse(endParts[1]) ?? 0;
        final startTotal = (startHour * 60) + startMinute;
        final endTotal = (endHour * 60) + endMinute;
        var diff = endTotal - startTotal;
        if (diff < 0) diff += 24 * 60; // handle overnight crossing
        duration = diff;
      }
    }

    final heartRate = payload['heartRate'] is num
        ? (payload['heartRate'] as num).toInt()
        : int.tryParse(
            (payload['heartRate'] ?? payload['avgHeartRate'] ?? '').toString());

    final userFeeling = ((payload['userFeeling'] ?? payload['feeling']) ?? '')
        .toString()
        .trim();

    if (name.isEmpty || duration <= 0) {
      throw Exception(
          'Data aktivitas belum lengkap (Nama & durasi wajib). Mohon cek lagi form.');
    }

    final now = DateTime.now();
    final diaryDate =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await _profileApi.addDiaryActivityByDate(
      diaryDate: diaryDate,
      name: name,
      activityCategory: activityCategory,
      intensityLevel: intensityLevel,
      transportMode: transportMode,
      outdoorMinutes: outdoorMinutes,
      duration: duration,
      heartRate: heartRate,
      userFeeling: userFeeling.isNotEmpty ? userFeeling : null,
      note: note,
    );
  }

  Future<void> addBodyMetricsFromModal(Map<String, dynamic> payload) async {
    final bodyHeight = payload['bodyHeight'] is num
        ? (payload['bodyHeight'] as num).toDouble()
        : double.tryParse(payload['bodyHeight']?.toString() ?? '');
    final bodyWeight = payload['bodyWeight'] is num
        ? (payload['bodyWeight'] as num).toDouble()
        : double.tryParse(payload['bodyWeight']?.toString() ?? '');
    final bmi = payload['bmi'] is num
        ? (payload['bmi'] as num).toDouble()
        : double.tryParse(payload['bmi']?.toString() ?? '');
    final systolicPressure = payload['systolicPressure'] is num
        ? (payload['systolicPressure'] as num).toInt()
        : int.tryParse(payload['systolicPressure']?.toString() ?? '');
    final diastolicPressure = payload['diastolicPressure'] is num
        ? (payload['diastolicPressure'] as num).toInt()
        : int.tryParse(payload['diastolicPressure']?.toString() ?? '');
    final heartRate = payload['heartRate'] is num
        ? (payload['heartRate'] as num).toInt()
        : int.tryParse(payload['heartRate']?.toString() ?? '');
    final oxygenSaturation = payload['oxygenSaturation'] is num
        ? (payload['oxygenSaturation'] as num).toInt()
        : int.tryParse(payload['oxygenSaturation']?.toString() ?? '');

    final hasAnyField = bodyHeight != null ||
        bodyWeight != null ||
        bmi != null ||
        systolicPressure != null ||
        diastolicPressure != null ||
        heartRate != null ||
        oxygenSaturation != null;
    if (!hasAnyField) {
      throw Exception('Isi minimal satu data metrik kesehatan.');
    }

    final now = DateTime.now();
    final diaryDate =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await _profileApi.updateDiaryBodyMetricsByDate(
      diaryDate: diaryDate,
      conditionTag: (payload['conditionTag'] ?? 'morning').toString(),
      timeStamp:
          (payload['timeStamp'] ?? now.toUtc().toIso8601String()).toString(),
      bodyHeight: bodyHeight,
      bodyWeight: bodyWeight,
      bmi: bmi,
      systolicPressure: systolicPressure,
      diastolicPressure: diastolicPressure,
      heartRate: heartRate,
      oxygenSaturation: oxygenSaturation,
    );
  }
}

class CurrentDiaryState {
  final bool isLoading;
  final bool isRefreshing;
  final bool hasLoadedOnce;
  final bool hasCurrentDiary;
  final String? diaryId;
  final DiaryDetail? diary;
  final String? error;

  const CurrentDiaryState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.hasLoadedOnce = false,
    this.hasCurrentDiary = false,
    this.diaryId,
    this.diary,
    this.error,
  });

  CurrentDiaryState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    bool? hasLoadedOnce,
    bool? hasCurrentDiary,
    String? diaryId,
    DiaryDetail? diary,
    String? error,
  }) {
    return CurrentDiaryState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
      hasCurrentDiary: hasCurrentDiary ?? this.hasCurrentDiary,
      diaryId: diaryId ?? this.diaryId,
      diary: diary ?? this.diary,
      error: error,
    );
  }
}

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
                  json['latestOxygenSaturationMeasuredAt'].toString())
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
  }) {
    return DiaryDetail(
      diaryId: diaryId ?? this.diaryId,
      userId: userId ?? this.userId,
      diaryDate: diaryDate ?? this.diaryDate,
      createdAt: createdAt ?? this.createdAt,
      heartRate: heartRate ?? this.heartRate,
      bodyMetrics: bodyMetrics ?? this.bodyMetrics,
      symptoms: symptoms ?? this.symptoms,
      activities: activities ?? this.activities,
      consumptions: consumptions ?? this.consumptions,
      sleeps: sleeps ?? this.sleeps,
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
                  json['latestOxygenSaturationMeasuredAt'].toString())
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
