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
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString().replaceFirst('Exception: ', ''),
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

    state = state.copyWith(
      loadingDetailDiaryIds: loadingIds,
      detailErrorsByDiaryId: detailErrors,
    );

    try {
      var detail = await _diaryApi.fetchDiaryDetail(diaryDate);
      final sleepData = await _diaryApi.fetchSleepDiaryByDate(diaryDate);
      if (sleepData != null) {
        detail = detail.copyWith(
          sleeps: [DiarySleep.fromJson(sleepData)],
        );
      }

      if (!mounted) return;

      final nextDetails = {...state.detailsByDiaryId, diaryDate: detail};
      final nextLoadingIds = {...state.loadingDetailDiaryIds}
        ..remove(diaryDate);

      state = state.copyWith(
        detailsByDiaryId: nextDetails,
        loadingDetailDiaryIds: nextLoadingIds,
      );
    } catch (e) {
      if (!mounted) return;

      final nextLoadingIds = {...state.loadingDetailDiaryIds}
        ..remove(diaryDate);
      final nextErrors = {
        ...state.detailErrorsByDiaryId,
        diaryDate: e.toString().replaceFirst('Exception: ', ''),
      };

      state = state.copyWith(
        loadingDetailDiaryIds: nextLoadingIds,
        detailErrorsByDiaryId: nextErrors,
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

  const DiaryHistoryState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
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
  });

  DiaryHistoryState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
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
  }) {
    return DiaryHistoryState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
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
    );
  }
}
