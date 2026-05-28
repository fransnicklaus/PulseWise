import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/admin/data/datasources/admin_api.dart';
import 'package:pulsewise/features/admin/data/models/admin_models.dart';
import 'package:pulsewise/features/admin/presentation/providers/admin_providers.dart';

void main() {
  group('AdminUsersNotifier', () {
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
            items: [
              AdminUserListItem(
                userId: 'user-$page',
                username: 'user$page',
                email: 'user$page@pulsewise.local',
                firstName: 'User',
                lastName: '$page',
                avatarPhoto: null,
                accountStatus: AdminAccountStatuses.active,
                isActive: true,
                emailVerifiedAt: null,
                createdAt: null,
                updatedAt: null,
                role: AdminManagedRoles.patient,
                roles: const [AdminManagedRoles.patient],
              ),
            ],
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
  });

  group('AdminDoctorsReviewNotifier', () {
    test('reloads doctors with selected status', () async {
      String observedStatus = '';

      final notifier = AdminDoctorsReviewNotifier(_FakeAdminApi(
        fetchDoctorsHandler: ({required String status}) async {
          observedStatus = status;
          return const [];
        },
      ));

      await notifier.loadDoctors(status: AdminAccountStatuses.suspended);

      expect(observedStatus, AdminAccountStatuses.suspended);
      expect(notifier.state.status, AdminAccountStatuses.suspended);
    });
  });
}

class _FakeAdminApi extends AdminApi {
  _FakeAdminApi({
    this.fetchUsersHandler,
    this.fetchDoctorsHandler,
  }) : super(Dio());

  final Future<AdminUsersPageData> Function({
    required int page,
    required int limit,
    required String query,
    String? role,
    String? accountStatus,
  })? fetchUsersHandler;

  final Future<List<AdminDoctorReviewItem>> Function({
    required String status,
  })? fetchDoctorsHandler;

  @override
  Future<AdminUsersPageData> fetchUsers({
    int page = 1,
    int limit = 20,
    String query = '',
    String? role,
    String? accountStatus,
  }) async {
    return fetchUsersHandler!(
      page: page,
      limit: limit,
      query: query,
      role: role,
      accountStatus: accountStatus,
    );
  }

  @override
  Future<List<AdminDoctorReviewItem>> fetchDoctors({
    String status = AdminAccountStatuses.pendingAdminVerification,
  }) async {
    return fetchDoctorsHandler!(status: status);
  }
}
