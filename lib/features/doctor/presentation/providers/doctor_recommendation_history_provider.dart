import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/features/doctor/data/datasources/doctor_dashboard_api.dart';
import 'package:pulsewise/features/doctor/presentation/providers/doctor_dashboard_provider.dart';
import 'package:pulsewise/features/ml_recommendation/data/models/ml_recommendation_models.dart';

final doctorRecommendationHistoryNotifierProvider =
    StateNotifierProvider.autoDispose.family<
        DoctorRecommendationHistoryNotifier,
        DoctorRecommendationHistoryState,
        String>(
  (ref, patientId) {
    return DoctorRecommendationHistoryNotifier(
      ref.watch(doctorDashboardApiProvider),
      patientId,
    );
  },
);

class DoctorRecommendationHistoryNotifier
    extends StateNotifier<DoctorRecommendationHistoryState> {
  DoctorRecommendationHistoryNotifier(
    this._doctorDashboardApi,
    this._patientId,
  ) : super(const DoctorRecommendationHistoryState());

  final DoctorDashboardApi _doctorDashboardApi;
  final String _patientId;

  Future<void> loadRecommendationHistory({
    int page = 1,
    int limit = 10,
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
    );

    try {
      final response =
          await _doctorDashboardApi.fetchPatientMlRecommendationHistory(
        _patientId,
        page: page,
        limit: limit,
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

  Future<void> loadNextPage() async {
    if (state.isLoading || state.isLoadingMore) return;
    if (state.page >= state.totalPages) return;

    await loadRecommendationHistory(
      page: state.page + 1,
      limit: state.limit,
      append: true,
    );
  }

  Future<void> refreshHistory() async {
    if (!mounted) return;

    state = state.copyWith(
      detailsByResultId: const {},
      detailErrorsByResultId: const {},
      detailErrorCausesByResultId: const {},
      loadingDetailResultIds: const {},
    );

    await loadRecommendationHistory(page: 1, limit: state.limit);
  }

  Future<void> loadRecommendationDetail(String resultId) async {
    if (state.detailsByResultId.containsKey(resultId)) return;
    if (state.loadingDetailResultIds.contains(resultId)) return;
    if (!mounted) return;

    final nextLoadingIds = {...state.loadingDetailResultIds, resultId};
    final nextErrors = {...state.detailErrorsByResultId}..remove(resultId);
    final nextErrorCauses = {...state.detailErrorCausesByResultId}
      ..remove(resultId);

    state = state.copyWith(
      loadingDetailResultIds: nextLoadingIds,
      detailErrorsByResultId: nextErrors,
      detailErrorCausesByResultId: nextErrorCauses,
    );

    try {
      final detail =
          await _doctorDashboardApi.fetchPatientMlRecommendationHistoryDetail(
        _patientId,
        resultId,
      );
      if (!mounted) return;

      final updatedDetails = {
        ...state.detailsByResultId,
        resultId: detail,
      };
      final updatedLoading = {...state.loadingDetailResultIds}
        ..remove(resultId);
      final updatedErrorCauses = {...state.detailErrorCausesByResultId}
        ..remove(resultId);

      state = state.copyWith(
        detailsByResultId: updatedDetails,
        loadingDetailResultIds: updatedLoading,
        detailErrorCausesByResultId: updatedErrorCauses,
      );
    } catch (error) {
      if (!mounted) return;

      final updatedLoading = {...state.loadingDetailResultIds}
        ..remove(resultId);
      final updatedErrors = {
        ...state.detailErrorsByResultId,
        resultId: error.toString().replaceFirst('Exception: ', ''),
      };
      final updatedErrorCauses = {
        ...state.detailErrorCausesByResultId,
        resultId: error,
      };

      state = state.copyWith(
        loadingDetailResultIds: updatedLoading,
        detailErrorsByResultId: updatedErrors,
        detailErrorCausesByResultId: updatedErrorCauses,
      );
    }
  }
}

class DoctorRecommendationHistoryState {
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final Object? errorCause;
  final List<MlRecommendationHistoryItem> items;
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;
  final Map<String, MlRecommendationResponse> detailsByResultId;
  final Set<String> loadingDetailResultIds;
  final Map<String, String> detailErrorsByResultId;
  final Map<String, Object> detailErrorCausesByResultId;

  const DoctorRecommendationHistoryState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.errorCause,
    this.items = const [],
    this.page = 1,
    this.limit = 10,
    this.totalItems = 0,
    this.totalPages = 1,
    this.detailsByResultId = const {},
    this.loadingDetailResultIds = const {},
    this.detailErrorsByResultId = const {},
    this.detailErrorCausesByResultId = const {},
  });

  DoctorRecommendationHistoryState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    Object? errorCause,
    List<MlRecommendationHistoryItem>? items,
    int? page,
    int? limit,
    int? totalItems,
    int? totalPages,
    Map<String, MlRecommendationResponse>? detailsByResultId,
    Set<String>? loadingDetailResultIds,
    Map<String, String>? detailErrorsByResultId,
    Map<String, Object>? detailErrorCausesByResultId,
  }) {
    return DoctorRecommendationHistoryState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      errorCause: errorCause,
      items: items ?? this.items,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalItems: totalItems ?? this.totalItems,
      totalPages: totalPages ?? this.totalPages,
      detailsByResultId: detailsByResultId ?? this.detailsByResultId,
      loadingDetailResultIds:
          loadingDetailResultIds ?? this.loadingDetailResultIds,
      detailErrorsByResultId:
          detailErrorsByResultId ?? this.detailErrorsByResultId,
      detailErrorCausesByResultId:
          detailErrorCausesByResultId ?? this.detailErrorCausesByResultId,
    );
  }
}
