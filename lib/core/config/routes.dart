import 'package:go_router/go_router.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:pulsewise/core/constants/app_roles.dart';
import 'package:pulsewise/core/platform/health_connect_visibility.dart';
import 'package:pulsewise/core/presentation/pages/not_found_page.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/features/auth/presentation/pages/login_page.dart';
import 'package:pulsewise/features/admin/presentation/pages/admin_doctor_detail_page.dart';
import 'package:pulsewise/features/admin/presentation/pages/admin_doctor_detail_resolver_page.dart';
import 'package:pulsewise/features/admin/presentation/pages/admin_doctors_review_page.dart';
import 'package:pulsewise/features/admin/presentation/pages/admin_user_detail_page.dart';
import 'package:pulsewise/features/admin/presentation/pages/admin_users_page.dart';
import 'package:pulsewise/features/admin_shell/presentation/pages/admin_home_page.dart';
import 'package:pulsewise/features/auth/presentation/pages/profile_setup_page.dart';
import 'package:pulsewise/features/auth/presentation/pages/register_page.dart';
import 'package:pulsewise/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:pulsewise/features/dashboard_shell/presentation/pages/home_page.dart';
import 'package:pulsewise/features/doctor/data/models/doctor_dashboard_models.dart';
import 'package:pulsewise/features/doctor/data/models/doctor_heart_risk_models.dart';
import 'package:pulsewise/features/doctor/presentation/pages/doctor_pending_verification_page.dart';
import 'package:pulsewise/features/doctor/presentation/pages/doctor_patient_heart_risk_form_page.dart';
import 'package:pulsewise/features/doctor/presentation/pages/doctor_patient_heart_risk_history_page.dart';
import 'package:pulsewise/features/doctor/presentation/pages/doctor_patient_heart_risk_page.dart';
import 'package:pulsewise/features/doctor/presentation/pages/doctor_patient_diary_history_page.dart';
import 'package:pulsewise/features/doctor/presentation/pages/doctor_ml_recommendation_history_page.dart';
import 'package:pulsewise/features/doctor/presentation/pages/doctor_patient_dashboard_page.dart';
import 'package:pulsewise/features/doctor/presentation/pages/update_doctor_profile_page.dart';
import 'package:pulsewise/features/doctor_shell/presentation/pages/doctor_home_page.dart';
import 'package:pulsewise/features/education/presentation/pages/education_article_detail_page.dart';
import 'package:pulsewise/features/diary/presentation/pages/add_diary_page.dart';
import 'package:pulsewise/features/diary/presentation/pages/detail_diari_page.dart';
import 'package:pulsewise/features/diary/presentation/pages/diary_qr_page.dart';
import 'package:pulsewise/features/diary/presentation/pages/qr_scanner_page.dart';
import 'package:pulsewise/features/diary/presentation/pages/riwayat_diari_page.dart';
// import 'package:pulsewise/features/home_dashboard/presentation/pages/patient_dashboard_page.dart';
import 'package:pulsewise/features/home_dashboard/presentation/pages/patient_flutter.dart'
    as patient_ui;
import 'package:pulsewise/features/emergency_contacts/presentation/pages/contacts_page.dart';
import 'package:pulsewise/features/health_connect/presentation/pages/health_connect_page.dart';
import 'package:pulsewise/features/ml_assessment/presentation/pages/patient_ml_assessment_page.dart';
import 'package:pulsewise/features/ml_recommendation/presentation/pages/ml_recommendation_history_page.dart';
import 'package:pulsewise/features/medication/presentation/pages/add_pengingat_page.dart';
import 'package:pulsewise/features/medication/presentation/pages/detail_pengingat_page.dart';
import 'package:pulsewise/features/medication/presentation/pages/edit_pengingat_page.dart';
import 'package:pulsewise/features/medication/presentation/pages/manage_pengingat_page.dart';
import 'package:pulsewise/features/ml_questionnaire/presentation/pages/ml_questionnaire_route_resolver_page.dart';
import 'package:pulsewise/features/profile/presentation/pages/date_time_picker_demo_page.dart';
import 'package:pulsewise/features/profile/presentation/pages/delete_account_page.dart';
import 'package:pulsewise/features/profile/presentation/pages/fcm_token_page.dart';
import 'package:pulsewise/features/profile/presentation/pages/update_profile_page.dart';
import 'package:pulsewise/features/reports/presentation/pages/print_page.dart';

GoRouter buildRouterConfig({String initialLocation = '/login'}) {
  return GoRouter(
    initialLocation: initialLocation,
    redirect: (context, state) async {
      return _guardAppRouteAccess(state);
    },
    errorBuilder: (context, state) => NotFoundPage(
      requestedLocation: state.uri.toString(),
    ),
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
            redirect: (context, state) =>
                shouldExposeHealthConnectUi ? null : '/home',
            builder: (context, state) => const HealthConnectPage(),
          ),
          GoRoute(
            path: 'fcm-token',
            builder: (context, state) => const FcmTokenPage(),
          ),
          GoRoute(
            path: 'picker-demo',
            builder: (context, state) => const DateTimePickerDemoPage(),
          ),
          GoRoute(
            path: 'ml-questionnaire',
            builder: (context, state) {
              final extra = state.extra;
              if (extra is Map<String, dynamic>) {
                return MlQuestionnaireRouteResolverPage(
                  tokenOverride:
                      (extra[AppSessionStore.tokenPrefsKey] ?? '').toString(),
                  patientIdOverride:
                      (extra[AppSessionStore.userIdPrefsKey] ?? '').toString(),
                );
              }

              return const MlQuestionnaireRouteResolverPage();
            },
          ),
          GoRoute(
            path: 'delete-account',
            builder: (context, state) => const DeleteAccountPage(),
          ),
          GoRoute(
            path: 'education/articles/:slug',
            builder: (context, state) {
              final slug = state.pathParameters['slug'] ?? '';
              return EducationArticleDetailPage(slug: slug);
            },
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
      GoRoute(
        path: '/admin/home',
        builder: (context, state) => const AdminHomePage(),
        routes: [
          GoRoute(
            path: 'users',
            builder: (context, state) => const AdminUsersPage(),
          ),
          GoRoute(
            path: 'users/:userId',
            builder: (context, state) {
              final userId = state.pathParameters['userId'] ?? '';
              return AdminUserDetailPage(userId: userId);
            },
          ),
          GoRoute(
            path: 'doctors',
            builder: (context, state) => const AdminDoctorsReviewPage(),
          ),
          GoRoute(
            path: 'doctors/by-user/:userId',
            builder: (context, state) {
              final userId = state.pathParameters['userId'] ?? '';
              return AdminDoctorDetailResolverPage(userId: userId);
            },
          ),
          GoRoute(
            path: 'doctors/:doctorId',
            builder: (context, state) {
              final doctorId = state.pathParameters['doctorId'] ?? '';
              return AdminDoctorDetailPage(doctorId: doctorId);
            },
          ),
        ],
      ),
      GoRoute(
        path: doctorPendingVerificationRoute,
        builder: (context, state) => const DoctorPendingVerificationPage(),
        routes: [
          GoRoute(
            path: 'update-profile',
            builder: (context, state) => const UpdateDoctorProfilePage(),
          ),
        ],
      ),
      GoRoute(
        path: '/doctor/home',
        builder: (context, state) => const DoctorHomePage(),
        routes: [
          GoRoute(
            path: 'update-profile',
            builder: (context, state) => const UpdateDoctorProfilePage(),
          ),
          GoRoute(
            path: 'education/articles/:slug',
            builder: (context, state) {
              final slug = state.pathParameters['slug'] ?? '';
              return EducationArticleDetailPage(slug: slug);
            },
          ),
          GoRoute(
            path: 'patients/:patientId',
            builder: (context, state) {
              final patientId = state.pathParameters['patientId'] ?? '';
              final extra = state.extra;
              return DoctorPatientDashboardPage(
                patientId: patientId,
                initialSummary:
                    extra is DoctorDashboardPatientSummaryData ? extra : null,
              );
            },
            routes: [
              GoRoute(
                path: 'diary-history',
                builder: (context, state) {
                  final patientId = state.pathParameters['patientId'] ?? '';
                  return DoctorPatientDiaryHistoryPage(patientId: patientId);
                },
              ),
              GoRoute(
                path: 'ml-recommendation-history',
                builder: (context, state) {
                  final patientId = state.pathParameters['patientId'] ?? '';
                  return DoctorMlRecommendationHistoryPage(
                    patientId: patientId,
                  );
                },
              ),
              GoRoute(
                path: 'heart-risk-model',
                builder: (context, state) {
                  final patientId = state.pathParameters['patientId'] ?? '';
                  final extra = state.extra;
                  return DoctorPatientHeartRiskPage(
                    patientId: patientId,
                    entryData: extra is DoctorHeartRiskEntryData ? extra : null,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'form',
                    builder: (context, state) {
                      final patientId = state.pathParameters['patientId'] ?? '';
                      final extra = state.extra;
                      return DoctorPatientHeartRiskFormPage(
                        patientId: patientId,
                        entryData:
                            extra is DoctorHeartRiskEntryData ? extra : null,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'history',
                    builder: (context, state) {
                      final patientId = state.pathParameters['patientId'] ?? '';
                      final extra = state.extra;
                      return DoctorPatientHeartRiskHistoryPage(
                        patientId: patientId,
                        entryData:
                            extra is DoctorHeartRiskEntryData ? extra : null,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

Future<String?> _guardAppRouteAccess(GoRouterState state) async {
  final path = state.uri.path;
  final isAuthRoute = _isPublicAuthRoute(path);

  final session = await AppSessionStore.readSession(allowEnvFallback: false);
  if (!session.hasValidSession) {
    return isAuthRoute ? null : '/login';
  }

  final token = (session.token ?? '').trim();
  if (_isSessionTokenExpiredOrInvalid(token)) {
    await AppSessionStore.clearSession();
    return isAuthRoute ? null : '/login';
  }

  if (isAuthRoute) {
    return routeForRoleSession(
      role: session.role,
      nextStep: session.nextStep,
      accountStatus: session.accountStatus,
    );
  }

  return null;
}

bool _isPublicAuthRoute(String path) {
  return path == '/login' || path.startsWith('/login/');
}

bool _isSessionTokenExpiredOrInvalid(String token) {
  if (token.isEmpty) return true;

  try {
    return JwtDecoder.isExpired(token);
  } catch (_) {
    return true;
  }
}
