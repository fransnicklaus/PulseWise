import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_test_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('Termin 11 - forgot password navigation flow', () {
    tearDown(() async {
      await clearPulseWiseSession();
    });

    testWidgets(
      'user can open forgot password page',
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
