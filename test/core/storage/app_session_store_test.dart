import 'package:flutter_test/flutter_test.dart';
import 'package:pulsewise/core/constants/app_roles.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppSession', () {
    test('has valid session only when token and user id are present', () {
      expect(
        const AppSession(token: 'token', userId: 'user-1').hasValidSession,
        isTrue,
      );
      expect(
        const AppSession(token: 'token', userId: '  ').hasValidSession,
        isFalse,
      );
      expect(
        const AppSession(token: null, userId: 'user-1').hasValidSession,
        isFalse,
      );
    });
  });

  group('AppSessionStore.readSession', () {
    test('reads and normalizes stored session values', () async {
      SharedPreferences.setMockInitialValues({
        AppSessionStore.tokenPrefsKey: ' token-1 ',
        AppSessionStore.userIdPrefsKey: ' user-1 ',
        AppSessionStore.rolePrefsKey: ' Doctor ',
        AppSessionStore.nextStepPrefsKey: ' verify_otp ',
        AppSessionStore.accountStatusPrefsKey: ' Active ',
      });

      final session = await AppSessionStore.readSession(
        allowEnvFallback: false,
      );

      expect(session.token, 'token-1');
      expect(session.userId, 'user-1');
      expect(session.role, AppRoles.doctor);
      expect(session.nextStep, 'verify_otp');
      expect(session.accountStatus, 'Active');
      expect(session.hasValidSession, isTrue);
    });

    test('returns patient role when stored role is missing', () async {
      final session = await AppSessionStore.readSession(
        allowEnvFallback: false,
      );

      expect(session.role, AppRoles.patient);
      expect(session.hasValidSession, isFalse);
    });
  });

  group('AppSessionStore.saveSession', () {
    test('saves session and removes blank optional fields', () async {
      await AppSessionStore.saveSession(
        token: ' token-2 ',
        userId: ' user-2 ',
        role: ' ADMIN ',
        nextStep: ' ',
        accountStatus: null,
      );

      final prefs = await SharedPreferences.getInstance();
      final session = await AppSessionStore.readSession(
        allowEnvFallback: false,
      );

      expect(prefs.getString(AppSessionStore.tokenPrefsKey), ' token-2 ');
      expect(session.token, 'token-2');
      expect(session.userId, 'user-2');
      expect(session.role, AppRoles.admin);
      expect(session.nextStep, isNull);
      expect(session.accountStatus, isNull);
    });

    test('clears user scoped values when user id is blank', () async {
      SharedPreferences.setMockInitialValues({
        AppSessionStore.tokenPrefsKey: 'old-token',
        AppSessionStore.userIdPrefsKey: 'old-user',
        AppSessionStore.rolePrefsKey: AppRoles.doctor,
        AppSessionStore.nextStepPrefsKey: 'VERIFY_OTP',
        AppSessionStore.accountStatusPrefsKey: 'active',
      });

      await AppSessionStore.saveSession(
        token: 'new-token',
        userId: ' ',
        role: AppRoles.admin,
        nextStep: 'HOME',
        accountStatus: 'active',
      );

      final session = await AppSessionStore.readSession(
        allowEnvFallback: false,
      );

      expect(session.token, 'new-token');
      expect(session.userId, isNull);
      expect(session.role, AppRoles.patient);
      expect(session.nextStep, isNull);
      expect(session.accountStatus, isNull);
    });
  });

  group('AppSessionStore required values', () {
    test('returns required token and user id when available', () async {
      SharedPreferences.setMockInitialValues({
        AppSessionStore.tokenPrefsKey: ' token-3 ',
        AppSessionStore.userIdPrefsKey: ' user-3 ',
      });

      expect(
        await AppSessionStore.requireToken(allowEnvFallback: false),
        'token-3',
      );
      expect(
        await AppSessionStore.requireUserId(allowEnvFallback: false),
        'user-3',
      );
    });

    test('throws custom message when required values are missing', () async {
      expect(
        () => AppSessionStore.requireToken(
          allowEnvFallback: false,
          missingMessage: 'missing token',
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('missing token'),
          ),
        ),
      );
      expect(
        () => AppSessionStore.requireUserId(
          allowEnvFallback: false,
          missingMessage: 'missing user id',
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('missing user id'),
          ),
        ),
      );
    });
  });

  group('AppSessionStore.clearSession', () {
    test('removes all stored session values', () async {
      SharedPreferences.setMockInitialValues({
        AppSessionStore.tokenPrefsKey: 'token',
        AppSessionStore.userIdPrefsKey: 'user',
        AppSessionStore.rolePrefsKey: AppRoles.doctor,
        AppSessionStore.nextStepPrefsKey: 'HOME',
        AppSessionStore.accountStatusPrefsKey: 'active',
      });

      await AppSessionStore.clearSession();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppSessionStore.tokenPrefsKey), isNull);
      expect(prefs.getString(AppSessionStore.userIdPrefsKey), isNull);
      expect(prefs.getString(AppSessionStore.rolePrefsKey), isNull);
      expect(prefs.getString(AppSessionStore.nextStepPrefsKey), isNull);
      expect(prefs.getString(AppSessionStore.accountStatusPrefsKey), isNull);
    });
  });
}
