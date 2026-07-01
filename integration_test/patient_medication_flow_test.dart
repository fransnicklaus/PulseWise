import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_test_config.dart';
import 'helpers/e2e_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Termin 3 - patient medication flow', () {
    tearDown(() async {
      await clearPulseWiseSession();
    });

    testWidgets(
      'patient can open add reminder form and sees validation errors',
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

        await tapLastText(tester, 'Kelola');
        await waitForVisible(
          tester,
          find.text('Kelola pengingat obat Anda'),
          timeout: const Duration(seconds: 45),
        );

        await tester.tap(find.byKey(patientMedicationManageAddButtonKey));
        await waitForVisible(
          tester,
          find.text('Tambah Pengingat'),
          timeout: const Duration(seconds: 20),
        );
        await waitForVisible(tester, find.text('Nama Obat'));

        await tapByKey(tester, patientMedicationNextButtonKey);
        await waitForVisible(
          tester,
          find.text('Isi nama dan pilih bentuk terlebih dahulu.'),
        );
        await waitForAbsent(
          tester,
          find.text('Isi nama dan pilih bentuk terlebih dahulu.'),
        );

        await tester.enterText(
          find.byKey(patientMedicationNameFieldKey),
          'Obat E2E',
        );
        await tester.pump();
        await dismissKeyboard(tester);

        await tapByKey(tester, patientMedicationFormPillOptionKey);
        await tapByKey(tester, patientMedicationNextButtonKey);
        await waitForVisible(tester, find.text('Besar Dosis'));

        await tapByKey(tester, patientMedicationNextButtonKey);
        await waitForVisible(
          tester,
          find.text('Isi besar dosis terlebih dahulu.'),
        );
        await waitForAbsent(
          tester,
          find.text('Isi besar dosis terlebih dahulu.'),
        );

        await tester.enterText(
            find.byKey(patientMedicationDoseFieldKey), 'abc');
        await tester.pump();
        await dismissKeyboard(tester);

        await tapByKey(tester, patientMedicationNextButtonKey);
        await waitForVisible(
          tester,
          find.text('Besar dosis hanya boleh angka.'),
        );
      },
      skip: !E2eTestConfig.canRunPatientAuthFlow,
    );
  });
}
