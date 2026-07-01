import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_test_config.dart';
import 'helpers/e2e_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Termin 4 - patient medication lifecycle', () {
    tearDown(() async {
      await clearPulseWiseSession();
    });

    testWidgets(
      'patient can create, mark taken, inspect, and delete a reminder',
      (tester) async {
        final suffix = DateTime.now().millisecondsSinceEpoch.remainder(1000000);
        final medicationName = 'Obat E2E $suffix';

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

        await tapByKey(tester, patientMedicationManageAddButtonKey);
        await waitForVisible(
          tester,
          find.text('Tambah Pengingat'),
          timeout: const Duration(seconds: 20),
        );

        await tester.enterText(
          find.byKey(patientMedicationNameFieldKey),
          medicationName,
        );
        await tester.pump();
        await dismissKeyboard(tester);
        await tapByKey(tester, patientMedicationFormPillOptionKey);
        await tapByKey(tester, patientMedicationNextButtonKey);

        await waitForVisible(tester, find.text('Besar Dosis'));
        await tester.enterText(find.byKey(patientMedicationDoseFieldKey), '1');
        await tester.pump();
        await dismissKeyboard(tester);
        await tapByKey(tester, patientMedicationNextButtonKey);

        await waitForVisible(tester, find.text('Seberapa sering obat diminum'));
        await tapByKey(tester, patientMedicationNextButtonKey);

        await waitForVisible(
            tester, find.text('Sehari berapa banyak minumnya'));
        await waitForVisible(tester, find.text('Simpan Pengingat'));
        await tapByKey(tester, patientMedicationNextButtonKey);

        await waitForVisible(
          tester,
          find.byKey(patientMedicationManageCardKey(medicationName)),
          timeout: const Duration(seconds: 60),
        );

        await tapCustomAppBarBack(tester);
        await waitForVisible(
          tester,
          find.text('Kalender Obat'),
          timeout: const Duration(seconds: 30),
        );
        await waitForVisible(
          tester,
          find.byKey(patientMedicationCalendarCardKey(medicationName)),
          timeout: const Duration(seconds: 60),
        );

        await openPatientTab(tester, 'Beranda');
        await waitForVisible(tester, find.text('Pengingat Obat'));
        await scrollUntilVisible(
          tester,
          find.byKey(patientHomeMedicationTileKey(medicationName)),
          timeout: const Duration(seconds: 45),
        );

        await openPatientTab(tester, 'Pengingat');
        await waitForVisible(
          tester,
          find.byKey(patientMedicationCalendarCardKey(medicationName)),
          timeout: const Duration(seconds: 45),
        );
        await tapByKey(
          tester,
          patientMedicationCalendarCardKey(medicationName),
        );
        await waitForVisible(tester, find.text(medicationName));
        await tapByKey(tester, patientMedicationStatusSaveButtonKey);
        await waitForAbsent(
          tester,
          find.byKey(patientMedicationStatusSaveButtonKey),
          timeout: const Duration(seconds: 60),
        );
        await waitForVisible(
          tester,
          find.text('Diminum'),
          timeout: const Duration(seconds: 60),
        );
        await waitForAbsent(
          tester,
          find.text('Status obat berhasil diperbarui.'),
          timeout: const Duration(seconds: 6),
        );

        await tapByKey(
          tester,
          patientMedicationCalendarCardKey(medicationName),
        );
        await waitForVisible(tester, find.text(medicationName));
        await tapByKey(tester, patientMedicationStatusManageButtonKey);

        await waitForVisible(
          tester,
          find.text('Detail Pengingat'),
          timeout: const Duration(seconds: 45),
        );
        await waitForVisible(tester, find.text(medicationName));
        await waitForVisible(tester, find.text('Waktu Minum'));

        final deleteFinder = find.byKey(patientMedicationDetailDeleteButtonKey);
        await ensureLastFinderVisible(
          tester,
          deleteFinder,
          timeout: const Duration(seconds: 20),
        );
        await tester.tap(deleteFinder);
        await waitForVisible(tester, find.text('Hapus Pengingat?'));
        await tapByKey(tester, patientMedicationConfirmDeleteButtonKey);

        await waitForVisible(
          tester,
          find.text('Kelola pengingat obat Anda'),
          timeout: const Duration(seconds: 45),
        );
        await waitForAbsent(
          tester,
          find.byKey(patientMedicationManageCardKey(medicationName)),
          timeout: const Duration(seconds: 60),
        );
      },
      skip: !E2eTestConfig.canRunPatientAuthFlow,
    );
  });
}
