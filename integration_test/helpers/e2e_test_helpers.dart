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

Future<void> ensureLastFinderVisible(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  await waitForVisible(tester, finder, timeout: timeout);
  await tester.ensureVisible(finder.last);
  await tester.pump(const Duration(milliseconds: 300));

  final scrollables = find.byType(Scrollable);
  if (scrollables.evaluate().isNotEmpty) {
    await tester.drag(scrollables.last, const Offset(0, -140));
    await tester.pump(const Duration(milliseconds: 300));
  }
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
