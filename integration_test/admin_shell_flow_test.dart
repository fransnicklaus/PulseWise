import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_test_config.dart';
import 'helpers/e2e_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Termin 21 - admin shell flow', () {
    tearDown(() async {
      await clearPulseWiseSession();
    });

    testWidgets(
      'admin can open admin panel from profile and navigate users',
      (tester) async {
        await launchPulseWise(tester);

        await loginAsAdmin(
          tester,
          email: E2eTestConfig.adminEmail,
          password: E2eTestConfig.adminPassword,
        );

        if (find.text('Profil Belum Lengkap').evaluate().isNotEmpty) {
          throw TestFailure(
            'Admin E2E account must be able to open profile tab before admin panel navigation can run.',
          );
        }

        await openPatientTab(tester, 'Profil');
        await waitForVisible(
          tester,
          find.byKey(patientProfileAdminPanelButtonKey),
          timeout: const Duration(seconds: 60),
        );

        await launchPulseWise(
          tester,
          initialLocation: '/admin/home',
          clearSession: false,
        );

        await waitForVisible(
          tester,
          find.byKey(adminOverviewContentKey),
          timeout: const Duration(seconds: 60),
        );

        await openAdminShellItem(tester, adminShellUsersButtonKey);
        await waitForVisible(
          tester,
          find.byKey(adminUsersContentKey),
          timeout: const Duration(seconds: 60),
        );
        await waitForVisible(tester, find.text('Kelola Pengguna'));

        await openAdminShellItem(tester, adminShellHomeButtonKey);
        await waitForVisible(
          tester,
          find.byKey(adminOverviewContentKey),
          timeout: const Duration(seconds: 60),
        );
        await waitForVisible(tester, find.text('Panel Admin'));
      },
      skip: !E2eTestConfig.canRunAdminAuthFlow,
      timeout: const Timeout(Duration(minutes: 4)),
    );
  });
}

Future<void> openAdminShellItem(WidgetTester tester, Key itemKey) async {
  if (find.byKey(adminShellMenuButtonKey).evaluate().isNotEmpty) {
    await tapByKey(tester, adminShellMenuButtonKey);
    await tester.pump(const Duration(milliseconds: 300));
  }

  await tapByKey(tester, itemKey);
  await tester.pump(const Duration(milliseconds: 500));
}
