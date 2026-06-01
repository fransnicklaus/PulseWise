import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/features/doctor/data/datasources/doctor_dashboard_api.dart';
import 'package:pulsewise/features/doctor/data/models/doctor_dashboard_models.dart';
import 'package:pulsewise/features/doctor/presentation/providers/doctor_dashboard_provider.dart';

const _doctorPatientsValueNotSet = Object();

final doctorPatientsNotifierProvider = StateNotifierProvider.autoDispose<
    DoctorPatientsNotifier, DoctorPatientsState>(
  (ref) => DoctorPatientsNotifier(ref.watch(doctorDashboardApiProvider)),
);

class DoctorPatientsNotifier extends StateNotifier<DoctorPatientsState> {
  DoctorPatientsNotifier(this._api) : super(const DoctorPatientsState());

  final DoctorDashboardApi _api;

  Future<void> loadPatients({
    int page = 1,
    int limit = 20,
    bool append = false,
  }) async {
    if (append && (state.isLoading || state.isLoadingMore)) return;
    if (!mounted) return;

    final hasItems = state.items.isNotEmpty;
    state = state.copyWith(
      isLoading: !append && !hasItems,
      isRefreshing: !append && hasItems,
      isLoadingMore: append,
      error: null,
      errorCause: null,
      page: page,
      limit: limit,
      clearError: true,
    );

    try {
      final response = await _api.fetchPatients(page: page, limit: limit);
      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        items: append ? [...state.items, ...response.items] : response.items,
        page: response.pagination.page,
        limit: response.pagination.limit,
        totalItems: response.pagination.totalItems,
        totalPages: response.pagination.totalPages,
        error: null,
        errorCause: null,
        clearError: true,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        error: error.toString().replaceFirst('Exception: ', ''),
        errorCause: error,
      );
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || state.isLoadingMore) return;
    if (state.page >= state.totalPages) return;

    await loadPatients(
      page: state.page + 1,
      limit: state.limit,
      append: true,
    );
  }

  Future<void> refreshPatients() async {
    await loadPatients(page: 1, limit: state.limit);
  }
}

class DoctorPatientsState {
  const DoctorPatientsState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.error,
    this.errorCause,
    this.items = const [],
    this.page = 1,
    this.limit = 20,
    this.totalItems = 0,
    this.totalPages = 1,
  });

  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? error;
  final Object? errorCause;
  final List<DoctorDashboardPatientListItem> items;
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;

  DoctorPatientsState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    Object? error = _doctorPatientsValueNotSet,
    Object? errorCause = _doctorPatientsValueNotSet,
    List<DoctorDashboardPatientListItem>? items,
    int? page,
    int? limit,
    int? totalItems,
    int? totalPages,
    bool clearError = false,
  }) {
    return DoctorPatientsState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError
          ? null
          : identical(error, _doctorPatientsValueNotSet)
              ? this.error
              : error as String?,
      errorCause: clearError
          ? null
          : identical(errorCause, _doctorPatientsValueNotSet)
              ? this.errorCause
              : errorCause,
      items: items ?? this.items,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalItems: totalItems ?? this.totalItems,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}
