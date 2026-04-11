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
  final num? systolicPressure;
  final num? diastolicPressure;
  final DateTime? timeStamp;

  const DiaryBodyMetric({
    required this.metricId,
    required this.conditionTag,
    required this.bodyHeight,
    required this.bodyWeight,
    required this.bmi,
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
