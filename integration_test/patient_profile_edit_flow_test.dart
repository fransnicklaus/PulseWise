import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_test_config.dart';
import 'helpers/e2e_test_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('Termin 6 - patient profile edit flow', () {
    tearDown(() async {
      await clearPulseWiseSession();
    });

    testWidgets(
      'patient can open edit profile and return to profile tab',
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
          find.byKey(patientProfileEditActionKey),
          timeout: const Duration(seconds: 30),
        );
        await tapByKey(tester, patientProfileEditActionKey);

        final addressFieldFinder = find.text('Alamat Tempat Tinggal');
        final editErrorFinder = find.text('Profil edit belum bisa dimuat');
        final genericErrorFinder = find.textContaining('Gagal memuat profil');
        final openedState = await waitForAnyVisible(
          tester,
          [
            addressFieldFinder,
            editErrorFinder,
            genericErrorFinder,
          ],
          timeout: const Duration(seconds: 60),
        );
        if (!identical(openedState, addressFieldFinder)) {
          throw TestFailure(
            'Edit profile page opened, but the profile form did not load.',
          );
        }
        await waitForVisible(
          tester,
          find.text('Tinggi Badan (cm)'),
          timeout: const Duration(seconds: 20),
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
