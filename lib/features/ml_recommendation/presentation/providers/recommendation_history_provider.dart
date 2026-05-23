import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/features/ml_recommendation/data/datasources/ml_recommendation_api.dart';
import 'package:pulsewise/features/ml_recommendation/data/models/ml_recommendation_models.dart';
import 'package:pulsewise/features/ml_recommendation/presentation/providers/ml_recommendation_provider.dart';

final recommendationHistoryNotifierProvider = StateNotifierProvider.autoDispose<
    RecommendationHistoryNotifier, RecommendationHistoryState>(
  (ref) {
    return RecommendationHistoryNotifier(
        ref.watch(mlRecommendationApiProvider));
  },
);

class RecommendationHistoryNotifier
    extends StateNotifier<RecommendationHistoryState> {
  RecommendationHistoryNotifier(this._recommendationApi)
      : super(const RecommendationHistoryState());

  final MlRecommendationApi _recommendationApi;

  Future<void> loadRecommendationHistory({
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
      final response = await _recommendationApi.fetchMlRecommendationHistory(
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

    await loadRecommendationHistory(
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

    await loadRecommendationHistory(
      page: 1,
      limit: state.limit,
    );
  }

  Future<void> loadRecommendationDetail(String resultId) async {
    // if (diaryId == null) return;
    if (state.detailsByDiaryId.containsKey(resultId)) return;
    if (state.loadingDetailDiaryIds.contains(resultId)) return;
    if (!mounted) return;

    final loadingIds = {...state.loadingDetailDiaryIds, resultId};
    final detailErrors = {...state.detailErrorsByDiaryId}..remove(resultId);

    state = state.copyWith(
      loadingDetailDiaryIds: loadingIds,
      detailErrorsByDiaryId: detailErrors,
    );

    try {
      final detail =
          await _recommendationApi.fetchMlRecommendationHistoryDetail(
        resultId,
      );
      if (!mounted) return;

      final Map<String, MlRecommendationResponse> nextDetails = {
        ...state.detailsByDiaryId,
        resultId: detail
      };
      final nextLoadingIds = {...state.loadingDetailDiaryIds}..remove(resultId);

      state = state.copyWith(
        detailsByDiaryId: nextDetails,
        loadingDetailDiaryIds: nextLoadingIds,
      );
    } catch (e) {
      if (!mounted) return;

      final nextLoadingIds = {...state.loadingDetailDiaryIds}..remove(resultId);
      final nextErrors = {
        ...state.detailErrorsByDiaryId,
        resultId: e.toString().replaceFirst('Exception: ', ''),
      };

      state = state.copyWith(
        loadingDetailDiaryIds: nextLoadingIds,
        detailErrorsByDiaryId: nextErrors,
      );
    }
  }

  void clearCache() {
    if (!mounted) return;
    state = const RecommendationHistoryState();
  }
}

class RecommendationHistoryState {
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final List<MlRecommendationHistoryItem> items;
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<String, MlRecommendationResponse> detailsByDiaryId;
  final Set<String> loadingDetailDiaryIds;
  final Map<String, String> detailErrorsByDiaryId;

  const RecommendationHistoryState({
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

  RecommendationHistoryState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    List<MlRecommendationHistoryItem>? items,
    int? page,
    int? limit,
    int? totalItems,
    int? totalPages,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, MlRecommendationResponse>? detailsByDiaryId,
    Set<String>? loadingDetailDiaryIds,
    Map<String, String>? detailErrorsByDiaryId,
  }) {
    return RecommendationHistoryState(
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
