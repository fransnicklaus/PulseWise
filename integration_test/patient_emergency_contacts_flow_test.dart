import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_test_config.dart';
import 'helpers/e2e_test_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('Termin 7 - patient emergency contacts flow', () {
    tearDown(() async {
      await clearPulseWiseSession();
    });

    testWidgets(
      'patient can open emergency contacts and return to home',
      (tester) async {
        await launchPulseWise(tester);

        await loginAsPatient(
          tester,
          email: E2eTestConfig.patientEmail,
          password: E2eTestConfig.patientPassword,
        );

        ensurePatientProfileReadyForE2e();

        await waitForAnyVisible(
          tester,
          [
            find.text('Status Kesehatan'),
            find.text('Pengingat Obat'),
            find.byKey(patientHomeEmergencyContactCardKey),
          ],
          timeout: const Duration(seconds: 60),
        );

        await scrollUntilVisible(
          tester,
          find.byKey(patientHomeEmergencyContactCardKey),
          timeout: const Duration(seconds: 45),
        );
        await tapByKey(tester, patientHomeEmergencyContactCardKey);

        await waitForVisible(
          tester,
          find.text('Daftar Kontak Darurat'),
          timeout: const Duration(seconds: 45),
        );
        await waitForAnyVisible(
          tester,
          [
            find.text('Tambah Kontak'),
            find.text('Kontak darurat belum bisa dimuat'),
            find.text('Gagal memuat kontak'),
          ],
          timeout: const Duration(seconds: 45),
        );

        await tapCustomAppBarBack(tester);
        await waitForAnyVisible(
          tester,
          [
            find.text('Status Kesehatan'),
            find.text('Pengingat Obat'),
            find.byKey(patientHomeEmergencyContactCardKey),
          ],
          timeout: const Duration(seconds: 45),
        );
      },
      skip: !E2eTestConfig.canRunPatientAuthFlow,
    );
  });
}
