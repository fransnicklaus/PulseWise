import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/features/doctor/data/datasources/doctor_profile_api.dart';
import 'package:pulsewise/features/doctor/data/models/doctor_profile_models.dart';

final doctorProfileApiProvider = Provider<DoctorProfileApi>((ref) {
  return DoctorProfileApi(ref.watch(apiDioProvider));
});

final doctorProfileProvider = FutureProvider<DoctorProfile>((ref) async {
  final api = ref.watch(doctorProfileApiProvider);
  return api.fetchProfile();
});

final doctorProfileNotifierProvider =
    StateNotifierProvider<DoctorProfileNotifier, DoctorProfileState>((ref) {
  return DoctorProfileNotifier(ref.watch(doctorProfileApiProvider));
});

class DoctorProfileNotifier extends StateNotifier<DoctorProfileState> {
  DoctorProfileNotifier(this._api) : super(const DoctorProfileState()) {
    fetchInitial();
  }

  final DoctorProfileApi _api;

  Future<void> fetchInitial() async {
    if (state.isLoading) return;
    await _load(isRefresh: false);
  }

  Future<void> refreshProfile() async {
    if (state.isRefreshing) return;
    await _load(isRefresh: state.profile != null);
  }

  Future<void> reloadProfile() async {
    await _load(isRefresh: false, force: true);
  }

  Future<void> _load({
    required bool isRefresh,
    bool force = false,
  }) async {
    if (!mounted) return;
    if (!force && (state.isLoading || state.isRefreshing)) return;

    state = state.copyWith(
      isLoading: !isRefresh,
      isRefreshing: isRefresh,
      error: null,
      errorCause: null,
    );

    try {
      final profile = await _api.fetchProfile();
      if (!mounted) return;

      state = state.copyWith(
        profile: profile,
        isLoading: false,
        isRefreshing: false,
        error: null,
        errorCause: null,
      );
    } catch (error) {
      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: error.toString().replaceFirst('Exception: ', ''),
        errorCause: error,
      );
    }
  }
}

class DoctorProfileState {
  const DoctorProfileState({
    this.profile,
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.errorCause,
  });

  final DoctorProfile? profile;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final Object? errorCause;

  DoctorProfileState copyWith({
    DoctorProfile? profile,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    Object? errorCause,
  }) {
    return DoctorProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
      errorCause: errorCause,
    );
  }
}
