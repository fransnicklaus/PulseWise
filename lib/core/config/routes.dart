import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/auth/presentation/pages/login_page.dart';
import 'package:pulsewise/features/auth/presentation/pages/profile_setup_page.dart';
import 'package:pulsewise/features/auth/presentation/pages/register_page.dart';
import 'package:pulsewise/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:pulsewise/features/dashboard_shell/presentation/pages/home_page.dart';
import 'package:pulsewise/features/diary/presentation/pages/add_diary_page.dart';
import 'package:pulsewise/features/diary/presentation/pages/detail_diari_page.dart';
import 'package:pulsewise/features/diary/presentation/pages/diary_qr_page.dart';
import 'package:pulsewise/features/diary/presentation/pages/qr_scanner_page.dart';
import 'package:pulsewise/features/diary/presentation/pages/riwayat_diari_page.dart';
import 'package:pulsewise/features/dashboard/presentation/pages/fcm_token_page.dart';
// import 'package:pulsewise/features/home_dashboard/presentation/pages/patient_dashboard_page.dart';
import 'package:pulsewise/features/dashboard/presentation/pages/patient_ml_assessment_page.dart';
import 'package:pulsewise/features/home_dashboard/presentation/pages/patient_flutter.dart'
    as patient_ui;
import 'package:pulsewise/features/dashboard/presentation/pages/print_page.dart';
import 'package:pulsewise/features/dashboard/presentation/pages/ml_recommendation_history_page.dart';
import 'package:pulsewise/features/emergency_contacts/presentation/pages/contacts_page.dart';
import 'package:pulsewise/features/health_connect/presentation/pages/health_connect_page.dart';
import 'package:pulsewise/features/medication/presentation/pages/add_pengingat_page.dart';
import 'package:pulsewise/features/medication/presentation/pages/detail_pengingat_page.dart';
import 'package:pulsewise/features/medication/presentation/pages/edit_pengingat_page.dart';
import 'package:pulsewise/features/medication/presentation/pages/manage_pengingat_page.dart';
import 'package:pulsewise/features/ml_questionnaire/presentation/pages/ml_questionnaire_page.dart';
import 'package:pulsewise/features/profile/presentation/pages/update_profile_page.dart';

GoRouter buildRouterConfig({String initialLocation = '/login'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
        routes: [
          GoRoute(
            path: 'register',
            builder: (context, state) {
              final extra = state.extra;
              if (extra is! Map<String, dynamic> || extra['flow'] != 'google') {
                return const RegisterPage();
              }

              return RegisterPage(
                googleRegistrationToken:
                    (extra['registrationToken'] ?? '').toString(),
                googleEmail: (extra['email'] ?? '').toString(),
                googleIdToken: (extra['idToken'] ?? '').toString(),
                googleRole: (extra['role'] ?? 'patient').toString(),
                googleFirstName: (extra['firstName'] ?? '').toString(),
                googleLastName: (extra['lastName'] ?? '').toString(),
                startAtOtp: extra['startAtOtp'] == true,
              );
            },
            routes: [
              GoRoute(
                path: 'profile-setup',
                builder: (context, state) {
                  final extra = state.extra;
                  if (extra is! Map<String, dynamic>) {
                    return const LoginPage();
                  }

                  final token =
                      (extra[AppSessionStore.tokenPrefsKey] ?? '').toString();
                  final patientId =
                      (extra[AppSessionStore.userIdPrefsKey] ?? '').toString();

                  if (token.isEmpty || patientId.isEmpty) {
                    return const LoginPage();
                  }

                  return ProfileSetupPage(
                    token: token,
                    patientId: patientId,
                  );
                },
              ),
              GoRoute(
                path: 'ml-questionnaire',
                builder: (context, state) {
                  final extra = state.extra;
                  if (extra is! Map<String, dynamic>) {
                    return const LoginPage();
                  }

                  final token =
                      (extra[AppSessionStore.tokenPrefsKey] ?? '').toString();
                  final patientId =
                      (extra[AppSessionStore.userIdPrefsKey] ?? '').toString();

                  if (token.isEmpty || patientId.isEmpty) {
                    return const LoginPage();
                  }

                  return MlQuestionnairePage(
                    token: token,
                    patientId: patientId,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'google-complete-registration',
            builder: (context, state) {
              final extra = state.extra;
              if (extra is! Map<String, dynamic>) {
                return const LoginPage();
              }

              final registrationToken =
                  (extra['registrationToken'] ?? '').toString();
              final email = (extra['email'] ?? '').toString();
              final role = (extra['role'] ?? 'patient').toString();
              final idToken = (extra['idToken'] ?? '').toString();

              if (registrationToken.isEmpty ||
                  email.isEmpty ||
                  idToken.isEmpty) {
                return const LoginPage();
              }

              return RegisterPage(
                googleRegistrationToken: registrationToken,
                googleEmail: email,
                googleIdToken: idToken,
                googleRole: role,
                googleFirstName: (extra['firstName'] ?? '').toString(),
                googleLastName: (extra['lastName'] ?? '').toString(),
                startAtOtp: false,
              );
            },
          ),
          GoRoute(
            path: 'google-verify-otp',
            builder: (context, state) {
              final extra = state.extra;
              if (extra is! Map<String, dynamic>) {
                return const LoginPage();
              }

              final email = (extra['email'] ?? '').toString();
              final role = (extra['role'] ?? 'patient').toString();
              final idToken = (extra['idToken'] ?? '').toString();

              if (email.isEmpty || idToken.isEmpty) {
                return const LoginPage();
              }

              return RegisterPage(
                googleEmail: email,
                googleIdToken: idToken,
                googleRole: role,
                startAtOtp: true,
              );
            },
          ),
          GoRoute(
            path: 'forgot-password',
            builder: (context, state) => const ForgotPasswordPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
        routes: [
          GoRoute(
            path: 'update-profile',
            builder: (context, state) => const UpdateProfilePage(),
          ),
          GoRoute(
            path: 'contacts',
            builder: (context, state) => const ContactsPage(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const AddContactPage(),
              ),
            ],
          ),
          GoRoute(
            path: 'add-diary',
            builder: (context, state) => const AddDiaryPage(),
          ),
          GoRoute(
            path: 'diary-qr',
            builder: (context, state) => const DiaryQrPage(),
          ),
          GoRoute(
            path: 'diary-qr/scan',
            builder: (context, state) => const QrScannerPage(),
          ),
          GoRoute(
            path: 'health-connect',
            builder: (context, state) => const HealthConnectPage(),
          ),
          GoRoute(
            path: 'fcm-token',
            builder: (context, state) => const FcmTokenPage(),
          ),
          GoRoute(
            path: 'diary',
            builder: (context, state) => const RiwayatDiariPage(),
            routes: [
              GoRoute(
                path: 'detail/:index',
                builder: (context, state) {
                  final index = int.parse(state.pathParameters['index'] ?? '0');
                  return DetailDiariPage(entryIndex: index);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'reminder/detail/:medicationId',
            builder: (context, state) {
              final medicationId = state.pathParameters['medicationId'] ?? '';
              return DetailPengingatPage(medicationId: medicationId);
            },
          ),
          GoRoute(
            path: 'reminder/add',
            builder: (context, state) => const AddPengingatPage(),
          ),
          GoRoute(
            path: 'reminder/edit/:medicationId',
            builder: (context, state) {
              final medicationId = state.pathParameters['medicationId'] ?? '';
              return EditPengingatPage(medicationId: medicationId);
            },
          ),
          GoRoute(
            path: 'reminder/manage',
            builder: (context, state) => const ManagePengingatPage(),
          ),
          GoRoute(
            path: 'patient-dashboard',
            builder: (context, state) =>
                const patient_ui.PatientDashboardPage(),
            routes: [
              GoRoute(
                path: 'ml-assessment',
                builder: (context, state) => const PatientMlAssessmentPage(),
              ),
              GoRoute(
                path: 'ml-recommendation-history',
                builder: (context, state) =>
                    const MlRecommendationHistoryPage(),
              ),
              GoRoute(
                path: 'print',
                builder: (context, state) => const PrintPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
