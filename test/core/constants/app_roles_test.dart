import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/constants/app_roles.dart';

void main() {
  group('normalizeAppRole', () {
    test('normalizes supported roles case-insensitively', () {
      expect(normalizeAppRole(' ADMIN '), AppRoles.admin);
      expect(normalizeAppRole('Doctor'), AppRoles.doctor);
      expect(normalizeAppRole('patient'), AppRoles.patient);
    });

    test('falls back to patient when role is empty or unknown', () {
      expect(normalizeAppRole(null), AppRoles.patient);
      expect(normalizeAppRole(''), AppRoles.patient);
      expect(normalizeAppRole('caregiver'), AppRoles.patient);
    });
  });

  group('role predicates', () {
    test('identify patient, doctor, and admin roles', () {
      expect(isPatientRole('patient'), isTrue);
      expect(isDoctorRole('doctor'), isTrue);
      expect(isAdminRole('admin'), isTrue);
    });

    test('treats unknown role as patient only', () {
      expect(isPatientRole('unknown'), isTrue);
      expect(isDoctorRole('unknown'), isFalse);
      expect(isAdminRole('unknown'), isFalse);
    });
  });

  group('isDoctorPendingAdminVerification', () {
    test('returns true for doctor waiting admin verification by next step', () {
      expect(
        isDoctorPendingAdminVerification(
          role: AppRoles.doctor,
          nextStep: ' wait_admin_verification ',
        ),
        isTrue,
      );
    });

    test('returns true for doctor pending admin verification by status', () {
      expect(
        isDoctorPendingAdminVerification(
          role: AppRoles.doctor,
          accountStatus: ' PENDING_ADMIN_VERIFICATION ',
        ),
        isTrue,
      );
    });

    test('returns false for non-doctor pending status', () {
      expect(
        isDoctorPendingAdminVerification(
          role: AppRoles.patient,
          accountStatus: AppAccountStatuses.pendingAdminVerification,
        ),
        isFalse,
      );
    });
  });

  group('routeForRoleSession', () {
    test('routes pending doctor to admin verification page', () {
      expect(
        routeForRoleSession(
          role: AppRoles.doctor,
          accountStatus: AppAccountStatuses.pendingAdminVerification,
        ),
        doctorPendingVerificationRoute,
      );
    });

    test('routes active doctor to doctor home', () {
      expect(routeForRoleSession(role: AppRoles.doctor), '/doctor/home');
    });

    test('routes patient and admin to home', () {
      expect(routeForRoleSession(role: AppRoles.patient), '/home');
      expect(routeForRoleSession(role: AppRoles.admin), '/home');
    });
  });
}
