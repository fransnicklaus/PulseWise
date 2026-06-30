import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_test_config.dart';
import 'helpers/e2e_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Termin 2 - patient shell flow', () {
    tearDown(() async {
      await clearPulseWiseSession();
    });

    testWidgets(
      'patient can navigate across main patient tabs',
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
          ],
          timeout: const Duration(seconds: 45),
        );

        await openPatientTab(tester, 'Edukasi');
        await waitForAnyVisible(
          tester,
          [
            find.text('Kategori'),
            find.text('Cari'),
            find.text('Artikel gagal dimuat'),
          ],
          timeout: const Duration(seconds: 45),
        );

        await openPatientTab(tester, 'Diari');
        await waitForAnyVisible(
          tester,
          [
            find.text('Diari Kesehatan'),
            find.text('Metriks Kesehatan'),
            find.text('Diari belum bisa dimuat'),
          ],
          timeout: const Duration(seconds: 45),
        );

        await openPatientTab(tester, 'Pengingat');
        await waitForAnyVisible(
          tester,
          [
            find.text('Kalender Obat'),
            find.text('Tidak ada jadwal obat pada tanggal ini.'),
            find.text('Coba Lagi'),
          ],
          timeout: const Duration(seconds: 45),
        );

        await openPatientTab(tester, 'Profil');
        await waitForAnyVisible(
          tester,
          [
            find.text('Informasi Pribadi'),
            find.text('Pengaturan Akun'),
            find.text('Profil belum bisa dimuat'),
          ],
          timeout: const Duration(seconds: 45),
        );
      },
      skip: !E2eTestConfig.canRunPatientAuthFlow,
    );
  });
}
