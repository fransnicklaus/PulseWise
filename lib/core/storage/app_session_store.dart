import 'package:pulsewise/core/constants/app_roles.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSession {
  const AppSession({
    this.token,
    this.userId,
    this.role,
  });

  final String? token;
  final String? userId;
  final String? role;

  bool get hasValidSession =>
      (token ?? '').trim().isNotEmpty && (userId ?? '').trim().isNotEmpty;
}

class AppSessionStore {
  AppSessionStore._();

  static const tokenPrefsKey = 'auth_token';
  static const userIdPrefsKey = 'auth_user_id';
  static const rolePrefsKey = 'auth_role';

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

    return AppSession(token: token, userId: userId, role: role);
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
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenPrefsKey, token);

    final normalizedUserId = _normalizeValue(userId);
    if (normalizedUserId == null) {
      await prefs.remove(userIdPrefsKey);
      await prefs.remove(rolePrefsKey);
      return;
    }

    await prefs.setString(userIdPrefsKey, normalizedUserId);
    await prefs.setString(rolePrefsKey, normalizeAppRole(role));
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenPrefsKey);
    await prefs.remove(userIdPrefsKey);
    await prefs.remove(rolePrefsKey);
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
