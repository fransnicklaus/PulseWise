class E2eTestConfig {
  E2eTestConfig._();

  static const bool runBackendTests = bool.fromEnvironment(
    'E2E_RUN_BACKEND_TESTS',
    defaultValue: false,
  );

  static const bool allowDefaultApi = bool.fromEnvironment(
    'E2E_ALLOW_DEFAULT_API',
    defaultValue: false,
  );

  static const String configuredApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String patientEmail = String.fromEnvironment(
    'E2E_PATIENT_EMAIL',
    defaultValue: '',
  );

  static const String patientPassword = String.fromEnvironment(
    'E2E_PATIENT_PASSWORD',
    defaultValue: '',
  );

  static const String doctorEmail = String.fromEnvironment(
    'E2E_DOCTOR_EMAIL',
    defaultValue: '',
  );

  static const String doctorPassword = String.fromEnvironment(
    'E2E_DOCTOR_PASSWORD',
    defaultValue: '',
  );

  static const String adminEmail = String.fromEnvironment(
    'E2E_ADMIN_EMAIL',
    defaultValue: '',
  );

  static const String adminPassword = String.fromEnvironment(
    'E2E_ADMIN_PASSWORD',
    defaultValue: '',
  );

  static const String invalidEmail = String.fromEnvironment(
    'E2E_INVALID_EMAIL',
    defaultValue: 'invalid.e2e@example.test',
  );

  static const String invalidPassword = String.fromEnvironment(
    'E2E_INVALID_PASSWORD',
    defaultValue: 'wrong-password-123',
  );

  static bool get hasConfiguredApiBaseUrl =>
      configuredApiBaseUrl.trim().isNotEmpty;

  static bool get canTouchBackend =>
      runBackendTests && (hasConfiguredApiBaseUrl || allowDefaultApi);

  static bool get hasPatientCredentials =>
      patientEmail.trim().isNotEmpty && patientPassword.trim().isNotEmpty;

  static bool get hasDoctorCredentials =>
      doctorEmail.trim().isNotEmpty && doctorPassword.trim().isNotEmpty;

  static bool get hasAdminCredentials =>
      adminEmail.trim().isNotEmpty && adminPassword.trim().isNotEmpty;

  static bool get canRunPatientAuthFlow =>
      canTouchBackend && hasPatientCredentials;

  static bool get canRunDoctorAuthFlow =>
      canTouchBackend && hasDoctorCredentials;

  static bool get canRunAdminAuthFlow => canTouchBackend && hasAdminCredentials;
}
