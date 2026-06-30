import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_test_config.dart';
import 'helpers/e2e_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Termin 1 - auth flow', () {
    tearDown(() async {
      await clearPulseWiseSession();
    });

    testWidgets('app opens on login page when no session', (tester) async {
      await launchPulseWise(tester);

      expect(find.text('Masuk'), findsWidgets);
      expect(find.byKey(loginEmailFieldKey), findsOneWidget);
      expect(find.byKey(loginPasswordFieldKey), findsOneWidget);
      expect(find.byKey(loginSubmitButtonKey), findsOneWidget);
    });

    testWidgets('empty login shows required input warning', (tester) async {
      await launchPulseWise(tester);

      await submitLogin(tester);

      await waitForVisible(
        tester,
        find.text('Email dan kata sandi wajib diisi'),
      );
      expect(find.byKey(loginSubmitButtonKey), findsOneWidget);
    });

    testWidgets(
      'invalid credential login stays on login page and shows error',
      (tester) async {
        await launchPulseWise(tester);
        await enterLoginCredentials(
          tester,
          email: E2eTestConfig.invalidEmail,
          password: E2eTestConfig.invalidPassword,
        );

        await submitLogin(tester);

        await waitForAnyVisible(
          tester,
          [
            find.text('Error'),
            find.textContaining(
              RegExp('gagal|salah|invalid|tidak', caseSensitive: false),
            ),
          ],
          timeout: const Duration(seconds: 35),
        );
        expect(find.byKey(loginSubmitButtonKey), findsOneWidget);
      },
      skip: !E2eTestConfig.canTouchBackend,
    );

    testWidgets(
      'patient can login with valid credential and reaches home',
      (tester) async {
        await launchPulseWise(tester);

        await loginAsPatient(
          tester,
          email: E2eTestConfig.patientEmail,
          password: E2eTestConfig.patientPassword,
        );

        expect(find.text('Beranda'), findsWidgets);
        expect(find.text('Edukasi'), findsWidgets);
        expect(find.text('Diari'), findsWidgets);
        expect(find.text('Pengingat'), findsWidgets);
        expect(find.text('Profil'), findsWidgets);
      },
      skip: !E2eTestConfig.canRunPatientAuthFlow,
    );

    testWidgets(
      'patient can logout back to login page',
      (tester) async {
        await launchPulseWise(tester);

        await loginAsPatient(
          tester,
          email: E2eTestConfig.patientEmail,
          password: E2eTestConfig.patientPassword,
        );

        await logoutFromPatientProfile(tester);

        expect(find.text('Masuk'), findsWidgets);
        expect(find.byKey(loginSubmitButtonKey), findsOneWidget);
      },
      skip: !E2eTestConfig.canRunPatientAuthFlow,
    );
  });
}
