import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_test_config.dart';
import 'helpers/e2e_test_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('Termin 9 - patient dashboard overview flow', () {
    tearDown(() async {
      await clearPulseWiseSession();
    });

    testWidgets(
      'patient can open health dashboard and return to home',
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
            find.byKey(patientHomeHealthDetailButtonKey),
          ],
          timeout: const Duration(seconds: 60),
        );

        await scrollUntilVisible(
          tester,
          find.byKey(patientHomeHealthDetailButtonKey),
          timeout: const Duration(seconds: 45),
        );
        await tapByKey(tester, patientHomeHealthDetailButtonKey);

        await waitForVisible(
          tester,
          find.byKey(patientDashboardContentKey),
          timeout: const Duration(seconds: 60),
        );
        await waitForAnyVisible(
          tester,
          [
            find.text('Prediksi'),
            find.text('Dashboard Metrik'),
            find.text('Dashboard metrik belum bisa dimuat'),
            find.text('Prediksi belum bisa dimuat'),
          ],
          timeout: const Duration(seconds: 60),
        );

        await tapCustomAppBarBack(tester);
        await waitForAnyVisible(
          tester,
          [
            find.text('Status Kesehatan'),
            find.text('Pengingat Obat'),
            find.byKey(patientHomeHealthDetailButtonKey),
          ],
          timeout: const Duration(seconds: 45),
        );
      },
      skip: !E2eTestConfig.canRunPatientAuthFlow,
    );
  });
}
