import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_test_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('Termin 12 - login empty validation flow', () {
    tearDown(() async {
      await clearPulseWiseSession();
    });

    testWidgets(
      'user sees required input warning on empty login submit',
      (tester) async {
        await launchPulseWise(tester);

        await submitLogin(tester);
        await waitForVisible(
          tester,
          find.text('Email dan kata sandi wajib diisi'),
          timeout: const Duration(seconds: 10),
        );
        await waitForVisible(
          tester,
          find.byKey(loginSubmitButtonKey),
          timeout: const Duration(seconds: 10),
        );
      },
    );
  });
}
