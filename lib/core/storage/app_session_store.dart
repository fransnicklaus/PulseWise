import 'package:pulsewise/core/constants/app_roles.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSession {
  const AppSession({
    this.token,
    this.userId,
    this.role,
    this.nextStep,
    this.accountStatus,
  });

  final String? token;
  final String? userId;
  final String? role;
  final String? nextStep;
  final String? accountStatus;

  bool get hasValidSession =>
      (token ?? '').trim().isNotEmpty && (userId ?? '').trim().isNotEmpty;
}

class AppSessionStore {
  AppSessionStore._();

  static const tokenPrefsKey = 'auth_token';
  static const userIdPrefsKey = 'auth_user_id';
  static const rolePrefsKey = 'auth_role';
  static const nextStepPrefsKey = 'auth_next_step';
  static const accountStatusPrefsKey = 'auth_account_status';

  static Future<AppSession> readSession({
    bool allowEnvFallback = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = _normalizeValue(
      prefs.getString(tokenPrefsKey),
      fallback: allowEnvFallback
          ? _firstNonEmpty(
              dotenv.env['AUTH_TOKEN'],
              dotenv.env['BEARER_TOKEN'],
            )
          : null,
    );
    final userId = _normalizeValue(
      prefs.getString(userIdPrefsKey),
      fallback: allowEnvFallback ? dotenv.env['PATIENT_ID'] : null,
    );
    final role = normalizeAppRole(
      _normalizeValue(
        prefs.getString(rolePrefsKey),
        fallback: allowEnvFallback
            ? _firstNonEmpty(
                dotenv.env['AUTH_ROLE'],
                dotenv.env['USER_ROLE'],
              )
            : null,
      ),
    );
    final nextStep = _normalizeValue(
      prefs.getString(nextStepPrefsKey),
      fallback: allowEnvFallback ? dotenv.env['AUTH_NEXT_STEP'] : null,
    );
    final accountStatus = _normalizeValue(
      prefs.getString(accountStatusPrefsKey),
      fallback: allowEnvFallback ? dotenv.env['AUTH_ACCOUNT_STATUS'] : null,
    );

    return AppSession(
      token: token,
      userId: userId,
      role: role,
      nextStep: nextStep,
      accountStatus: accountStatus,
    );
  }

  static Future<String?> readToken({
    bool allowEnvFallback = true,
  }) async {
    return (await readSession(allowEnvFallback: allowEnvFallback)).token;
  }

  static Future<String?> readUserId({
    bool allowEnvFallback = true,
  }) async {
    return (await readSession(allowEnvFallback: allowEnvFallback)).userId;
  }

  static Future<String?> readRole({
    bool allowEnvFallback = true,
  }) async {
    return (await readSession(allowEnvFallback: allowEnvFallback)).role;
  }

  static Future<String?> readNextStep({
    bool allowEnvFallback = true,
  }) async {
    return (await readSession(allowEnvFallback: allowEnvFallback)).nextStep;
  }

  static Future<String?> readAccountStatus({
    bool allowEnvFallback = true,
  }) async {
    return (await readSession(allowEnvFallback: allowEnvFallback))
        .accountStatus;
  }

  static Future<String> requireToken({
    bool allowEnvFallback = true,
    String missingMessage =
        'Bearer token tidak ditemukan. Silakan login ulang.',
  }) async {
    final token = await readToken(allowEnvFallback: allowEnvFallback);
    if ((token ?? '').trim().isEmpty) {
      throw Exception(missingMessage);
    }
    return token!;
  }

  static Future<String> requireUserId({
    bool allowEnvFallback = true,
    String missingMessage = 'userId tidak ditemukan. Silakan login ulang.',
  }) async {
    final userId = await readUserId(allowEnvFallback: allowEnvFallback);
    if ((userId ?? '').trim().isEmpty) {
      throw Exception(missingMessage);
    }
    return userId!;
  }

  static Future<void> saveSession({
    required String token,
    String? userId,
    String? role,
    String? nextStep,
    String? accountStatus,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenPrefsKey, token);

    final normalizedUserId = _normalizeValue(userId);
    if (normalizedUserId == null) {
      await prefs.remove(userIdPrefsKey);
      await prefs.remove(rolePrefsKey);
      await prefs.remove(nextStepPrefsKey);
      await prefs.remove(accountStatusPrefsKey);
      return;
    }

    await prefs.setString(userIdPrefsKey, normalizedUserId);
    await prefs.setString(rolePrefsKey, normalizeAppRole(role));

    final normalizedNextStep = _normalizeValue(nextStep);
    if (normalizedNextStep == null) {
      await prefs.remove(nextStepPrefsKey);
    } else {
      await prefs.setString(nextStepPrefsKey, normalizedNextStep);
    }

    final normalizedAccountStatus = _normalizeValue(accountStatus);
    if (normalizedAccountStatus == null) {
      await prefs.remove(accountStatusPrefsKey);
    } else {
      await prefs.setString(accountStatusPrefsKey, normalizedAccountStatus);
    }
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenPrefsKey);
    await prefs.remove(userIdPrefsKey);
    await prefs.remove(rolePrefsKey);
    await prefs.remove(nextStepPrefsKey);
    await prefs.remove(accountStatusPrefsKey);
  }

  static String? _normalizeValue(String? value, {String? fallback}) {
    final normalized = value?.trim() ?? '';
    if (normalized.isNotEmpty) return normalized;

    final normalizedFallback = fallback?.trim() ?? '';
    if (normalizedFallback.isNotEmpty) return normalizedFallback;

    return null;
  }

  static String? _firstNonEmpty(String? first, String? second) {
    final normalizedFirst = first?.trim() ?? '';
    if (normalizedFirst.isNotEmpty) return normalizedFirst;

    final normalizedSecond = second?.trim() ?? '';
    if (normalizedSecond.isNotEmpty) return normalizedSecond;

    return null;
  }
}
