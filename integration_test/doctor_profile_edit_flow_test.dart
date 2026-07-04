import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_test_config.dart';
import 'helpers/e2e_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Termin 24 - doctor profile edit flow', () {
    tearDown(() async {
      await clearPulseWiseSession();
    });

    testWidgets(
      'active doctor can open edit profile and return without saving',
      (tester) async {
        await launchPulseWise(tester);

        await loginAsDoctor(
          tester,
          email: E2eTestConfig.doctorEmail,
          password: E2eTestConfig.doctorPassword,
        );

        await openDoctorTab(tester, 'Profil');
        await waitForVisible(
          tester,
          find.byKey(doctorProfileTabContentKey),
          timeout: const Duration(seconds: 45),
        );

        await scrollUntilVisible(
          tester,
          find.byKey(doctorProfileEditActionKey),
          scrollable: find.byKey(doctorProfileScrollViewKey),
          timeout: const Duration(seconds: 45),
        );
        await tapByKey(tester, doctorProfileEditActionKey);
        await waitForVisible(
          tester,
          find.byKey(doctorEditProfileContentKey),
          timeout: const Duration(seconds: 45),
        );
        await waitForVisible(tester, find.text('Edit Profil Dokter'));

        await tapCustomAppBarBackUntilVisible(
          tester,
          find.byKey(doctorProfileTabContentKey),
        );
      },
      skip: !E2eTestConfig.canRunDoctorAuthFlow,
    );
  });
}
