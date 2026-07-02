import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_test_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('Termin 10 - forgot password validation flow', () {
    tearDown(() async {
      await clearPulseWiseSession();
    });

    testWidgets(
      'user can open forgot password and see empty email validation',
      (tester) async {
        await launchPulseWise(tester);

        await tapByKey(tester, loginForgotPasswordButtonKey);
        await waitForVisible(
          tester,
          find.text('Langkah 1: Masukkan Email'),
          timeout: const Duration(seconds: 30),
        );
        await waitForVisible(
          tester,
          find.byKey(forgotPasswordEmailFieldKey),
          timeout: const Duration(seconds: 20),
        );

        await tapByKey(tester, forgotPasswordSubmitButtonKey);
        await waitForVisible(
          tester,
          find.text('Email wajib diisi'),
          timeout: const Duration(seconds: 10),
        );

        await tapByKey(tester, forgotPasswordCancelButtonKey);
        await waitForVisible(
          tester,
          find.byKey(loginSubmitButtonKey),
          timeout: const Duration(seconds: 30),
        );
      },
    );
  });
}
