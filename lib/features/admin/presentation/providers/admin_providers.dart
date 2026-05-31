import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/features/admin/data/datasources/admin_api.dart';
import 'package:pulsewise/features/admin/data/models/admin_models.dart';

const _adminUsersValueNotSet = Object();

final adminApiProvider = Provider<AdminApi>((ref) {
  return AdminApi(ref.watch(apiDioProvider));
});

final adminOverviewProvider =
    FutureProvider.autoDispose<AdminOverview>((ref) async {
  return ref.watch(adminApiProvider).fetchOverview();
});

final adminPendingDoctorsProvider =
    FutureProvider.autoDispose<List<AdminDoctorReviewItem>>((ref) async {
  return ref.watch(adminApiProvider).fetchPendingDoctors();
});

final adminUserDetailProvider = StateNotifierProvider.autoDispose
    .family<AdminUserDetailNotifier, AdminUserDetailState, String>(
  (ref, userId) => AdminUserDetailNotifier(ref.watch(adminApiProvider), userId),
);

final adminDoctorDetailProvider = StateNotifierProvider.autoDispose
    .family<AdminDoctorDetailNotifier, AdminDoctorDetailState, String>(
  (ref, doctorId) =>
      AdminDoctorDetailNotifier(ref.watch(adminApiProvider), doctorId),
);

final adminUsersNotifierProvider =
    StateNotifierProvider.autoDispose<AdminUsersNotifier, AdminUsersState>(
  (ref) => AdminUsersNotifier(ref.watch(adminApiProvider)),
);

final adminDoctorsReviewNotifierProvider = StateNotifierProvider.autoDispose<
    AdminDoctorsReviewNotifier, AdminDoctorsReviewState>(
  (ref) => AdminDoctorsReviewNotifier(ref.watch(adminApiProvider)),
);

final adminUserStatusActionProvider = StateNotifierProvider.autoDispose<
    AdminUserStatusActionNotifier, AdminActionState>(
  (ref) => AdminUserStatusActionNotifier(ref, ref.watch(adminApiProvider)),
);

final adminDoctorReviewActionProvider = StateNotifierProvider.autoDispose<
    AdminDoctorReviewActionNotifier, AdminActionState>(
  (ref) => AdminDoctorReviewActionNotifier(ref, ref.watch(adminApiProvider)),
);

class AdminUsersNotifier extends StateNotifier<AdminUsersState> {
  AdminUsersNotifier(this._api) : super(const AdminUsersState());

  final AdminApi _api;

  Future<void> loadUsers({
    int page = 1,
    int? limit,
    Object? query = _adminUsersValueNotSet,
    Object? role = _adminUsersValueNotSet,
    Object? accountStatus = _adminUsersValueNotSet,
    bool append = false,
  }) async {
    if (append && (state.isLoading || state.isLoadingMore)) return;
    if (!mounted) return;

    final nextLimit = limit ?? state.limit;
    final nextQuery = identical(query, _adminUsersValueNotSet)
        ? state.query
        : (query as String? ?? '');
    final nextRole =
        identical(role, _adminUsersValueNotSet) ? state.role : role as String?;
    final nextAccountStatus = identical(accountStatus, _adminUsersValueNotSet)
        ? state.accountStatus
        : accountStatus as String?;

    state = state.copyWith(
      isLoading: !append,
      isLoadingMore: append,
      error: null,
      errorCause: null,
      page: page,
      limit: nextLimit,
      query: nextQuery,
      role: nextRole,
      accountStatus: nextAccountStatus,
    );

    try {
      final response = await _api.fetchUsers(
        page: page,
        limit: nextLimit,
        query: nextQuery,
        role: nextRole,
        accountStatus: nextAccountStatus,
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

  Future<void> refreshUsers() async {
    await loadUsers(
      page: 1,
      limit: state.limit,
      query: state.query,
      role: state.role,
      accountStatus: state.accountStatus,
    );
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || state.isLoadingMore) return;
    if (state.page >= state.totalPages) return;

    await loadUsers(
      page: state.page + 1,
      limit: state.limit,
      query: state.query,
      role: state.role,
      accountStatus: state.accountStatus,
      append: true,
    );
  }
}

class AdminUserDetailNotifier extends StateNotifier<AdminUserDetailState> {
  AdminUserDetailNotifier(this._api, this._userId)
      : super(const AdminUserDetailState()) {
    Future.microtask(fetchInitial);
  }

  final AdminApi _api;
  final String _userId;
  bool _isFetching = false;

  Future<void> fetchInitial() async {
    if (_isFetching) return;
    _isFetching = true;

    final hasUser = state.user != null;
    state = state.copyWith(
      isLoading: !hasUser,
      isRefreshing: hasUser,
      error: null,
      errorCause: null,
      clearError: true,
    );

    try {
      final user = await _api.fetchUserDetail(_userId);
      if (!mounted) return;

      state = state.copyWith(
        user: user,
        isLoading: false,
        isRefreshing: false,
        error: null,
        errorCause: null,
        clearError: true,
      );
    } catch (error) {
      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: error.toString().replaceFirst('Exception: ', ''),
        errorCause: error,
      );
    } finally {
      _isFetching = false;
    }
  }
}

class AdminUsersState {
  const AdminUsersState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.errorCause,
    this.items = const [],
    this.page = 1,
    this.limit = 20,
    this.totalItems = 0,
    this.totalPages = 1,
    this.query = '',
    this.role,
    this.accountStatus,
  });

  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final Object? errorCause;
  final List<AdminUserListItem> items;
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;
  final String query;
  final String? role;
  final String? accountStatus;

  AdminUsersState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    Object? error = _adminUsersValueNotSet,
    Object? errorCause = _adminUsersValueNotSet,
    List<AdminUserListItem>? items,
    int? page,
    int? limit,
    int? totalItems,
    int? totalPages,
    Object? query = _adminUsersValueNotSet,
    Object? role = _adminUsersValueNotSet,
    Object? accountStatus = _adminUsersValueNotSet,
  }) {
    return AdminUsersState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: identical(error, _adminUsersValueNotSet)
          ? this.error
          : error as String?,
      errorCause: identical(errorCause, _adminUsersValueNotSet)
          ? this.errorCause
          : errorCause,
      items: items ?? this.items,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalItems: totalItems ?? this.totalItems,
      totalPages: totalPages ?? this.totalPages,
      query: identical(query, _adminUsersValueNotSet)
          ? this.query
          : (query as String? ?? ''),
      role:
          identical(role, _adminUsersValueNotSet) ? this.role : role as String?,
      accountStatus: identical(accountStatus, _adminUsersValueNotSet)
          ? this.accountStatus
          : accountStatus as String?,
    );
  }
}

class AdminUserDetailState {
  const AdminUserDetailState({
    this.user,
    this.isLoading = true,
    this.isRefreshing = false,
    this.error,
    this.errorCause,
  });

  final AdminUserDetail? user;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final Object? errorCause;

  bool get hasUser => user != null;

  AdminUserDetailState copyWith({
    AdminUserDetail? user,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    Object? errorCause,
    bool clearError = false,
  }) {
    return AdminUserDetailState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : error ?? this.error,
      errorCause: clearError ? null : errorCause ?? this.errorCause,
    );
  }
}

class AdminDoctorsReviewNotifier
    extends StateNotifier<AdminDoctorsReviewState> {
  AdminDoctorsReviewNotifier(this._api)
      : super(
          const AdminDoctorsReviewState(
            status: AdminAccountStatuses.pendingAdminVerification,
          ),
        );

  final AdminApi _api;

  Future<void> loadDoctors({
    String? status,
  }) async {
    if (!mounted) return;

    final nextStatus = status ?? state.status;
    final hasItems = state.items.isNotEmpty;
    state = state.copyWith(
      isLoading: !hasItems,
      isRefreshing: hasItems,
      error: null,
      errorCause: null,
      status: nextStatus,
      clearError: true,
    );

    try {
      final items = await _api.fetchDoctors(status: nextStatus);
      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        items: items,
        error: null,
        errorCause: null,
        clearError: true,
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

  Future<void> refreshDoctors() async {
    await loadDoctors(status: state.status);
  }
}

class AdminDoctorsReviewState {
  const AdminDoctorsReviewState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.errorCause,
    this.items = const [],
    this.status = AdminAccountStatuses.pendingAdminVerification,
  });

  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final Object? errorCause;
  final List<AdminDoctorReviewItem> items;
  final String status;

  AdminDoctorsReviewState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    Object? errorCause,
    List<AdminDoctorReviewItem>? items,
    String? status,
    bool clearError = false,
  }) {
    return AdminDoctorsReviewState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : error ?? this.error,
      errorCause: clearError ? null : errorCause ?? this.errorCause,
      items: items ?? this.items,
      status: status ?? this.status,
    );
  }
}

class AdminDoctorDetailNotifier extends StateNotifier<AdminDoctorDetailState> {
  AdminDoctorDetailNotifier(this._api, this._doctorId)
      : super(const AdminDoctorDetailState()) {
    Future.microtask(fetchInitial);
  }

  final AdminApi _api;
  final String _doctorId;
  bool _isFetching = false;

  Future<void> fetchInitial() async {
    if (_isFetching) return;
    _isFetching = true;

    final hasDoctor = state.doctor != null;
    state = state.copyWith(
      isLoading: !hasDoctor,
      isRefreshing: hasDoctor,
      error: null,
      errorCause: null,
      clearError: true,
    );

    try {
      final doctor = await _api.fetchDoctorDetail(_doctorId);
      if (!mounted) return;

      state = state.copyWith(
        doctor: doctor,
        isLoading: false,
        isRefreshing: false,
        error: null,
        errorCause: null,
        clearError: true,
      );
    } catch (error) {
      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: error.toString().replaceFirst('Exception: ', ''),
        errorCause: error,
      );
    } finally {
      _isFetching = false;
    }
  }
}

class AdminDoctorDetailState {
  const AdminDoctorDetailState({
    this.doctor,
    this.isLoading = true,
    this.isRefreshing = false,
    this.error,
    this.errorCause,
  });

  final AdminDoctorDetail? doctor;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final Object? errorCause;

  bool get hasDoctor => doctor != null;

  AdminDoctorDetailState copyWith({
    AdminDoctorDetail? doctor,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    Object? errorCause,
    bool clearError = false,
  }) {
    return AdminDoctorDetailState(
      doctor: doctor ?? this.doctor,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : error ?? this.error,
      errorCause: clearError ? null : errorCause ?? this.errorCause,
    );
  }
}

class AdminActionState {
  const AdminActionState({
    this.isLoading = false,
    this.error,
    this.message,
  });

  final bool isLoading;
  final String? error;
  final String? message;

  AdminActionState copyWith({
    bool? isLoading,
    String? error,
    String? message,
  }) {
    return AdminActionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      message: message ?? this.message,
    );
  }
}

class AdminUserStatusActionNotifier extends StateNotifier<AdminActionState> {
  AdminUserStatusActionNotifier(this._ref, this._api)
      : super(const AdminActionState());

  final Ref _ref;
  final AdminApi _api;

  Future<AdminMutationResult?> updateStatus(
    String userId,
    String accountStatus,
  ) async {
    if (state.isLoading) return null;
    state = const AdminActionState(isLoading: true);

    try {
      final result = await _api.updateUserStatus(
        userId,
        AdminUpdateUserStatusRequest(accountStatus: accountStatus),
      );
      _ref.invalidate(adminOverviewProvider);
      _ref.invalidate(adminPendingDoctorsProvider);
      _ref.read(adminUserDetailProvider(userId).notifier).fetchInitial();
      await _ref.read(adminUsersNotifierProvider.notifier).refreshUsers();

      state = AdminActionState(
        isLoading: false,
        message: result.message,
      );
      return result;
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      state = AdminActionState(
        isLoading: false,
        error: message,
      );
      return null;
    }
  }
}

class AdminDoctorReviewActionNotifier extends StateNotifier<AdminActionState> {
  AdminDoctorReviewActionNotifier(this._ref, this._api)
      : super(const AdminActionState());

  final Ref _ref;
  final AdminApi _api;

  Future<AdminMutationResult?> approveDoctor(
    String doctorId,
    String verificationNote,
  ) async {
    return _runDoctorMutation(
      doctorId: doctorId,
      action: () => _api.approveDoctor(
        doctorId,
        AdminApproveDoctorRequest(
          verificationNote: verificationNote,
        ),
      ),
    );
  }

  Future<AdminMutationResult?> rejectDoctor(
    String doctorId,
    String rejectionReason,
  ) async {
    return _runDoctorMutation(
      doctorId: doctorId,
      action: () => _api.rejectDoctor(
        doctorId,
        AdminRejectDoctorRequest(
          rejectionReason: rejectionReason,
        ),
      ),
    );
  }

  Future<AdminMutationResult?> suspendDoctor(
    String doctorId,
    String verificationNote,
  ) async {
    return _runDoctorMutation(
      doctorId: doctorId,
      action: () => _api.suspendDoctor(
        doctorId,
        AdminSuspendDoctorRequest(
          verificationNote: verificationNote,
        ),
      ),
    );
  }

  Future<AdminMutationResult?> reactivateDoctor(String doctorId) async {
    return _runDoctorMutation(
      doctorId: doctorId,
      action: () => _api.reactivateDoctor(doctorId),
    );
  }

  Future<AdminMutationResult?> _runDoctorMutation({
    required String doctorId,
    required Future<AdminMutationResult> Function() action,
  }) async {
    if (state.isLoading) return null;
    state = const AdminActionState(isLoading: true);

    try {
      final result = await action();
      _ref.invalidate(adminOverviewProvider);
      _ref.invalidate(adminPendingDoctorsProvider);
      _ref.read(adminDoctorDetailProvider(doctorId).notifier).fetchInitial();
      await _ref
          .read(adminDoctorsReviewNotifierProvider.notifier)
          .refreshDoctors();
      await _ref.read(adminUsersNotifierProvider.notifier).refreshUsers();

      state = AdminActionState(
        isLoading: false,
        message: result.message,
      );
      return result;
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      state = AdminActionState(
        isLoading: false,
        error: message,
      );
      return null;
    }
  }
}
