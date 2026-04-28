import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/features/auth/presentation/pages/login_page.dart';
import 'package:pulsewise/features/auth/presentation/pages/ml_questionnaire_page.dart';
import 'package:pulsewise/features/auth/presentation/pages/profile_setup_page.dart';
import 'package:pulsewise/features/auth/presentation/pages/register_page.dart';
import 'package:pulsewise/features/dashboard/presentation/pages/home_page.dart';
import 'package:pulsewise/features/dashboard/presentation/pages/contacts_page.dart';
import 'package:pulsewise/features/dashboard/presentation/pages/add_diary_page.dart';
import 'package:pulsewise/features/dashboard/presentation/pages/riwayat_diari_page.dart';
import 'package:pulsewise/features/dashboard/presentation/pages/detail_diari_page.dart';
import 'package:pulsewise/features/dashboard/presentation/pages/detail_pengingat_page.dart';
import 'package:pulsewise/features/dashboard/presentation/pages/add_pengingat_page.dart';
import 'package:pulsewise/features/dashboard/presentation/pages/edit_pengingat_page.dart';
import 'package:pulsewise/features/dashboard/presentation/pages/manage_pengingat_page.dart';
import 'package:pulsewise/features/dashboard/presentation/pages/diary_qr_page.dart';
import 'package:pulsewise/features/dashboard/presentation/pages/qr_scanner_page.dart';
import 'package:pulsewise/features/dashboard/presentation/pages/health_connect_page.dart';
import 'package:pulsewise/features/dashboard/presentation/pages/update_profile_page.dart';
// import 'package:pulsewise/features/dashboard/presentation/pages/patient_dashboard_page.dart';
import 'package:pulsewise/features/dashboard/presentation/pages/patient_flutter.dart'
    as patient_ui;
import 'package:pulsewise/features/dashboard/presentation/pages/print_page.dart';
import 'package:pulsewise/features/dashboard/presentation/providers/profile_provider.dart';

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

                  final token = (extra['auth_token'] ?? '').toString();
                  final patientId = (extra['auth_user_id'] ?? '').toString();

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

                  final token = (extra['auth_token'] ?? '').toString();
                  final patientId = (extra['auth_user_id'] ?? '').toString();

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
            builder: (context, state) => const _PatientDashboardRoute(),
            routes: [
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

class _PatientDashboardRoute extends ConsumerWidget {
  const _PatientDashboardRoute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(patientProfileProvider);
    final authMeAsync = ref.watch(authMeProvider);

    return profileAsync.when(
      data: (patientProfile) {
        final authMe = authMeAsync.valueOrNull;
        final patient = patient_ui.PatientProfile(
          id: patientProfile.patientId,
          firstName: patientProfile.firstName.isNotEmpty
              ? patientProfile.firstName
              : authMe?.firstName ?? '',
          lastName: patientProfile.lastName.isNotEmpty
              ? patientProfile.lastName
              : authMe?.lastName ?? '',
          sex: patientProfile.sex.isEmpty ? null : patientProfile.sex,
          dateOfBirth:
              patientProfile.dateOfBirth?.toIso8601String().split('T').first,
          phone: null,
          email: patientProfile.email.isNotEmpty
              ? patientProfile.email
              : authMe?.email,
        );

        const periods = [
          patient_ui.TimePeriodOption(id: '7d', label: '7 Hari'),
          patient_ui.TimePeriodOption(id: '30d', label: '30 Hari'),
          patient_ui.TimePeriodOption(id: '90d', label: '90 Hari'),
        ];

        final data = patient_ui.PatientDashboardData(
          patient: patient,
          periods: periods,
          selectedPeriod: periods.first,
          avatarUrl: authMe?.avatarPhoto,
          heartRatePoints: _buildDummyHeartRatePoints(),
          bloodPressurePoints: _buildDummyBloodPressurePoints(),
          spo2Points: _buildDummySpo2Points(),
          weightPoints: _buildDummyWeightPoints(),
          bmiPoints: _buildDummyBmiPoints(),
          latestHeightCm: double.tryParse(patientProfile.bodyHeightCm) ?? 0,
          heartRateThreshold: const patient_ui.HeartRateThreshold(
            normalMin: 60,
            normalMax: 100,
          ),
          bloodPressureThreshold: const patient_ui.BloodPressureThreshold(
            normalSystolicMax: 120,
            normalDiastolicMax: 80,
            elevatedSystolicMin: 120,
            elevatedSystolicMax: 129,
            elevatedDiastolicMax: 80,
            stage1SystolicMin: 130,
            stage1SystolicMax: 139,
            stage1DiastolicMin: 80,
            stage1DiastolicMax: 89,
            stage2SystolicMin: 140,
            stage2DiastolicMin: 90,
          ),
          spo2Threshold: const patient_ui.Spo2Threshold(
            criticalThreshold: 90,
            cautionThreshold: 95,
          ),
          weightThreshold: const patient_ui.WeightThreshold(
            dailyIncreaseCriticalKg: 2,
          ),
        );

        return patient_ui.PatientDashboardPage(data: data);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

List<patient_ui.ChartPoint> _buildDummyHeartRatePoints() {
  final now = DateTime.now();
  return List.generate(7, (index) {
    final offset = 6 - index;
    return patient_ui.ChartPoint(
      timestamp: DateTime(now.year, now.month, now.day - offset),
      value: (72 + (index.isEven ? index * 2 : -index)).toDouble(),
    );
  });
}

List<patient_ui.BloodPressurePoint> _buildDummyBloodPressurePoints() {
  final now = DateTime.now();
  return List.generate(7, (index) {
    final offset = 6 - index;
    return patient_ui.BloodPressurePoint(
      timestamp: DateTime(now.year, now.month, now.day - offset),
      systolic: 116 + (index * 2),
      diastolic: 76 + (index % 3),
    );
  });
}

List<patient_ui.ChartPoint> _buildDummySpo2Points() {
  final now = DateTime.now();
  return List.generate(7, (index) {
    final offset = 6 - index;
    return patient_ui.ChartPoint(
      timestamp: DateTime(now.year, now.month, now.day - offset),
      value: (97 - (index % 4)).toDouble(),
    );
  });
}

List<patient_ui.ChartPoint> _buildDummyWeightPoints() {
  final now = DateTime.now();
  return List.generate(7, (index) {
    final offset = 6 - index;
    return patient_ui.ChartPoint(
      timestamp: DateTime(now.year, now.month, now.day - offset),
      value: 68.0 + (index * 0.2),
    );
  });
}

List<patient_ui.ChartPoint> _buildDummyBmiPoints() {
  final now = DateTime.now();
  return List.generate(7, (index) {
    final offset = 6 - index;
    return patient_ui.ChartPoint(
      timestamp: DateTime(now.year, now.month, now.day - offset),
      value: 23.1 + (index * 0.05),
    );
  });
}
