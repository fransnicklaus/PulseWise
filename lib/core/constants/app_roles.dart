class AppRoles {
  AppRoles._();

  static const patient = 'patient';
  static const doctor = 'doctor';
}

String normalizeAppRole(String? role) {
  switch ((role ?? '').trim().toLowerCase()) {
    case AppRoles.doctor:
      return AppRoles.doctor;
    case AppRoles.patient:
    default:
      return AppRoles.patient;
  }
}

bool isDoctorRole(String? role) {
  return normalizeAppRole(role) == AppRoles.doctor;
}

String homeRouteForRole(String? role) {
  return isDoctorRole(role) ? '/doctor/home' : '/home';
}
