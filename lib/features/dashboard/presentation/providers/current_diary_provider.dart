import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'profile_provider.dart';

final currentDiaryProvider =
    StateNotifierProvider<CurrentDiaryNotifier, CurrentDiaryState>(
  (ref) => CurrentDiaryNotifier(ref.watch(profileApiProvider)),
);

class CurrentDiaryNotifier extends StateNotifier<CurrentDiaryState> {
  CurrentDiaryNotifier(this._profileApi) : super(const CurrentDiaryState());

  final ProfileApi _profileApi;

  Future<void> loadCurrentDiaryForToday() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final diary = await _profileApi.fetchDiaryDetailByDate(DateTime.now());

      if (diary == null) {
        state = const CurrentDiaryState(
          isLoading: false,
          hasCurrentDiary: false,
        );
        return;
      }

      state = CurrentDiaryState(
        isLoading: false,
        hasCurrentDiary: true,
        diaryId: diary.diaryId,
        diary: diary,
      );
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('not found') ||
          message.contains('404') ||
          message.contains('tidak ditemukan')) {
        state = const CurrentDiaryState(
          isLoading: false,
          hasCurrentDiary: false,
        );
        return;
      }

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        hasCurrentDiary: false,
      );
    }
  }

  Future<void> addSymptomsFromModal(Map<String, dynamic> payload) async {
    final symptoms = ((payload['symptoms'] as List?) ?? const [])
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (symptoms.isEmpty) return;

    final now = DateTime.now();
    final diaryDate =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final intensity = payload['intensity'] is num
        ? (payload['intensity'] as num).toInt()
        : int.tryParse(payload['intensity']?.toString() ?? '') ?? 1;
    final time = (payload['time'] ?? '').toString();
    final note = (payload['description'] ?? '').toString();

    for (final symptomName in symptoms) {
      await _profileApi.addDiarySymptomByDate(
        diaryDate: diaryDate,
        symptomName: symptomName,
        intensity: intensity,
        time: time,
        note: note,
      );
    }

    await loadCurrentDiaryForToday();
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

    await loadCurrentDiaryForToday();
  }

  Future<void> addActivitiesFromModal(Map<String, dynamic> payload) async {
    final name =
        ((payload['name'] ?? payload['activity']) ?? '').toString().trim();

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
        duration = endTotal - startTotal;
      }
    }

    final heartRate = payload['heartRate'] is num
        ? (payload['heartRate'] as num).toInt()
        : int.tryParse((payload['heartRate'] ?? payload['avgHeartRate'] ?? '')
                .toString()) ??
            0;
    final userFeeling = ((payload['userFeeling'] ?? payload['feeling']) ?? '')
        .toString()
        .trim();

    if (name.isEmpty ||
        duration <= 0 ||
        heartRate <= 0 ||
        userFeeling.isEmpty) {
      throw Exception('Data aktivitas belum lengkap. Mohon cek lagi form.');
    }

    final now = DateTime.now();
    final diaryDate =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await _profileApi.addDiaryActivityByDate(
      diaryDate: diaryDate,
      name: name,
      duration: duration,
      heartRate: heartRate,
      userFeeling: userFeeling,
    );

    await loadCurrentDiaryForToday();
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

    final hasAnyField = bodyHeight != null ||
        bodyWeight != null ||
        bmi != null ||
        systolicPressure != null ||
        diastolicPressure != null ||
        heartRate != null;
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
    );

    await loadCurrentDiaryForToday();
  }
}

class CurrentDiaryState {
  final bool isLoading;
  final bool hasCurrentDiary;
  final String? diaryId;
  final DiaryDetail? diary;
  final String? error;

  const CurrentDiaryState({
    this.isLoading = false,
    this.hasCurrentDiary = false,
    this.diaryId,
    this.diary,
    this.error,
  });

  CurrentDiaryState copyWith({
    bool? isLoading,
    bool? hasCurrentDiary,
    String? diaryId,
    DiaryDetail? diary,
    String? error,
  }) {
    return CurrentDiaryState(
      isLoading: isLoading ?? this.isLoading,
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
  final List<DiaryBodyMetric> bodyMetrics;
  final List<DiarySymptom> symptoms;
  final List<DiaryActivity> activities;
  final List<DiaryConsumption> consumptions;

  const DiaryDetail({
    required this.diaryId,
    required this.userId,
    required this.diaryDate,
    required this.createdAt,
    required this.bodyMetrics,
    required this.symptoms,
    required this.activities,
    required this.consumptions,
  });

  factory DiaryDetail.fromJson(Map<String, dynamic> json) {
    return DiaryDetail(
      diaryId: (json['diaryId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      diaryDate: DateTime.tryParse((json['diaryDate'] ?? '').toString()),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
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
