import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/admin/data/datasources/admin_api.dart';
import 'package:pulsewise/features/admin/data/models/admin_models.dart';
import 'package:pulsewise/features/admin/presentation/providers/admin_providers.dart';

void main() {
  group('AdminUsersNotifier', () {
    test('loads first page with filters and stores pagination state', () async {
      String observedQuery = '';
      String? observedRole;

      final notifier = AdminUsersNotifier(_FakeAdminApi(
        fetchUsersHandler: ({
          required int page,
          required int limit,
          required String query,
          String? role,
          String? accountStatus,
        }) async {
          observedQuery = query;
          observedRole = role;
          return AdminUsersPageData(
            items: [_userListItem('user-1')],
            pagination: const AdminPagination(
              page: 1,
              limit: 10,
              totalItems: 1,
              totalPages: 1,
            ),
          );
        },
      ));

      await notifier.loadUsers(
        limit: 10,
        query: 'doctor',
        role: AdminManagedRoles.doctor,
      );

      expect(observedQuery, 'doctor');
      expect(observedRole, AdminManagedRoles.doctor);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
      expect(notifier.state.items.single.userId, 'user-1');
      expect(notifier.state.limit, 10);
      expect(notifier.state.totalItems, 1);
    });

    test('loads next page and appends items', () async {
      final notifier = AdminUsersNotifier(_FakeAdminApi(
        fetchUsersHandler: ({
          required int page,
          required int limit,
          required String query,
          String? role,
          String? accountStatus,
        }) async {
          return AdminUsersPageData(
            items: [_userListItem('user-$page')],
            pagination: AdminPagination(
              page: page,
              limit: limit,
              totalItems: 2,
              totalPages: 2,
            ),
          );
        },
      ));

      await notifier.loadUsers();
      await notifier.loadNextPage();

      expect(notifier.state.items, hasLength(2));
      expect(notifier.state.items.first.userId, 'user-1');
      expect(notifier.state.items.last.userId, 'user-2');
    });

    test('does not load next page when already at the last page', () async {
      final api = _FakeAdminApi(
        fetchUsersHandler: ({
          required int page,
          required int limit,
          required String query,
          String? role,
          String? accountStatus,
        }) async {
          return AdminUsersPageData(
            items: [_userListItem('user-$page')],
            pagination: const AdminPagination(
              page: 1,
              limit: 20,
              totalItems: 1,
              totalPages: 1,
            ),
          );
        },
      );
      final notifier = AdminUsersNotifier(api);

      await notifier.loadUsers();
      await notifier.loadNextPage();

      expect(api.fetchUsersCalls, 1);
      expect(notifier.state.items, hasLength(1));
    });

    test('refreshes from page one with latest filters', () async {
      String observedQuery = '';

      final notifier = AdminUsersNotifier(_FakeAdminApi(
        fetchUsersHandler: ({
          required int page,
          required int limit,
          required String query,
          String? role,
          String? accountStatus,
        }) async {
          observedQuery = query;
          return const AdminUsersPageData(
            items: [],
            pagination: AdminPagination(
              page: 1,
              limit: 20,
              totalItems: 0,
              totalPages: 1,
            ),
          );
        },
      ));

      await notifier.loadUsers(query: 'doctor', role: AdminManagedRoles.doctor);
      await notifier.refreshUsers();

      expect(observedQuery, 'doctor');
      expect(notifier.state.role, AdminManagedRoles.doctor);
      expect(notifier.state.page, 1);
    });

    test('allows clearing role and status filters back to all', () async {
      String? observedRole;
      String? observedStatus;

      final notifier = AdminUsersNotifier(_FakeAdminApi(
        fetchUsersHandler: ({
          required int page,
          required int limit,
          required String query,
          String? role,
          String? accountStatus,
        }) async {
          observedRole = role;
          observedStatus = accountStatus;
          return const AdminUsersPageData(
            items: [],
            pagination: AdminPagination(
              page: 1,
              limit: 20,
              totalItems: 0,
              totalPages: 1,
            ),
          );
        },
      ));

      await notifier.loadUsers(
        role: AdminManagedRoles.doctor,
        accountStatus: AdminAccountStatuses.suspended,
      );
      await notifier.loadUsers(
        page: 1,
        role: null,
        accountStatus: null,
      );

      expect(observedRole, isNull);
      expect(observedStatus, isNull);
      expect(notifier.state.role, isNull);
      expect(notifier.state.accountStatus, isNull);
    });

    test('stores error message when API throws', () async {
      final notifier = AdminUsersNotifier(_FakeAdminApi(
        fetchUsersHandler: ({
          required int page,
          required int limit,
          required String query,
          String? role,
          String? accountStatus,
        }) async {
          throw Exception('Gagal mengambil pengguna');
        },
      ));

      await notifier.loadUsers();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, 'Gagal mengambil pengguna');
      expect(notifier.state.errorCause, isA<Exception>());
      expect(notifier.state.items, isEmpty);
    });
  });

  group('AdminUserDetailNotifier', () {
    test('loads user detail successfully', () async {
      final api = _FakeAdminApi(
        fetchUserDetailHandler: (userId) async => _userDetail(userId),
      );
      final notifier = AdminUserDetailNotifier(api, 'user-1');

      await notifier.fetchInitial();

      expect(api.fetchUserDetailCalls, 1);
      expect(notifier.state.hasUser, isTrue);
      expect(notifier.state.user!.userId, 'user-1');
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
    });

    test('stores error when user detail fails', () async {
      final notifier = AdminUserDetailNotifier(
        _FakeAdminApi(
          fetchUserDetailHandler: (_) async {
            throw Exception('Detail pengguna gagal');
          },
        ),
        'user-1',
      );

      await notifier.fetchInitial();

      expect(notifier.state.hasUser, isFalse);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, 'Detail pengguna gagal');
      expect(notifier.state.errorCause, isA<Exception>());
    });
  });

  group('AdminDoctorDetailNotifier', () {
    test('loads doctor detail successfully', () async {
      final api = _FakeAdminApi(
        fetchDoctorDetailHandler: (doctorId) async => _doctorDetail(doctorId),
      );
      final notifier = AdminDoctorDetailNotifier(api, 'doctor-1');

      await notifier.fetchInitial();

      expect(api.fetchDoctorDetailCalls, 1);
      expect(notifier.state.hasDoctor, isTrue);
      expect(notifier.state.doctor!.doctorId, 'doctor-1');
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
    });

    test('stores error when doctor detail fails', () async {
      final notifier = AdminDoctorDetailNotifier(
        _FakeAdminApi(
          fetchDoctorDetailHandler: (_) async {
            throw Exception('Detail dokter gagal');
          },
        ),
        'doctor-1',
      );

      await notifier.fetchInitial();

      expect(notifier.state.hasDoctor, isFalse);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, 'Detail dokter gagal');
      expect(notifier.state.errorCause, isA<Exception>());
    });
  });

  group('AdminDoctorsReviewNotifier', () {
    test('reloads doctors with selected status', () async {
      String observedStatus = '';

      final notifier = AdminDoctorsReviewNotifier(_FakeAdminApi(
        fetchDoctorsHandler: ({required String status}) async {
          observedStatus = status;
          return [_doctorReviewItem('doctor-1')];
        },
      ));

      await notifier.loadDoctors(status: AdminAccountStatuses.suspended);

      expect(observedStatus, AdminAccountStatuses.suspended);
      expect(notifier.state.status, AdminAccountStatuses.suspended);
      expect(notifier.state.items.single.doctorId, 'doctor-1');
      expect(notifier.state.error, isNull);
    });

    test('stores error when doctors review request fails', () async {
      final notifier = AdminDoctorsReviewNotifier(_FakeAdminApi(
        fetchDoctorsHandler: ({required String status}) async {
          throw Exception('Review dokter gagal');
        },
      ));

      await notifier.loadDoctors();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, 'Review dokter gagal');
      expect(notifier.state.errorCause, isA<Exception>());
      expect(notifier.state.items, isEmpty);
    });
  });

  group('AdminUserStatusActionNotifier', () {
    test('updates status and refreshes dependent admin state', () async {
      final api = _FakeAdminApi(
        updateUserStatusHandler: (userId, request) async {
          return const AdminMutationResult(
            success: true,
            message: 'Status pengguna diperbarui',
          );
        },
      );
      final container = _providerContainerWith(api);
      final notifier = container.read(adminUserStatusActionProvider.notifier);

      final result = await notifier.updateStatus(
        'user-1',
        AdminAccountStatuses.suspended,
      );

      expect(result, isNotNull);
      expect(result!.message, 'Status pengguna diperbarui');
      expect(api.updateUserStatusCalls, 1);
      expect(api.lastUpdatedUserId, 'user-1');
      expect(
        api.lastUpdateUserStatusRequest!.accountStatus,
        AdminAccountStatuses.suspended,
      );
      expect(api.fetchUserDetailCalls, 1);
      expect(api.fetchUsersCalls, 1);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.message, 'Status pengguna diperbarui');
      expect(notifier.state.error, isNull);
    });

    test('stores error when update status fails', () async {
      final api = _FakeAdminApi(
        updateUserStatusHandler: (userId, request) async {
          throw Exception('Status gagal diperbarui');
        },
      );
      final container = _providerContainerWith(api);
      final notifier = container.read(adminUserStatusActionProvider.notifier);

      final result = await notifier.updateStatus(
        'user-1',
        AdminAccountStatuses.suspended,
      );

      expect(result, isNull);
      expect(api.updateUserStatusCalls, 1);
      expect(api.fetchUserDetailCalls, 0);
      expect(api.fetchUsersCalls, 0);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, 'Status gagal diperbarui');
    });
  });

  group('AdminDoctorReviewActionNotifier', () {
    test('approves doctor and refreshes review, detail, and users state',
        () async {
      final api = _FakeAdminApi(
        approveDoctorHandler: (doctorId, request) async {
          return const AdminMutationResult(
            success: true,
            message: 'Dokter disetujui',
          );
        },
      );
      final container = _providerContainerWith(api);
      final notifier = container.read(adminDoctorReviewActionProvider.notifier);

      final result = await notifier.approveDoctor(
        'doctor-1',
        'Dokumen valid',
      );

      expect(result, isNotNull);
      expect(result!.message, 'Dokter disetujui');
      expect(api.approveDoctorCalls, 1);
      expect(api.lastReviewedDoctorId, 'doctor-1');
      expect(api.lastApproveDoctorRequest!.verificationNote, 'Dokumen valid');
      expect(api.fetchDoctorDetailCalls, 1);
      expect(api.fetchDoctorsCalls, 1);
      expect(api.fetchUsersCalls, 1);
      expect(notifier.state.message, 'Dokter disetujui');
      expect(notifier.state.error, isNull);
    });

    test('stores error when doctor review action fails', () async {
      final api = _FakeAdminApi(
        rejectDoctorHandler: (doctorId, request) async {
          throw Exception('Dokumen belum valid');
        },
      );
      final container = _providerContainerWith(api);
      final notifier = container.read(adminDoctorReviewActionProvider.notifier);

      final result = await notifier.rejectDoctor(
        'doctor-1',
        'Dokumen belum valid',
      );

      expect(result, isNull);
      expect(api.rejectDoctorCalls, 1);
      expect(api.fetchDoctorDetailCalls, 0);
      expect(api.fetchDoctorsCalls, 0);
      expect(api.fetchUsersCalls, 0);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, 'Dokumen belum valid');
    });
  });
}

ProviderContainer _providerContainerWith(_FakeAdminApi api) {
  final container = ProviderContainer(
    overrides: [
      adminApiProvider.overrideWithValue(api),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

AdminUserListItem _userListItem(String userId) {
  return AdminUserListItem(
    userId: userId,
    username: userId,
    email: '$userId@pulsewise.local',
    firstName: 'User',
    lastName: userId,
    avatarPhoto: null,
    accountStatus: AdminAccountStatuses.active,
    isActive: true,
    emailVerifiedAt: null,
    createdAt: null,
    updatedAt: null,
    role: AdminManagedRoles.patient,
    roles: const [AdminManagedRoles.patient],
  );
}

AdminUserDetail _userDetail(String userId) {
  return AdminUserDetail(
    userId: userId,
    username: userId,
    email: '$userId@pulsewise.local',
    firstName: 'User',
    lastName: userId,
    avatarPhoto: null,
    accountStatus: AdminAccountStatuses.active,
    isActive: true,
    emailVerifiedAt: null,
    createdAt: null,
    updatedAt: null,
    role: AdminManagedRoles.patient,
    roles: const [AdminManagedRoles.patient],
    doctorProfile: null,
  );
}

AdminDoctorReviewItem _doctorReviewItem(String doctorId) {
  return AdminDoctorReviewItem(
    userId: 'user-$doctorId',
    username: doctorId,
    email: '$doctorId@pulsewise.local',
    firstName: 'Doctor',
    lastName: doctorId,
    avatarPhoto: null,
    accountStatus: AdminAccountStatuses.pendingAdminVerification,
    isActive: false,
    emailVerifiedAt: null,
    createdAt: null,
    updatedAt: null,
    role: AdminManagedRoles.doctor,
    roles: const [AdminManagedRoles.doctor],
    doctorProfile: AdminDoctorProfile(
      doctorId: doctorId,
      specialization: 'Cardiology',
      licenseNo: 'SIP-001',
      hospitalName: 'PulseWise Hospital',
      isVerified: false,
      verifiedAt: null,
      verifiedBy: null,
      verificationNote: null,
      rejectionReason: null,
      createdAt: null,
    ),
  );
}

AdminDoctorDetail _doctorDetail(String doctorId) {
  return AdminDoctorDetail(
    userId: 'user-$doctorId',
    username: doctorId,
    email: '$doctorId@pulsewise.local',
    firstName: 'Doctor',
    lastName: doctorId,
    avatarPhoto: null,
    accountStatus: AdminAccountStatuses.pendingAdminVerification,
    isActive: false,
    emailVerifiedAt: null,
    createdAt: null,
    updatedAt: null,
    role: AdminManagedRoles.doctor,
    roles: const [AdminManagedRoles.doctor],
    doctorProfile: AdminDoctorProfile(
      doctorId: doctorId,
      specialization: 'Cardiology',
      licenseNo: 'SIP-001',
      hospitalName: 'PulseWise Hospital',
      isVerified: false,
      verifiedAt: null,
      verifiedBy: null,
      verificationNote: null,
      rejectionReason: null,
      createdAt: null,
    ),
  );
}

typedef _FetchUsersHandler = Future<AdminUsersPageData> Function({
  required int page,
  required int limit,
  required String query,
  String? role,
  String? accountStatus,
});

typedef _FetchDoctorsHandler = Future<List<AdminDoctorReviewItem>> Function({
  required String status,
});

class _FakeAdminApi extends AdminApi {
  _FakeAdminApi({
    this.fetchUsersHandler,
    this.fetchUserDetailHandler,
    this.fetchDoctorsHandler,
    this.fetchDoctorDetailHandler,
    this.updateUserStatusHandler,
    this.approveDoctorHandler,
    this.rejectDoctorHandler,
  }) : super(Dio());

  final _FetchUsersHandler? fetchUsersHandler;
  final Future<AdminUserDetail> Function(String userId)? fetchUserDetailHandler;
  final _FetchDoctorsHandler? fetchDoctorsHandler;
  final Future<AdminDoctorDetail> Function(String doctorId)?
      fetchDoctorDetailHandler;
  final Future<AdminMutationResult> Function(
    String userId,
    AdminUpdateUserStatusRequest request,
  )? updateUserStatusHandler;
  final Future<AdminMutationResult> Function(
    String doctorId,
    AdminApproveDoctorRequest request,
  )? approveDoctorHandler;
  final Future<AdminMutationResult> Function(
    String doctorId,
    AdminRejectDoctorRequest request,
  )? rejectDoctorHandler;

  int fetchUsersCalls = 0;
  int fetchUserDetailCalls = 0;
  int fetchDoctorsCalls = 0;
  int fetchDoctorDetailCalls = 0;
  int updateUserStatusCalls = 0;
  int approveDoctorCalls = 0;
  int rejectDoctorCalls = 0;

  String? lastUpdatedUserId;
  String? lastReviewedDoctorId;
  AdminUpdateUserStatusRequest? lastUpdateUserStatusRequest;
  AdminApproveDoctorRequest? lastApproveDoctorRequest;
  AdminRejectDoctorRequest? lastRejectDoctorRequest;

  @override
  Future<AdminUsersPageData> fetchUsers({
    int page = 1,
    int limit = 20,
    String query = '',
    String? role,
    String? accountStatus,
  }) async {
    fetchUsersCalls++;
    final handler = fetchUsersHandler;
    if (handler != null) {
      return handler(
        page: page,
        limit: limit,
        query: query,
        role: role,
        accountStatus: accountStatus,
      );
    }
    return AdminUsersPageData(
      items: const [],
      pagination: AdminPagination(
        page: page,
        limit: limit,
        totalItems: 0,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<AdminUserDetail> fetchUserDetail(String userId) async {
    fetchUserDetailCalls++;
    final handler = fetchUserDetailHandler;
    if (handler != null) {
      return handler(userId);
    }
    return _userDetail(userId);
  }

  @override
  Future<List<AdminDoctorReviewItem>> fetchDoctors({
    String status = AdminAccountStatuses.pendingAdminVerification,
  }) async {
    fetchDoctorsCalls++;
    final handler = fetchDoctorsHandler;
    if (handler != null) {
      return handler(status: status);
    }
    return const [];
  }

  @override
  Future<AdminDoctorDetail> fetchDoctorDetail(String doctorId) async {
    fetchDoctorDetailCalls++;
    final handler = fetchDoctorDetailHandler;
    if (handler != null) {
      return handler(doctorId);
    }
    return _doctorDetail(doctorId);
  }

  @override
  Future<AdminMutationResult> updateUserStatus(
    String userId,
    AdminUpdateUserStatusRequest request,
  ) async {
    updateUserStatusCalls++;
    lastUpdatedUserId = userId;
    lastUpdateUserStatusRequest = request;
    final handler = updateUserStatusHandler;
    if (handler != null) {
      return handler(userId, request);
    }
    return const AdminMutationResult(
      success: true,
      message: 'Status pengguna diperbarui',
    );
  }

  @override
  Future<AdminMutationResult> approveDoctor(
    String doctorId,
    AdminApproveDoctorRequest request,
  ) async {
    approveDoctorCalls++;
    lastReviewedDoctorId = doctorId;
    lastApproveDoctorRequest = request;
    final handler = approveDoctorHandler;
    if (handler != null) {
      return handler(doctorId, request);
    }
    return const AdminMutationResult(
      success: true,
      message: 'Dokter disetujui',
    );
  }

  @override
  Future<AdminMutationResult> rejectDoctor(
    String doctorId,
    AdminRejectDoctorRequest request,
  ) async {
    rejectDoctorCalls++;
    lastReviewedDoctorId = doctorId;
    lastRejectDoctorRequest = request;
    final handler = rejectDoctorHandler;
    if (handler != null) {
      return handler(doctorId, request);
    }
    return const AdminMutationResult(
      success: true,
      message: 'Dokter ditolak',
    );
  }
}
