import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';

import 'helpers/e2e_test_config.dart';
import 'helpers/e2e_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Termin 23 - admin user detail flow', () {
    tearDown(() async {
      await clearPulseWiseSession();
    });

    testWidgets(
      'admin can open own user detail without mutating account status',
      (tester) async {
        await launchPulseWise(tester);

        await loginAsAdmin(
          tester,
          email: E2eTestConfig.adminEmail,
          password: E2eTestConfig.adminPassword,
        );

        final session = await AppSessionStore.readSession(
          allowEnvFallback: false,
        );
        final userId = session.userId?.trim() ?? '';
        if (userId.isEmpty) {
          throw TestFailure(
            'Admin user detail E2E requires a userId in the saved login session.',
          );
        }

        await launchPulseWise(
          tester,
          initialLocation: '/admin/home/users/$userId',
          clearSession: false,
        );

        await waitForVisible(
          tester,
          find.byKey(adminUserDetailContentKey),
          timeout: const Duration(seconds: 60),
        );
        await waitForAnyVisible(
          tester,
          [
            find.text('Detail Pengguna'),
            find.text('Informasi Akun'),
            find.text('Timeline Akun'),
          ],
          timeout: const Duration(seconds: 60),
        );
      },
      skip: !E2eTestConfig.canRunAdminAuthFlow,
      timeout: const Timeout(Duration(minutes: 4)),
    );
  });
}
