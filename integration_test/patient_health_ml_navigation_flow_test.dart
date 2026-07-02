import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_test_config.dart';
import 'helpers/e2e_test_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('Termin 14-16 - patient health and ML navigation flow', () {
    tearDown(() async {
      await clearPulseWiseSession();
    });

    testWidgets(
      'patient can open Health Connect guide and ML pages without submitting',
      (tester) async {
        await launchPulseWise(tester);

        await loginAsPatient(
          tester,
          email: E2eTestConfig.patientEmail,
          password: E2eTestConfig.patientPassword,
        );

        ensurePatientProfileReadyForE2e();

        await openHealthConnectGuide(tester);
        await openMlQuestionnaire(tester);
        await openMlAssessmentAndOptionalHistory(tester);
      },
      skip: !E2eTestConfig.canRunPatientAuthFlow,
    );
  });
}

Future<void> openHealthConnectGuide(WidgetTester tester) async {
  await openPatientTab(tester, 'Edukasi');
  await waitForVisible(
    tester,
    find.byKey(patientEducationSearchFieldKey),
    timeout: const Duration(seconds: 60),
  );

  final guideButtonFinder =
      find.byKey(patientEducationHealthConnectGuideButtonKey);
  if (guideButtonFinder.evaluate().isEmpty) {
    final wearableCardFinder = find.byKey(patientEducationWearableCardKey);
    if (wearableCardFinder.evaluate().isEmpty) {
      return;
    }
    await scrollUntilVisible(
      tester,
      wearableCardFinder,
      timeout: const Duration(seconds: 45),
    );
    await tapByKey(tester, patientEducationWearableCardKey);
  }

  await scrollUntilVisible(
    tester,
    guideButtonFinder,
    timeout: const Duration(seconds: 45),
  );
  await tapByKey(tester, patientEducationHealthConnectGuideButtonKey);

  await waitForAnyVisible(
    tester,
    [
      find.text('Koneksi Wearable'),
      find.text('Periksa apakah perangkat mendukung'),
    ],
    timeout: const Duration(seconds: 45),
  );

  await tapCustomAppBarBack(tester);
  await waitForAnyVisible(
    tester,
    [
      find.byKey(patientEducationSearchFieldKey),
      find.text('Edukasi'),
    ],
    timeout: const Duration(seconds: 30),
  );
}

Future<void> openMlQuestionnaire(WidgetTester tester) async {
  await openPatientTab(tester, 'Profil');
  await waitForVisible(
    tester,
    find.text('Pengaturan Akun'),
    timeout: const Duration(seconds: 60),
  );

  await scrollUntilVisible(
    tester,
    find.byKey(patientProfileMlQuestionnaireActionKey),
    timeout: const Duration(seconds: 45),
  );
  await tapByKey(tester, patientProfileMlQuestionnaireActionKey);

  await waitForAnyVisible(
    tester,
    [
      find.byKey(patientMlQuestionnaireContentKey),
      find.text('Kuisioner Pasien'),
      find.text('Kirim Kuisioner'),
    ],
    timeout: const Duration(seconds: 60),
  );

  await tapCustomAppBarBack(tester);
  await waitForAnyVisible(
    tester,
    [
      find.text('Beranda'),
      find.text('Status Kesehatan'),
      find.text('Pengaturan Akun'),
    ],
    timeout: const Duration(seconds: 45),
  );
}

Future<void> openMlAssessmentAndOptionalHistory(WidgetTester tester) async {
  await openPatientTab(tester, 'Beranda');
  await waitForAnyVisible(
    tester,
    [
      find.text('Status Kesehatan'),
      find.text('Pengingat Obat'),
      find.byKey(patientHomeHealthDetailButtonKey),
    ],
    timeout: const Duration(seconds: 60),
  );
  await dismissOptionalPatientPrompt(tester);

  await scrollUntilVisible(
    tester,
    find.byKey(patientHomeHealthDetailButtonKey),
    timeout: const Duration(seconds: 45),
  );
  await dismissOptionalPatientPrompt(
    tester,
    timeout: const Duration(seconds: 2),
  );
  await tapByKey(tester, patientHomeHealthDetailButtonKey);

  await waitForVisible(
    tester,
    find.byKey(patientDashboardContentKey),
    timeout: const Duration(seconds: 60),
  );

  await scrollUntilVisible(
    tester,
    find.byKey(patientDashboardMlAssessmentButtonKey),
    timeout: const Duration(seconds: 60),
  );
  await tapByKey(tester, patientDashboardMlAssessmentButtonKey);

  await waitForAnyVisible(
    tester,
    [
      find.byKey(patientMlAssessmentContentKey),
      find.text('Form Asesmen ML'),
      find.text('Simpan Asesmen'),
    ],
    timeout: const Duration(seconds: 45),
  );

  await tapCustomAppBarBackUntilVisible(
    tester,
    find.byKey(patientDashboardContentKey),
    timeout: const Duration(seconds: 45),
  );

  final historyButtonFinder = find.byKey(patientDashboardMlHistoryButtonKey);
  await tester.pump(const Duration(seconds: 2));
  if (historyButtonFinder.evaluate().isNotEmpty) {
    await scrollUntilVisible(
      tester,
      historyButtonFinder,
      timeout: const Duration(seconds: 30),
    );
    await tapByKey(tester, patientDashboardMlHistoryButtonKey);

    await waitForAnyVisible(
      tester,
      [
        find.text('Riwayat Prediksi ML'),
        find.text('Belum ada riwayat prediksi ML'),
      ],
      timeout: const Duration(seconds: 60),
    );

    await tapCustomAppBarBackUntilVisible(
      tester,
      find.byKey(patientDashboardContentKey),
      timeout: const Duration(seconds: 45),
    );
  }

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
}
