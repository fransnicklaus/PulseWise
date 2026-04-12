import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'current_diary_provider.dart';
import 'profile_provider.dart';

final diaryHistoryProvider =
    StateNotifierProvider.autoDispose<DiaryHistoryNotifier, DiaryHistoryState>(
  (ref) {
    return DiaryHistoryNotifier(ref.watch(profileApiProvider));
  },
);

class DiaryHistoryNotifier extends StateNotifier<DiaryHistoryState> {
  DiaryHistoryNotifier(this._profileApi) : super(const DiaryHistoryState());

  final ProfileApi _profileApi;

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
      final response = await _profileApi.fetchDiaryHistory(
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

  Future<void> loadDiaryDetail(String diaryId) async {
    if (diaryId.isEmpty) return;
    if (state.detailsByDiaryId.containsKey(diaryId)) return;
    if (state.loadingDetailDiaryIds.contains(diaryId)) return;
    if (!mounted) return;

    final loadingIds = {...state.loadingDetailDiaryIds, diaryId};
    final detailErrors = {...state.detailErrorsByDiaryId}..remove(diaryId);

    state = state.copyWith(
      loadingDetailDiaryIds: loadingIds,
      detailErrorsByDiaryId: detailErrors,
    );

    try {
      final detail = await _profileApi.fetchDiaryDetail(diaryId);
      if (!mounted) return;

      final nextDetails = {...state.detailsByDiaryId, diaryId: detail};
      final nextLoadingIds = {...state.loadingDetailDiaryIds}..remove(diaryId);

      state = state.copyWith(
        detailsByDiaryId: nextDetails,
        loadingDetailDiaryIds: nextLoadingIds,
      );
    } catch (e) {
      if (!mounted) return;

      final nextLoadingIds = {...state.loadingDetailDiaryIds}..remove(diaryId);
      final nextErrors = {
        ...state.detailErrorsByDiaryId,
        diaryId: e.toString().replaceFirst('Exception: ', ''),
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
  final Map<String, DiaryDetail> detailsByDiaryId;
  final Set<String> loadingDetailDiaryIds;
  final Map<String, String> detailErrorsByDiaryId;

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
    Map<String, DiaryDetail>? detailsByDiaryId,
    Set<String>? loadingDetailDiaryIds,
    Map<String, String>? detailErrorsByDiaryId,
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
