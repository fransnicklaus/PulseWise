import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_test_config.dart';
import 'helpers/e2e_test_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('Termin 18 - patient diary QR share flow', () {
    tearDown(() async {
      await clearPulseWiseSession();
    });

    testWidgets(
      'patient can open QR share page and return without scanning',
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

        await tapByKey(tester, patientDiaryQrShareButtonKey);
        await waitForAnyVisible(
          tester,
          [
            find.byKey(patientDiaryQrShareContentKey),
            find.text('QR Share Pasien'),
            find.text('Tunjukkan QR ini ke dokter untuk menghubungkan akun.'),
          ],
          timeout: const Duration(seconds: 45),
        );

        await waitForAnyVisible(
          tester,
          [
            find.text('Kode Share'),
            find.text('Buat QR Baru'),
            find.text('Buat Ulang QR'),
            find.textContaining('QR share tidak tersedia'),
            find.textContaining('Gagal membuat QR share pasien'),
          ],
          timeout: const Duration(seconds: 60),
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
