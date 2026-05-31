import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/features/diary/data/datasources/diary_api.dart';
import 'package:pulsewise/features/diary/data/models/diary_models.dart';

final diaryHistoryProvider =
    StateNotifierProvider.autoDispose<DiaryHistoryNotifier, DiaryHistoryState>(
  (ref) {
    return DiaryHistoryNotifier(ref.watch(diaryApiProvider));
  },
);

class DiaryHistoryNotifier extends StateNotifier<DiaryHistoryState> {
  DiaryHistoryNotifier(this._diaryApi) : super(const DiaryHistoryState());

  final DiaryApi _diaryApi;

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
      final response = await _diaryApi.fetchDiaryHistory(
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
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString().replaceFirst('Exception: ', ''),
        errorCause: e,
      );
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || state.isLoadingMore) return;
    if (state.page >= state.totalPages) return;

    await loadDiaryHistory(
      page: state.page + 1,
      limit: state.limit,
      startDate: state.startDate,
      endDate: state.endDate,
      append: true,
    );
  }

  Future<void> refreshHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!mounted) return;

    state = state.copyWith(
      detailsByDiaryId: const {},
      detailErrorsByDiaryId: const {},
      detailErrorCausesByDiaryId: const {},
      loadingDetailDiaryIds: const {},
    );

    await loadDiaryHistory(
      page: 1,
      limit: state.limit,
      startDate: startDate ?? state.startDate,
      endDate: endDate ?? state.endDate,
    );
  }

  Future<void> loadDiaryDetail(DateTime diaryDate) async {
    // if (diaryId == null) return;
    if (state.detailsByDiaryId.containsKey(diaryDate)) return;
    if (state.loadingDetailDiaryIds.contains(diaryDate)) return;
    if (!mounted) return;

    final loadingIds = {...state.loadingDetailDiaryIds, diaryDate};
    final detailErrors = {...state.detailErrorsByDiaryId}..remove(diaryDate);
    final detailErrorCauses = {...state.detailErrorCausesByDiaryId}
      ..remove(diaryDate);

    state = state.copyWith(
      loadingDetailDiaryIds: loadingIds,
      detailErrorsByDiaryId: detailErrors,
      detailErrorCausesByDiaryId: detailErrorCauses,
    );

    try {
      var detail = await _diaryApi.fetchDiaryDetail(diaryDate);
      Map<String, dynamic>? sleepData;
      try {
        sleepData = await _diaryApi.fetchSleepDiaryByDate(diaryDate);
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
    } catch (e) {
      if (!mounted) return;

      final nextLoadingIds = {...state.loadingDetailDiaryIds}
        ..remove(diaryDate);
      final nextErrors = {
        ...state.detailErrorsByDiaryId,
        diaryDate: e.toString().replaceFirst('Exception: ', ''),
      };
      final nextErrorCauses = {
        ...state.detailErrorCausesByDiaryId,
        diaryDate: e,
      };

      state = state.copyWith(
        loadingDetailDiaryIds: nextLoadingIds,
        detailErrorsByDiaryId: nextErrors,
        detailErrorCausesByDiaryId: nextErrorCauses,
      );
    }
  }

  void clearCache() {
    if (!mounted) return;
    state = const DiaryHistoryState();
  }
}

class DiaryHistoryState {
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final Object? errorCause;
  final List<DiaryHistoryItem> items;
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<DateTime, DiaryDetail> detailsByDiaryId;
  final Set<DateTime> loadingDetailDiaryIds;
  final Map<DateTime, String> detailErrorsByDiaryId;
  final Map<DateTime, Object> detailErrorCausesByDiaryId;

  const DiaryHistoryState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.errorCause,
    this.items = const [],
    this.page = 1,
    this.limit = 10,
    this.totalItems = 0,
    this.totalPages = 1,
    this.startDate,
    this.endDate,
    this.detailsByDiaryId = const {},
    this.loadingDetailDiaryIds = const {},
    this.detailErrorsByDiaryId = const {},
    this.detailErrorCausesByDiaryId = const {},
  });

  DiaryHistoryState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    Object? errorCause,
    List<DiaryHistoryItem>? items,
    int? page,
    int? limit,
    int? totalItems,
    int? totalPages,
    DateTime? startDate,
    DateTime? endDate,
    Map<DateTime, DiaryDetail>? detailsByDiaryId,
    Set<DateTime>? loadingDetailDiaryIds,
    Map<DateTime, String>? detailErrorsByDiaryId,
    Map<DateTime, Object>? detailErrorCausesByDiaryId,
  }) {
    return DiaryHistoryState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      errorCause: errorCause,
      items: items ?? this.items,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalItems: totalItems ?? this.totalItems,
      totalPages: totalPages ?? this.totalPages,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      detailsByDiaryId: detailsByDiaryId ?? this.detailsByDiaryId,
      loadingDetailDiaryIds:
          loadingDetailDiaryIds ?? this.loadingDetailDiaryIds,
      detailErrorsByDiaryId:
          detailErrorsByDiaryId ?? this.detailErrorsByDiaryId,
      detailErrorCausesByDiaryId:
          detailErrorCausesByDiaryId ?? this.detailErrorCausesByDiaryId,
    );
  }
}
