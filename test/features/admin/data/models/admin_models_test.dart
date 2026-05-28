import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/features/admin/data/models/admin_models.dart';

void main() {
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
  });
}
