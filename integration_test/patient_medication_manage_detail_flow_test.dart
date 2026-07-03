import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_test_config.dart';
import 'helpers/e2e_test_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('Termin 19 - patient medication manage detail flow', () {
    tearDown(() async {
      await clearPulseWiseSession();
    });

    testWidgets(
      'patient can open a medication detail from manage list',
      (tester) async {
        await launchPulseWise(tester);

        await loginAsPatient(
          tester,
          email: E2eTestConfig.patientEmail,
          password: E2eTestConfig.patientPassword,
        );

        ensurePatientProfileReadyForE2e();

        await openPatientTab(tester, 'Pengingat');
        await waitForVisible(
          tester,
          find.text('Kalender Obat'),
          timeout: const Duration(seconds: 45),
        );

        await tapByKey(tester, patientMedicationCalendarManageButtonKey);
        await waitForVisible(
          tester,
          find.text('Kelola pengingat obat Anda'),
          timeout: const Duration(seconds: 45),
        );

        final firstCardFinder = find.byKey(patientMedicationManageFirstCardKey);
        final emptyStateFinder =
            find.textContaining('Belum ada pengingat obat');
        final noConnectionFinder =
            find.text('Daftar pengingat belum bisa dimuat');

        final manageState = await waitForAnyVisible(
          tester,
          [
            firstCardFinder,
            emptyStateFinder,
            noConnectionFinder,
          ],
          timeout: const Duration(seconds: 60),
        );

        if (!identical(manageState, firstCardFinder)) {
          throw TestFailure(
            'Medication detail E2E needs at least one medication reminder in the patient account.',
          );
        }

        await tapByKey(tester, patientMedicationManageFirstCardKey);
        final detailContentFinder =
            find.byKey(patientMedicationDetailContentKey);
        final detailState = await waitForAnyVisible(
          tester,
          [
            detailContentFinder,
            find.text('Detail pengingat belum bisa dimuat'),
          ],
          timeout: const Duration(seconds: 60),
        );
        if (!identical(detailState, detailContentFinder)) {
          throw TestFailure(
            'Medication detail page opened, but medication detail data did not load.',
          );
        }
        await waitForVisible(
          tester,
          find.byKey(patientMedicationDetailDeleteButtonKey),
          timeout: const Duration(seconds: 45),
        );

        await tapCustomAppBarBackUntilVisible(
          tester,
          find.text('Kelola pengingat obat Anda'),
          timeout: const Duration(seconds: 30),
        );

        await tapCustomAppBarBack(tester);
        await waitForVisible(
          tester,
          find.text('Kalender Obat'),
          timeout: const Duration(seconds: 30),
        );
      },
      skip: !E2eTestConfig.canRunPatientAuthFlow,
    );
  });
}
