import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/features/doctor/data/datasources/doctor_dashboard_api.dart';
import 'package:pulsewise/features/doctor/data/models/doctor_dashboard_models.dart';
import 'package:pulsewise/features/doctor/presentation/providers/doctor_dashboard_provider.dart';

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

    state = state.copyWith(
      isLoading: !append,
      isLoadingMore: append,
      error: null,
      page: page,
      limit: limit,
    );

    try {
      final response = await _api.fetchPatients(page: page, limit: limit);
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
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: error.toString().replaceFirst('Exception: ', ''),
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
    this.isLoadingMore = false,
    this.error,
    this.items = const [],
    this.page = 1,
    this.limit = 20,
    this.totalItems = 0,
    this.totalPages = 1,
  });

  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final List<DoctorDashboardPatientListItem> items;
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;

  DoctorPatientsState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    List<DoctorDashboardPatientListItem>? items,
    int? page,
    int? limit,
    int? totalItems,
    int? totalPages,
  }) {
    return DoctorPatientsState(
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
