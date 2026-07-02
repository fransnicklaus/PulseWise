import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_test_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('Termin 13 - login form input flow', () {
    tearDown(() async {
      await clearPulseWiseSession();
    });

    testWidgets(
      'user can type email and password on login form',
      (tester) async {
        await launchPulseWise(tester);

        await enterLoginCredentials(
          tester,
          email: 'pasien.e2e@example.com',
          password: 'password-e2e',
        );

        expect(find.text('pasien.e2e@example.com'), findsOneWidget);
        expect(find.byKey(loginPasswordFieldKey), findsOneWidget);
        expect(find.byKey(loginSubmitButtonKey), findsOneWidget);
      },
    );
  });
}
