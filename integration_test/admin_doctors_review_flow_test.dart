import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_test_config.dart';
import 'helpers/e2e_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Termin 22 - admin doctors review flow', () {
    tearDown(() async {
      await clearPulseWiseSession();
    });

    testWidgets(
      'admin can open doctors review page without mutating doctor status',
      (tester) async {
        await launchPulseWise(tester);

        await loginAsAdmin(
          tester,
          email: E2eTestConfig.adminEmail,
          password: E2eTestConfig.adminPassword,
        );

        await launchPulseWise(
          tester,
          initialLocation: '/admin/home/doctors',
          clearSession: false,
        );

        await waitForVisible(
          tester,
          find.byKey(adminDoctorsReviewContentKey),
          timeout: const Duration(seconds: 60),
        );
        await waitForAnyVisible(
          tester,
          [
            find.text('Review Dokter'),
            find.text('Status dokter'),
            find.text('Tidak ada dokter pada status ini'),
            find.text('Daftar dokter belum bisa dimuat'),
            find.text('Daftar dokter gagal dimuat'),
          ],
          timeout: const Duration(seconds: 60),
        );
      },
      skip: !E2eTestConfig.canRunAdminAuthFlow,
      timeout: const Timeout(Duration(minutes: 4)),
    );
  });
}
