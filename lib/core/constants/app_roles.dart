class AppRoles {
  AppRoles._();

  static const patient = 'patient';
  static const doctor = 'doctor';
  static const admin = 'admin';
}

class AppAuthNextSteps {
  AppAuthNextSteps._();

  static const home = 'HOME';
  static const completeRegistration = 'COMPLETE_REGISTRATION';
  static const verifyOtp = 'VERIFY_OTP';
  static const waitAdminVerification = 'WAIT_ADMIN_VERIFICATION';
}

class AppAccountStatuses {
  AppAccountStatuses._();

  static const pendingAdminVerification = 'pending_admin_verification';
}

const doctorPendingVerificationRoute = '/doctor/wait-admin-verification';
const releaseUnsupportedRoleMessage =
    'Versi aplikasi ini hanya mendukung akun pengguna umum. Akses selain pengguna umum belum tersedia di rilis ini.';

String normalizeAppRole(String? role) {
  switch ((role ?? '').trim().toLowerCase()) {
    case AppRoles.admin:
      return AppRoles.admin;
    case AppRoles.doctor:
      return AppRoles.doctor;
    case AppRoles.patient:
    default:
      return AppRoles.patient;
  }
}

bool isPatientRole(String? role) {
  return normalizeAppRole(role) == AppRoles.patient;
}

bool isDoctorRole(String? role) {
  return normalizeAppRole(role) == AppRoles.doctor;
}

bool isAdminRole(String? role) {
  return normalizeAppRole(role) == AppRoles.admin;
}

bool isReleaseSupportedRole(String? role) {
  return isPatientRole(role);
}

String normalizeAuthNextStep(String? nextStep) {
  return (nextStep ?? '').trim().toUpperCase();
}

String normalizeAccountStatus(String? accountStatus) {
  return (accountStatus ?? '').trim().toLowerCase();
}

bool isDoctorPendingAdminVerification({
  String? role,
  String? nextStep,
  String? accountStatus,
}) {
  if (!isDoctorRole(role)) return false;

  return normalizeAuthNextStep(nextStep) ==
          AppAuthNextSteps.waitAdminVerification ||
      normalizeAccountStatus(accountStatus) ==
          AppAccountStatuses.pendingAdminVerification;
}

String homeRouteForRole(String? role) {
  return isReleaseSupportedRole(role) ? '/home' : '/login';
}

String routeForRoleSession({
  String? role,
  String? nextStep,
  String? accountStatus,
}) {
  if (!isReleaseSupportedRole(role)) {
    return '/login';
  }

  if (isDoctorPendingAdminVerification(
    role: role,
    nextStep: nextStep,
    accountStatus: accountStatus,
  )) {
    return '/login';
  }

  return homeRouteForRole(role);
}
