import 'package:pulsewise/features/diary/data/datasources/diary_api.dart';
import 'package:pulsewise/features/diary/data/models/diary_models.dart';
import 'package:pulsewise/features/diary/presentation/providers/diary_history_provider.dart';

class DoctorPatientDiaryHistoryNotifier extends DiaryHistoryNotifier {
  DoctorPatientDiaryHistoryNotifier(
    this._diaryApi,
    this._patientId,
  ) : super(_diaryApi);

  final DiaryApi _diaryApi;
  final String _patientId;

  @override
  Future<void> loadDiaryHistory({
    int page = 1,
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
    bool append = false,
  }) async {
    if (append && (state.isLoading || state.isLoadingMore)) return;
    if (!mounted) return;

    state = state.copyWith(
      isLoading: !append,
      isLoadingMore: append,
      error: null,
      errorCause: null,
      page: page,
      limit: limit,
      startDate: startDate,
      endDate: endDate,
    );

    try {
      final response = await _diaryApi.fetchDiaryHistoryForUser(
        _patientId,
        page: page,
        limit: limit,
        startDate: startDate,
        endDate: endDate,
      );

      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        items: append ? [...state.items, ...response.items] : response.items,
        page: response.pagination.page,
        limit: response.pagination.limit,
        totalItems: response.pagination.totalItems,
        totalPages: response.pagination.totalPages,
        errorCause: null,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: error.toString().replaceFirst('Exception: ', ''),
        errorCause: error,
      );
    }
  }

  @override
  Future<void> loadDiaryDetail(DateTime diaryDate) async {
    if (state.detailsByDiaryId.containsKey(diaryDate)) return;
    if (state.loadingDetailDiaryIds.contains(diaryDate)) return;
    if (!mounted) return;

    final loadingIds = {...state.loadingDetailDiaryIds, diaryDate};
    final detailErrors = {...state.detailErrorsByDiaryId}..remove(diaryDate);

    state = state.copyWith(
      loadingDetailDiaryIds: loadingIds,
      detailErrorsByDiaryId: detailErrors,
      detailErrorCausesByDiaryId: {
        ...state.detailErrorCausesByDiaryId,
      }..remove(diaryDate),
    );

    try {
      var detail = await _diaryApi.fetchDiaryDetailForUser(
        _patientId,
        diaryDate,
      );
      Map<String, dynamic>? sleepData;
      try {
        sleepData = await _diaryApi.fetchSleepDiaryByDateForUser(
          _patientId,
          diaryDate,
        );
      } catch (_) {
        sleepData = null;
      }
      if (sleepData != null) {
        detail = detail.copyWith(
          sleeps: [DiarySleep.fromJson(sleepData)],
        );
      }

      if (!mounted) return;

      final nextDetails = {...state.detailsByDiaryId, diaryDate: detail};
      final nextLoadingIds = {...state.loadingDetailDiaryIds}
        ..remove(diaryDate);
      final nextErrorCauses = {...state.detailErrorCausesByDiaryId}
        ..remove(diaryDate);

      state = state.copyWith(
        detailsByDiaryId: nextDetails,
        loadingDetailDiaryIds: nextLoadingIds,
        detailErrorCausesByDiaryId: nextErrorCauses,
      );
    } catch (error) {
      if (!mounted) return;

      final nextLoadingIds = {...state.loadingDetailDiaryIds}
        ..remove(diaryDate);
      final nextErrors = {
        ...state.detailErrorsByDiaryId,
        diaryDate: error.toString().replaceFirst('Exception: ', ''),
      };
      final nextErrorCauses = {
        ...state.detailErrorCausesByDiaryId,
        diaryDate: error,
      };

      state = state.copyWith(
        loadingDetailDiaryIds: nextLoadingIds,
        detailErrorsByDiaryId: nextErrors,
        detailErrorCausesByDiaryId: nextErrorCauses,
      );
    }
  }

  @override
  Future<void> saveMyNoteForDate(DateTime diaryDate, String content) async {
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) {
      await _diaryApi.deleteMyDiaryNoteByDate(
        patientId: _patientId,
        date: diaryDate,
      );
    } else {
      await _diaryApi.upsertMyDiaryNoteByDate(
        patientId: _patientId,
        diaryDate:
            '${diaryDate.year.toString().padLeft(4, '0')}-${diaryDate.month.toString().padLeft(2, '0')}-${diaryDate.day.toString().padLeft(2, '0')}',
        content: trimmedContent,
      );
    }

    if (!mounted) return;

    final nextDetails = {...state.detailsByDiaryId}..remove(diaryDate);
    state = state.copyWith(detailsByDiaryId: nextDetails);
    await loadDiaryDetail(diaryDate);
  }
}
