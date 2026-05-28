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

final adminUserDetailProvider = FutureProvider.autoDispose
    .family<AdminUserDetail, String>((ref, userId) async {
  return ref.watch(adminApiProvider).fetchUserDetail(userId);
});

final adminDoctorDetailProvider = FutureProvider.autoDispose
    .family<AdminDoctorDetail, String>((ref, doctorId) async {
  return ref.watch(adminApiProvider).fetchDoctorDetail(doctorId);
});

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

class AdminUsersState {
  const AdminUsersState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
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
    state = state.copyWith(
      isLoading: true,
      error: null,
      status: nextStatus,
    );

    try {
      final items = await _api.fetchDoctors(status: nextStatus);
      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        items: items,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: error.toString().replaceFirst('Exception: ', ''),
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
    this.error,
    this.items = const [],
    this.status = AdminAccountStatuses.pendingAdminVerification,
  });

  final bool isLoading;
  final String? error;
  final List<AdminDoctorReviewItem> items;
  final String status;

  AdminDoctorsReviewState copyWith({
    bool? isLoading,
    String? error,
    List<AdminDoctorReviewItem>? items,
    String? status,
  }) {
    return AdminDoctorsReviewState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      items: items ?? this.items,
      status: status ?? this.status,
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
      _ref.invalidate(adminUserDetailProvider(userId));
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
      _ref.invalidate(adminDoctorDetailProvider(doctorId));
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
