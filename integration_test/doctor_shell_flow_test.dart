import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_test_config.dart';
import 'helpers/e2e_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Termin 20 - doctor shell flow', () {
    tearDown(() async {
      await clearPulseWiseSession();
    });

    testWidgets(
      'active doctor can open main shell tabs without scanning QR',
      (tester) async {
        await launchPulseWise(tester);

        await loginAsDoctor(
          tester,
          email: E2eTestConfig.doctorEmail,
          password: E2eTestConfig.doctorPassword,
        );

        await waitForVisible(
          tester,
          find.byKey(doctorPatientsTabContentKey),
          timeout: const Duration(seconds: 45),
        );
        await waitForVisible(tester, find.text('QR'));

        await openDoctorTab(tester, 'Edukasi');
        await waitForAnyVisible(
          tester,
          [
            find.byKey(patientEducationSearchFieldKey),
            find.text('Artikel gagal dimuat'),
            find.text('Tidak ada artikel'),
          ],
          timeout: const Duration(seconds: 45),
        );

        await openDoctorTab(tester, 'Profil');
        await waitForVisible(
          tester,
          find.byKey(doctorProfileTabContentKey),
          timeout: const Duration(seconds: 45),
        );

        await openDoctorTab(tester, 'Pasien');
        await waitForVisible(
          tester,
          find.byKey(doctorPatientsTabContentKey),
          timeout: const Duration(seconds: 45),
        );
      },
      skip: !E2eTestConfig.canRunDoctorAuthFlow,
    );
  });
}
