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

  static bool get canRunPatientAuthFlow =>
      canTouchBackend && hasPatientCredentials;
}
