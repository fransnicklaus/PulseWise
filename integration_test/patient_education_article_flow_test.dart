import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_test_config.dart';
import 'helpers/e2e_test_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('Termin 8 - patient education article flow', () {
    tearDown(() async {
      await clearPulseWiseSession();
    });

    testWidgets(
      'patient can open an education article and return to education tab',
      (tester) async {
        await launchPulseWise(tester);

        await loginAsPatient(
          tester,
          email: E2eTestConfig.patientEmail,
          password: E2eTestConfig.patientPassword,
        );

        ensurePatientProfileReadyForE2e();

        final searchFieldFinder = find.byKey(patientEducationSearchFieldKey);
        await openPatientTab(tester, 'Edukasi');
        await waitForVisible(
          tester,
          searchFieldFinder,
          timeout: const Duration(seconds: 60),
        );

        final firstArticleFinder =
            find.byKey(patientEducationFirstArticleCardKey);
        final articlesState = await waitForAnyVisible(
          tester,
          [
            firstArticleFinder,
            find.text('Belum ada artikel edukasi yang tersedia saat ini.'),
            find.text('Artikel gagal dimuat'),
            find.text('Artikel belum bisa dimuat'),
          ],
          timeout: const Duration(seconds: 60),
        );
        if (!identical(articlesState, firstArticleFinder)) {
          throw TestFailure(
            'Education E2E backend must have at least one published article.',
          );
        }

        await tapByKey(tester, patientEducationFirstArticleCardKey);
        await waitForVisible(
          tester,
          find.byKey(patientEducationArticleDetailContentKey),
          timeout: const Duration(seconds: 60),
        );

        await tapCustomAppBarBack(tester);
        await waitForAbsent(
          tester,
          find.byKey(patientEducationArticleDetailContentKey),
          timeout: const Duration(seconds: 15),
        );

        final returnedState = await waitForAnyVisible(
          tester,
          [
            searchFieldFinder,
            firstArticleFinder,
            find.text('Artikel Terbaru'),
            find.text('Artikel Populer'),
            find.text('Beranda'),
            find.text('Status Kesehatan'),
          ],
          timeout: const Duration(seconds: 30),
        );
        final alreadyOnEducation =
            identical(returnedState, searchFieldFinder) ||
                identical(returnedState, firstArticleFinder);
        if (!alreadyOnEducation) {
          await openPatientTab(tester, 'Edukasi');
        }
        await waitForAnyVisible(
          tester,
          [
            searchFieldFinder,
            firstArticleFinder,
            find.text('Artikel Terbaru'),
            find.text('Artikel Populer'),
          ],
          timeout: const Duration(seconds: 30),
        );
      },
      skip: !E2eTestConfig.canRunPatientAuthFlow,
    );
  });
}
