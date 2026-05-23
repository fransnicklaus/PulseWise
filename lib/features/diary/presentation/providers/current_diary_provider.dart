import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/features/diary/data/datasources/diary_api.dart';
import 'package:pulsewise/features/diary/data/models/diary_models.dart';

final currentDiaryProvider =
    StateNotifierProvider<CurrentDiaryNotifier, CurrentDiaryState>(
  (ref) => CurrentDiaryNotifier(ref.watch(diaryApiProvider)),
);

class CurrentDiaryNotifier extends StateNotifier<CurrentDiaryState> {
  CurrentDiaryNotifier(this._diaryApi) : super(const CurrentDiaryState());

  final DiaryApi _diaryApi;

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
      var diary = await _diaryApi.fetchDiaryDetailByDate(DateTime.now());
      final sleepData = await _diaryApi.fetchSleepDiaryByDate(DateTime.now());

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

    await _diaryApi.addDiarySleepByDate(
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

      await _diaryApi.addDiarySymptomByDate(
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
    final nutritionPayloadRaw = payload['nutritionPayload'];
    final nutritionPayload = nutritionPayloadRaw is Map
        ? nutritionPayloadRaw.map(
            (key, value) => MapEntry(key.toString(), value),
          )
        : null;
    if (type.isEmpty || name.isEmpty || portion.isEmpty) return;

    final now = DateTime.now();
    final diaryDate =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final time = (payload['time'] ?? '').toString();
    final note = (payload['note'] ?? '').toString();

    await _diaryApi.addDiaryConsumptionByDate(
      diaryDate: diaryDate,
      type: type,
      name: name,
      portion: portion,
      time: time,
      note: note,
      nutritionPayload: nutritionPayload,
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

    await _diaryApi.addDiaryActivityByDate(
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

    await _diaryApi.updateDiaryBodyMetricsByDate(
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
