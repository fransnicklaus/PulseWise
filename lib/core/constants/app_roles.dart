class AppRoles {
  AppRoles._();

  static const patient = 'patient';
  static const doctor = 'doctor';
  static const admin = 'admin';
}

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

String homeRouteForRole(String? role) {
  switch (normalizeAppRole(role)) {
    case AppRoles.doctor:
      return '/doctor/home';
    case AppRoles.admin:
      return '/admin/home';
    case AppRoles.patient:
    default:
      return '/home';
  }
}
