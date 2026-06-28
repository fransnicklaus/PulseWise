import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/admin/data/models/admin_models.dart';

void main() {
  group('AdminOverview', () {
    test('parses numeric counters from json', () {
      final overview = AdminOverview.fromJson({
        'totalUsers': 10.0,
        'totalDoctors': 2,
        'totalPatients': 7,
        'totalAdmins': 1,
        'pendingDoctors': 3,
        'suspendedUsers': 4,
      });

      expect(overview.totalUsers, 10);
      expect(overview.totalDoctors, 2);
      expect(overview.totalPatients, 7);
      expect(overview.totalAdmins, 1);
      expect(overview.pendingDoctors, 3);
      expect(overview.suspendedUsers, 4);
    });

    test('defaults missing counters to zero', () {
      final overview = AdminOverview.fromJson({});

      expect(overview.totalUsers, 0);
      expect(overview.pendingDoctors, 0);
      expect(overview.suspendedUsers, 0);
    });
  });

  group('AdminPagination', () {
    test('uses pagination defaults when fields are absent', () {
      final pagination = AdminPagination.fromJson({});

      expect(pagination.page, 1);
      expect(pagination.limit, 20);
      expect(pagination.totalItems, 0);
      expect(pagination.totalPages, 1);
    });
  });

  group('AdminDoctorProfile', () {
    test('parses snake case aliases and trims nullable strings', () {
      final profile = AdminDoctorProfile.fromJson({
        'doctor_id': ' doctor-2 ',
        'specialization': ' Cardiology ',
        'license_no': ' SIP-001 ',
        'hospital_name': ' PulseWise Hospital ',
        'isVerified': true,
        'verifiedAt': '2026-05-28T10:00:00.000Z',
        'verifiedBy': ' admin-1 ',
        'verificationNote': ' Valid ',
        'rejectionReason': ' ',
        'createdAt': 'not-a-date',
      });

      expect(profile.doctorId, 'doctor-2');
      expect(profile.specialization, 'Cardiology');
      expect(profile.licenseNo, 'SIP-001');
      expect(profile.hospitalName, 'PulseWise Hospital');
      expect(profile.isVerified, isTrue);
      expect(profile.verifiedAt, DateTime.parse('2026-05-28T10:00:00.000Z'));
      expect(profile.verifiedBy, 'admin-1');
      expect(profile.verificationNote, 'Valid');
      expect(profile.rejectionReason, isNull);
      expect(profile.createdAt, isNull);
    });
  });

  group('AdminUserListItem', () {
    test('parses snake case aliases, role fallback, and active status', () {
      final item = AdminUserListItem.fromJson({
        'user_id': ' user-2 ',
        'username': ' patienttwo ',
        'email': ' patient2@pulsewise.local ',
        'first_name': ' Patient ',
        'last_name': ' Two ',
        'avatar_photo': ' ',
        'account_status': AdminAccountStatuses.active,
        'emailVerifiedAt': 'invalid-date',
        'createdAt': '2026-05-27T10:00:00.000Z',
        'updatedAt': null,
        'role': AdminManagedRoles.patient,
        'roles': [],
      });

      expect(item.userId, 'user-2');
      expect(item.username, 'patienttwo');
      expect(item.email, 'patient2@pulsewise.local');
      expect(item.fullName, 'Patient Two');
      expect(item.avatarPhoto, isNull);
      expect(item.isActive, isTrue);
      expect(item.emailVerifiedAt, isNull);
      expect(item.createdAt, DateTime.parse('2026-05-27T10:00:00.000Z'));
      expect(item.updatedAt, isNull);
      expect(item.roles, [AdminManagedRoles.patient]);
      expect(item.isPatientUser, isTrue);
    });

    test('falls back full name to username, email, then default label', () {
      expect(
        const AdminUserListItem(
          userId: 'user-1',
          username: 'patientone',
          email: 'patient@pulsewise.local',
          firstName: '',
          lastName: '',
          avatarPhoto: null,
          accountStatus: AdminAccountStatuses.active,
          isActive: true,
          emailVerifiedAt: null,
          createdAt: null,
          updatedAt: null,
          role: AdminManagedRoles.patient,
          roles: [AdminManagedRoles.patient],
        ).fullName,
        'patientone',
      );
      expect(
        const AdminUserListItem(
          userId: 'user-2',
          username: '',
          email: 'patient2@pulsewise.local',
          firstName: '',
          lastName: '',
          avatarPhoto: null,
          accountStatus: AdminAccountStatuses.active,
          isActive: true,
          emailVerifiedAt: null,
          createdAt: null,
          updatedAt: null,
          role: AdminManagedRoles.patient,
          roles: [AdminManagedRoles.patient],
        ).fullName,
        'patient2@pulsewise.local',
      );
      expect(
        const AdminUserListItem(
          userId: 'user-3',
          username: '',
          email: '',
          firstName: '',
          lastName: '',
          avatarPhoto: null,
          accountStatus: AdminAccountStatuses.active,
          isActive: true,
          emailVerifiedAt: null,
          createdAt: null,
          updatedAt: null,
          role: AdminManagedRoles.patient,
          roles: [AdminManagedRoles.patient],
        ).fullName,
        'Pengguna',
      );
    });
  });

  group('AdminUsersPageData', () {
    test('parses paginated users response data', () {
      final data = AdminUsersPageData.fromJson({
        'items': [
          {
            'userId': 'user-1',
            'username': 'adminone',
            'email': 'admin@pulsewise.local',
            'firstName': 'Admin',
            'lastName': 'One',
            'avatarPhoto': null,
            'accountStatus': 'active',
            'isActive': true,
            'emailVerifiedAt': '2026-05-28T10:00:00.000Z',
            'createdAt': '2026-05-27T10:00:00.000Z',
            'updatedAt': '2026-05-28T10:00:00.000Z',
            'role': 'admin',
            'roles': ['admin'],
          },
        ],
        'pagination': {
          'page': 2,
          'limit': 20,
          'totalItems': 45,
          'totalPages': 3,
        },
      });

      expect(data.items, hasLength(1));
      expect(data.items.first.userId, 'user-1');
      expect(data.items.first.avatarPhoto, isNull);
      expect(data.items.first.roles, ['admin']);
      expect(data.pagination.page, 2);
      expect(data.pagination.totalPages, 3);
    });

    test('ignores non-map items and defaults missing pagination', () {
      final data = AdminUsersPageData.fromJson({
        'items': [
          'invalid',
          {
            'userId': 'user-1',
            'username': 'patientone',
            'email': 'patient@pulsewise.local',
            'accountStatus': AdminAccountStatuses.active,
            'role': AdminManagedRoles.patient,
          },
        ],
      });

      expect(data.items, hasLength(1));
      expect(data.items.single.userId, 'user-1');
      expect(data.pagination.page, 1);
      expect(data.pagination.limit, 20);
    });
  });

  group('AdminUserDetail', () {
    test('parses optional doctor profile', () {
      final detail = AdminUserDetail.fromJson({
        'userId': 'user-doctor',
        'username': 'drdev',
        'email': 'doctor@pulsewise.local',
        'firstName': 'Dev',
        'lastName': 'Doctor',
        'avatarPhoto': null,
        'accountStatus': 'pending_admin_verification',
        'isActive': false,
        'emailVerifiedAt': '2026-05-28T10:00:00.000Z',
        'createdAt': '2026-05-27T10:00:00.000Z',
        'updatedAt': '2026-05-28T10:00:00.000Z',
        'role': 'doctor',
        'roles': ['doctor'],
        'doctorProfile': {
          'doctorId': 'doctor-1',
          'specialization': 'Cardiology',
          'licenseNo': 'ABC123',
          'hospitalName': 'PulseWise Hospital',
          'isVerified': false,
          'verifiedAt': null,
          'verifiedBy': null,
          'verificationNote': null,
          'rejectionReason': null,
          'createdAt': '2026-05-26T10:00:00.000Z',
        },
      });

      expect(detail.isDoctorUser, isTrue);
      expect(detail.doctorProfile, isNotNull);
      expect(detail.doctorProfile!.doctorId, 'doctor-1');
      expect(detail.doctorProfile!.specialization, 'Cardiology');
    });

    test('parses user detail without doctor profile', () {
      final detail = AdminUserDetail.fromJson({
        'userId': 'user-patient',
        'username': 'patientone',
        'email': 'patient@pulsewise.local',
        'accountStatus': AdminAccountStatuses.active,
        'role': AdminManagedRoles.patient,
      });

      expect(detail.isPatientUser, isTrue);
      expect(detail.isDoctorUser, isFalse);
      expect(detail.doctorProfile, isNull);
    });
  });

  group('AdminDoctorReviewItem', () {
    test('parses doctor review item from array response item', () {
      final item = AdminDoctorReviewItem.fromJson({
        'userId': 'user-doctor',
        'email': 'doctor@example.com',
        'role': 'doctor',
        'roles': ['doctor'],
        'accountStatus': 'pending_admin_verification',
        'doctorProfile': {
          'doctorId': 'doctor-1',
          'specialization': null,
          'licenseNo': null,
          'hospitalName': null,
          'isVerified': false,
          'verifiedAt': null,
          'verifiedBy': null,
          'verificationNote': null,
          'rejectionReason': null,
          'createdAt': '2026-05-26T10:00:00.000Z',
        },
      });

      expect(item.userId, 'user-doctor');
      expect(item.email, 'doctor@example.com');
      expect(item.accountStatus, AdminAccountStatuses.pendingAdminVerification);
      expect(item.doctorId, 'doctor-1');
      expect(item.doctorProfile.isVerified, isFalse);
    });

    test('uses empty doctor profile when profile payload is absent', () {
      final item = AdminDoctorReviewItem.fromJson({
        'userId': 'user-doctor',
        'email': 'doctor@example.com',
        'role': 'doctor',
        'accountStatus': AdminAccountStatuses.pendingAdminVerification,
      });

      expect(item.isDoctorUser, isTrue);
      expect(item.doctorId, '');
      expect(item.doctorProfile.isVerified, isFalse);
    });
  });

  group('AdminDoctorDetail', () {
    test('parses doctor detail as review item with doctor profile', () {
      final detail = AdminDoctorDetail.fromJson({
        'userId': 'user-doctor',
        'email': 'doctor@example.com',
        'role': 'doctor',
        'roles': ['doctor'],
        'accountStatus': AdminAccountStatuses.active,
        'doctorProfile': {
          'doctorId': 'doctor-9',
          'isVerified': true,
          'verifiedAt': '2026-05-28T10:00:00.000Z',
        },
      });

      expect(detail.doctorId, 'doctor-9');
      expect(detail.isDoctorUser, isTrue);
      expect(detail.doctorProfile.isVerified, isTrue);
    });
  });

  group('AdminMutationResult and requests', () {
    test('parses mutation result and serializes request bodies', () {
      final result = AdminMutationResult.fromJson({
        'success': true,
        'message': 'Berhasil',
      });

      expect(result.success, isTrue);
      expect(result.message, 'Berhasil');
      expect(
        const AdminUpdateUserStatusRequest(
          accountStatus: AdminAccountStatuses.suspended,
        ).toJson(),
        {'accountStatus': AdminAccountStatuses.suspended},
      );
      expect(
        const AdminApproveDoctorRequest(verificationNote: 'Valid').toJson(),
        {'verificationNote': 'Valid'},
      );
      expect(
        const AdminRejectDoctorRequest(rejectionReason: 'Invalid').toJson(),
        {'rejectionReason': 'Invalid'},
      );
      expect(
        const AdminSuspendDoctorRequest(verificationNote: 'Review ulang')
            .toJson(),
        {'verificationNote': 'Review ulang'},
      );
    });

    test('defaults unsuccessful mutation result message to empty string', () {
      final result = AdminMutationResult.fromJson({});

      expect(result.success, isFalse);
      expect(result.message, '');
    });
  });
}
