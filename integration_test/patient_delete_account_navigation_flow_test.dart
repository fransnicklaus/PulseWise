import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_test_config.dart';
import 'helpers/e2e_test_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('Termin 17 - patient delete account navigation flow', () {
    tearDown(() async {
      await clearPulseWiseSession();
    });

    testWidgets(
      'patient can open delete account page and return without deleting',
      (tester) async {
        await launchPulseWise(tester);

        await loginAsPatient(
          tester,
          email: E2eTestConfig.patientEmail,
          password: E2eTestConfig.patientPassword,
        );

        ensurePatientProfileReadyForE2e();

        await openPatientTab(tester, 'Profil');
        await waitForVisible(
          tester,
          find.text('Pengaturan Akun'),
          timeout: const Duration(seconds: 60),
        );

        await scrollUntilVisible(
          tester,
          find.byKey(patientProfileDeleteAccountActionKey),
          timeout: const Duration(seconds: 45),
        );
        await tapByKey(tester, patientProfileDeleteAccountActionKey);

        await waitForVisible(
          tester,
          find.text('Ketik konfirmasi'),
          timeout: const Duration(seconds: 45),
        );
        await waitForVisible(
          tester,
          find.text('Kirim OTP Penghapusan'),
          timeout: const Duration(seconds: 10),
        );

        await tapCustomAppBarBack(tester);
        await waitForVisible(
          tester,
          find.text('Pengaturan Akun'),
          timeout: const Duration(seconds: 30),
        );
      },
      skip: !E2eTestConfig.canRunPatientAuthFlow,
    );
  });
}
