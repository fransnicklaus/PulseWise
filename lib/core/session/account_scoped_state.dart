import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/platform/health_connect_visibility.dart';
import 'package:pulsewise/features/dashboard_shell/presentation/providers/dashboard_provider.dart';
import 'package:pulsewise/features/diary/presentation/providers/current_diary_provider.dart';
import 'package:pulsewise/features/diary/presentation/providers/diary_history_provider.dart';
import 'package:pulsewise/features/doctor/presentation/providers/doctor_patients_provider.dart';
import 'package:pulsewise/features/doctor/presentation/providers/doctor_profile_provider.dart';
import 'package:pulsewise/features/doctor/presentation/providers/doctor_recommendation_history_provider.dart';
import 'package:pulsewise/features/doctor_shell/presentation/providers/doctor_dashboard_provider.dart';
import 'package:pulsewise/features/emergency_contacts/presentation/providers/emergency_contacts_provider.dart';
import 'package:pulsewise/features/home_dashboard/presentation/providers/dashboard_overview_provider.dart';
import 'package:pulsewise/features/medication/presentation/providers/medication_calendar_provider.dart';
import 'package:pulsewise/features/ml_recommendation/presentation/providers/ml_recommendation_provider.dart';
import 'package:pulsewise/features/ml_recommendation/presentation/providers/recommendation_history_provider.dart';
import 'package:pulsewise/features/profile/presentation/providers/profile_provider.dart';

void resetAccountScopedProviderState(WidgetRef ref) {
  ref.invalidate(authMeProvider);
  ref.invalidate(patientProfileProvider);
  ref.invalidate(quickDashboardProvider);
  ref.invalidate(dashboardVitalsProvider);
  ref.invalidate(latestMlRecommendationProvider);
  ref.invalidate(currentDiaryProvider);
  ref.invalidate(diaryHistoryProvider);
  ref.invalidate(emergencyContactsProvider);
  ref.invalidate(medicationCalendarRangeProvider);
  ref.invalidate(recommendationHistoryNotifierProvider);
  ref.invalidate(doctorProfileProvider);
  ref.invalidate(doctorProfileNotifierProvider);
  ref.invalidate(doctorPatientsNotifierProvider);
  ref.invalidate(doctorRecommendationHistoryNotifierProvider);
}

void prepareAppForAuthenticatedSession(
  WidgetRef ref, {
  required bool armHealthConnectPrompt,
}) {
  resetAccountScopedProviderState(ref);
  ref.read(previousNavIndexProvider.notifier).state = 0;
  ref.read(dashboardNavIndexProvider.notifier).state = 0;
  ref.read(pendingDiarySectionProvider.notifier).state = null;
  ref.read(pendingDiaryToastMessageProvider.notifier).state = null;
  ref.read(doctorDashboardNavIndexProvider.notifier).state = 0;
  ref.read(healthConnectLoginPromptArmedProvider.notifier).state =
      armHealthConnectPrompt && shouldExposeHealthConnectUi;
}
