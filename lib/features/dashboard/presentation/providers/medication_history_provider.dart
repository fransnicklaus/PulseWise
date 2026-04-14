import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'profile_provider.dart';

final medicationDetailProvider =
    FutureProvider.autoDispose.family<MedicationItem, String>((ref, id) async {
  return ref.watch(profileApiProvider).fetchMedicationDetail(id);
});

final medicationHistoryProvider = StateNotifierProvider.autoDispose<
    MedicationHistoryNotifier, MedicationHistoryState>(
  (ref) => MedicationHistoryNotifier(ref.watch(profileApiProvider)),
);

class MedicationHistoryNotifier extends StateNotifier<MedicationHistoryState> {
  MedicationHistoryNotifier(this._profileApi)
      : super(const MedicationHistoryState());

  final ProfileApi _profileApi;

  Future<void> loadMedications({
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
      page: page,
      limit: limit,
    );

    try {
      final response = await _profileApi.fetchMedications(
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

    await loadMedications(
      page: state.page + 1,
      limit: state.limit,
      append: true,
    );
  }

  Future<void> refreshMedications() async {
    await loadMedications(page: 1, limit: state.limit);
  }
}

class MedicationHistoryState {
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final List<MedicationItem> items;
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;

  const MedicationHistoryState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.items = const [],
    this.page = 1,
    this.limit = 10,
    this.totalItems = 0,
    this.totalPages = 1,
  });

  MedicationHistoryState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    List<MedicationItem>? items,
    int? page,
    int? limit,
    int? totalItems,
    int? totalPages,
  }) {
    return MedicationHistoryState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      items: items ?? this.items,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalItems: totalItems ?? this.totalItems,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}
