import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/main.dart';

const loginEmailFieldKey = Key('login_email_field');
const loginPasswordFieldKey = Key('login_password_field');
const loginSubmitButtonKey = Key('login_submit_button');
const patientProfileLogoutActionKey = Key('patient_profile_logout_action');
const patientProfileEditActionKey = Key('patient_profile_edit_action');
const patientDiaryHistoryButtonKey = Key('patient_diary_history_button');
const patientHomeEmergencyContactCardKey =
    Key('patient_home_emergency_contact_card');
const patientEducationSearchFieldKey = Key('patient_education_search_field');
const patientEducationFirstArticleCardKey =
    Key('patient_education_article_card_0');
const patientEducationArticleDetailContentKey =
    Key('patient_education_article_detail_content');
const patientHomeHealthDetailButtonKey =
    Key('patient_home_health_detail_button');
const patientDashboardContentKey = Key('patient_dashboard_content');
const patientMedicationManageAddButtonKey =
    Key('patient_medication_manage_add_button');
const patientMedicationNameFieldKey = Key('patient_medication_name_field');
const patientMedicationDoseFieldKey = Key('patient_medication_dose_field');
const patientMedicationFormPillOptionKey =
    Key('patient_medication_form_pill_option');
const patientMedicationNextButtonKey = Key('patient_medication_next_button');
const patientMedicationCalendarManageButtonKey =
    Key('patient_medication_calendar_manage_button');
const patientMedicationCalendarScrollViewKey =
    Key('patient_medication_calendar_scroll_view');
const patientMedicationStatusSaveButtonKey =
    Key('patient_medication_status_save_button');
const patientMedicationStatusManageButtonKey =
    Key('patient_medication_status_manage_button');
const patientMedicationDetailDeleteButtonKey =
    Key('patient_medication_detail_delete_button');
const patientMedicationConfirmDeleteButtonKey =
    Key('patient_medication_confirm_delete_button');
const customAppBarBackButtonKey = Key('custom_app_bar_back_button');

Key patientMedicationManageCardKey(String medicationName) {
  return Key('patient_medication_manage_card_$medicationName');
}

Key patientMedicationCalendarCardKey(String medicationName) {
  return Key('patient_medication_calendar_card_$medicationName');
}

Key patientHomeMedicationTileKey(String medicationName) {
  return Key('patient_home_medication_tile_$medicationName');
}

Future<void> clearPulseWiseSession() async {
  await AppSessionStore.clearSession();
}

Future<void> launchPulseWise(
  WidgetTester tester, {
  String initialLocation = '/login',
  bool clearSession = true,
}) async {
  await initializeDateFormatting('id_ID');
  if (clearSession) {
    await clearPulseWiseSession();
  }

  await tester.pumpWidget(
    ProviderScope(
      child: MyApp(initialLocation: initialLocation),
    ),
  );
  await tester.pump();
  await waitForVisible(tester, find.byType(MyApp));
}

Future<void> enterLoginCredentials(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  await tester.enterText(find.byKey(loginEmailFieldKey), email);
  await tester.enterText(find.byKey(loginPasswordFieldKey), password);
  await tester.pump();
}

Future<void> submitLogin(WidgetTester tester) async {
  await tester.tap(find.byKey(loginSubmitButtonKey));
  await tester.pump();
}

Future<void> loginAsPatient(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  await enterLoginCredentials(
    tester,
    email: email,
    password: password,
  );
  await submitLogin(tester);

  await waitForAnyVisible(
    tester,
    [
      find.text('Beranda'),
      find.text('Profil Belum Lengkap'),
      find.text('Isi Profil Sekarang'),
    ],
    timeout: const Duration(seconds: 60),
  );
  await dismissOptionalPatientPrompt(tester);
}

void ensurePatientProfileReadyForE2e() {
  if (find.text('Profil Belum Lengkap').evaluate().isNotEmpty ||
      find.text('Isi Profil Sekarang').evaluate().isNotEmpty) {
    throw TestFailure(
      'Patient E2E account must have a completed profile before patient shell tests can run.',
    );
  }
}

Future<void> openPatientTab(WidgetTester tester, String label) async {
  await tapLastText(tester, label);
  await tester.pump(const Duration(milliseconds: 500));
  await dismissOptionalPatientPrompt(tester);
}

Future<void> logoutFromPatientProfile(WidgetTester tester) async {
  if (find.text('Profil Belum Lengkap').evaluate().isNotEmpty) {
    throw TestFailure(
      'Patient E2E account must have a completed profile before logout can be tested.',
    );
  }

  await tapLastText(tester, 'Profil');
  await tester.pump();

  final logoutFinder = find.byKey(patientProfileLogoutActionKey);
  await ensureLastFinderVisible(
    tester,
    logoutFinder,
    timeout: const Duration(seconds: 30),
  );

  await tester.tap(logoutFinder, warnIfMissed: false);
  await tester.pump(const Duration(milliseconds: 500));
  await waitForAnyVisible(
    tester,
    [
      find.text('Konfirmasi Keluar'),
      find.text('Ya, Keluar'),
    ],
    timeout: const Duration(seconds: 15),
  );
  await tester.tap(find.text('Ya, Keluar').last);
  await waitForVisible(
    tester,
    find.byKey(loginSubmitButtonKey),
    timeout: const Duration(seconds: 45),
  );
}

Future<void> dismissOptionalPatientPrompt(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));

  final healthPromptVisible =
      find.text('Hubungkan Smartwatch Anda?').evaluate().isNotEmpty ||
          find.text('Lanjutkan Setup Health Connect?').evaluate().isNotEmpty;

  if (healthPromptVisible) {
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> tapLastText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await waitForVisible(tester, finder);
  await tester.tap(finder.last);
}

Future<void> tapByKey(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await waitForVisible(tester, finder);
  await revealFinderInScrollable(tester, finder);
  await tester.tap(finder.first);
  await tester.pump();
}

Future<void> tapCustomAppBarBack(WidgetTester tester) async {
  final finder = find.byKey(customAppBarBackButtonKey);
  await waitForVisible(tester, finder);
  await pumpUntilNoTransientCallbacks(tester);
  await tester.tap(finder.last, warnIfMissed: false);

  final end = DateTime.now().add(const Duration(seconds: 2));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isEmpty) {
      return;
    }
  }

  if (finder.evaluate().isNotEmpty) {
    final didPop = await tester.binding.handlePopRoute();
    if (didPop) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }
}

Future<void> pumpUntilNoTransientCallbacks(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 2),
  Duration step = const Duration(milliseconds: 100),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
    if (tester.binding.transientCallbackCount == 0) {
      return;
    }
  }
}

Future<void> dismissKeyboard(WidgetTester tester) async {
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> ensureLastFinderVisible(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  await waitForVisible(tester, finder, timeout: timeout);
  await revealFinderInScrollable(
    tester,
    finder.last,
    alignment: 0.65,
  );

  final scrollables = find.byType(Scrollable);
  if (scrollables.evaluate().isNotEmpty) {
    await tester.drag(scrollables.last, const Offset(0, -140));
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> scrollUntilVisible(
  WidgetTester tester,
  Finder finder, {
  Finder? scrollable,
  Duration timeout = const Duration(seconds: 20),
  double scrollDelta = -420,
}) async {
  final end = DateTime.now().add(timeout);
  var attempts = 0;
  while (DateTime.now().isBefore(end)) {
    if (finder.evaluate().isNotEmpty) {
      await revealFinderInScrollable(tester, finder);
      return;
    }

    final scrollableFinder = scrollable ?? find.byType(Scrollable).last;
    if (scrollableFinder.evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 100));
      continue;
    }

    final direction = ((attempts ~/ 20).isEven) ? scrollDelta : -scrollDelta;
    attempts += 1;
    await tester.dragFrom(
      safeDragStartForScrollable(tester, scrollableFinder),
      Offset(0, direction),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  throw TestFailure('Timed out scrolling to visible finder: $finder');
}

Future<void> revealFinderInScrollable(
  WidgetTester tester,
  Finder finder, {
  double alignment = 0.35,
}) async {
  if (finder.evaluate().isEmpty) return;

  await Scrollable.ensureVisible(
    tester.element(finder.first),
    alignment: alignment,
    duration: const Duration(milliseconds: 250),
  );
  await tester.pump(const Duration(milliseconds: 350));
}

Offset safeDragStartForScrollable(
  WidgetTester tester,
  Finder scrollableFinder,
) {
  final rect = tester.getRect(scrollableFinder.first);
  final view = tester.view;
  final viewportHeight = view.physicalSize.height / view.devicePixelRatio;
  final minY = rect.top + 96;
  final maxYFromScrollable = rect.bottom - 180;
  final maxYFromViewport = viewportHeight - 180;
  final maxY = maxYFromScrollable < maxYFromViewport
      ? maxYFromScrollable
      : maxYFromViewport;
  final y = maxY > minY ? rect.center.dy.clamp(minY, maxY).toDouble() : minY;
  final minX = rect.left + 24;
  final maxX = rect.right - 24;
  final x = maxX > minX
      ? rect.center.dx.clamp(minX, maxX).toDouble()
      : rect.center.dx;

  return Offset(x, y);
}

Future<void> waitForVisible(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
  Duration step = const Duration(milliseconds: 100),
}) async {
  await waitForAnyVisible(
    tester,
    [finder],
    timeout: timeout,
    step: step,
  );
}

Future<Finder> waitForAnyVisible(
  WidgetTester tester,
  List<Finder> finders, {
  Duration timeout = const Duration(seconds: 10),
  Duration step = const Duration(milliseconds: 100),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    for (final finder in finders) {
      if (finder.evaluate().isNotEmpty) {
        return finder;
      }
    }
    await tester.pump(step);
  }

  final descriptions = finders.map((finder) => finder.toString()).join(', ');
  throw TestFailure('Timed out waiting for visible finder: $descriptions');
}

Future<void> waitForAbsent(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 5),
  Duration step = const Duration(milliseconds: 100),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    if (finder.evaluate().isEmpty) {
      return;
    }
    await tester.pump(step);
  }

  throw TestFailure('Timed out waiting for absent finder: $finder');
}
