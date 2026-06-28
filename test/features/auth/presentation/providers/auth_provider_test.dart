import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/constants/app_roles.dart';
import 'package:pulsewise/features/auth/presentation/providers/auth_provider.dart';

void main() {
  group('GoogleAuthFlowResult', () {
    test('error creates failed unknown result with patient role fallback', () {
      final result = GoogleAuthFlowResult.error('Google gagal');

      expect(result.success, isFalse);
      expect(result.message, 'Google gagal');
      expect(result.nextStep, GoogleAuthNextStep.unknown);
      expect(result.role, AppRoles.patient);
      expect(result.restrictedAccess, isFalse);
      expect(result.token, isNull);
    });
  });

  group('AuthState', () {
    test('copyWith updates session fields and clears transient fields', () {
      final original = AuthState(
        isLoading: true,
        error: 'error lama',
        token: 'old-token',
        userId: 'old-user',
        role: AppRoles.patient,
        nextStep: 'verify_email',
        accountStatus: 'pending',
        restrictedAccess: true,
      );

      final updated = original.copyWith(
        isLoading: false,
        token: 'new-token',
        userId: 'new-user',
        role: AppRoles.doctor,
        restrictedAccess: false,
        isAuthenticated: true,
      );

      expect(updated.isLoading, isFalse);
      expect(updated.error, isNull);
      expect(updated.token, 'new-token');
      expect(updated.userId, 'new-user');
      expect(updated.role, AppRoles.doctor);
      expect(updated.nextStep, isNull);
      expect(updated.accountStatus, isNull);
      expect(updated.restrictedAccess, isFalse);
      expect(updated.isAuthenticated, isTrue);
    });

    test('copyWith preserves session values when omitted', () {
      final original = AuthState(
        token: 'token',
        userId: 'user-1',
        role: AppRoles.admin,
        isAuthenticated: true,
      );

      final updated = original.copyWith(error: 'Sesi gagal');

      expect(updated.token, 'token');
      expect(updated.userId, 'user-1');
      expect(updated.role, AppRoles.admin);
      expect(updated.error, 'Sesi gagal');
      expect(updated.isAuthenticated, isTrue);
    });
  });
}
