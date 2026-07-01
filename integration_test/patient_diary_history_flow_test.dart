import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_test_config.dart';
import 'helpers/e2e_test_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('Termin 5 - patient diary history flow', () {
    tearDown(() async {
      await clearPulseWiseSession();
    });

    testWidgets(
      'patient can open diary history and return to diary tab',
      (tester) async {
        await launchPulseWise(tester);

        await loginAsPatient(
          tester,
          email: E2eTestConfig.patientEmail,
          password: E2eTestConfig.patientPassword,
        );

        ensurePatientProfileReadyForE2e();

        await openPatientTab(tester, 'Diari');
        await waitForVisible(
          tester,
          find.text('Diari Kesehatan'),
          timeout: const Duration(seconds: 60),
        );

        await tapByKey(tester, patientDiaryHistoryButtonKey);
        await waitForVisible(
          tester,
          find.text('Riwayat Diari'),
          timeout: const Duration(seconds: 45),
        );
        await waitForVisible(
          tester,
          find.text('Semua catatan kesehatan Anda'),
          timeout: const Duration(seconds: 20),
        );

        await tapCustomAppBarBack(tester);
        await waitForVisible(
          tester,
          find.text('Diari Kesehatan'),
          timeout: const Duration(seconds: 30),
        );
      },
      skip: !E2eTestConfig.canRunPatientAuthFlow,
    );
  });
}
