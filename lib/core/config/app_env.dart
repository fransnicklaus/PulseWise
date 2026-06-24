class AppEnv {
  AppEnv._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://pulsewise-api.algoritme.tech',
  );

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '1087013148919-gv3qj9k0se9hj4ptbilei9ro1hfv5h41.apps.googleusercontent.com',
  );

  static const String googleWebClientIdPlayStore = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID_PLAY_STORE',
    defaultValue:
        '1087013148919-bc7n421oeuf5tj3brf7vlg1cgedo7qh1.apps.googleusercontent.com',
  );

  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue:
        '1087013148919-gv3qj9k0se9hj4ptbilei9ro1hfv5h41.apps.googleusercontent.com',
  );

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '1087013148919-gv3qj9k0se9hj4ptbilei9ro1hfv5h41.apps.googleusercontent.com',
  );

  static const String cloudinaryFolder = String.fromEnvironment(
    'CLOUDINARY_FOLDER',
    defaultValue: 'pulsewise/avatars',
  );

  static const String authToken = String.fromEnvironment(
    'AUTH_TOKEN',
    defaultValue: '',
  );

  static const String bearerToken = String.fromEnvironment(
    'BEARER_TOKEN',
    defaultValue: '',
  );

  static const String patientId = String.fromEnvironment(
    'PATIENT_ID',
    defaultValue: '',
  );

  static const String authRole = String.fromEnvironment(
    'AUTH_ROLE',
    defaultValue: '',
  );

  static const String userRole = String.fromEnvironment(
    'USER_ROLE',
    defaultValue: '',
  );

  static const String authNextStep = String.fromEnvironment(
    'AUTH_NEXT_STEP',
    defaultValue: '',
  );

  static const String authAccountStatus = String.fromEnvironment(
    'AUTH_ACCOUNT_STATUS',
    defaultValue: '',
  );
}
