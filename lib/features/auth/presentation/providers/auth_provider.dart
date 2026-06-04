import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pulsewise/core/constants/app_roles.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/core/notifications/fcm_service.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

const _fallbackGoogleClientId =
    '1087013148919-bc7n421oeuf5tj3brf7vlg1cgedo7qh1.apps.googleusercontent.com';
const _googleSignInScopes = <String>['email', 'profile'];

String _firstNonEmptyValue(
  List<String?> values, {
  required String fallback,
}) {
  for (final value in values) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return fallback;
}

String resolveGoogleWebClientId() {
  return _firstNonEmptyValue(
    [
      dotenv.env['GOOGLE_WEB_CLIENT_ID'],
      dotenv.env['GOOGLE_CLIENT_ID'],
    ],
    fallback: _fallbackGoogleClientId,
  );
}

bool _shouldUsePlayStoreGoogleClientId() {
  return !kIsWeb &&
      kReleaseMode &&
      defaultTargetPlatform == TargetPlatform.android;
}

String resolveGoogleServerClientId() {
  if (_shouldUsePlayStoreGoogleClientId()) {
    return _firstNonEmptyValue(
      [
        dotenv.env['GOOGLE_WEB_CLIENT_ID_PLAY_STORE'],
        dotenv.env['GOOGLE_SERVER_CLIENT_ID_PLAY_STORE'],
        dotenv.env['GOOGLE_SERVER_CLIENT_ID'],
        dotenv.env['GOOGLE_CLIENT_ID'],
        dotenv.env['GOOGLE_WEB_CLIENT_ID'],
      ],
      fallback: _fallbackGoogleClientId,
    );
  }

  return _firstNonEmptyValue(
    [
      dotenv.env['GOOGLE_SERVER_CLIENT_ID'],
      dotenv.env['GOOGLE_CLIENT_ID'],
      dotenv.env['GOOGLE_WEB_CLIENT_ID'],
    ],
    fallback: _fallbackGoogleClientId,
  );
}

GoogleSignIn buildGoogleSignInClient() {
  return GoogleSignIn(
    clientId: kIsWeb ? resolveGoogleWebClientId() : null,
    serverClientId: kIsWeb ? null : resolveGoogleServerClientId(),
    scopes: _googleSignInScopes,
  );
}

enum GoogleAuthNextStep {
  home,
  completeRegistration,
  verifyOtp,
  waitAdminVerification,
  unknown,
}

class GoogleAuthFlowResult {
  final bool success;
  final String? message;
  final GoogleAuthNextStep nextStep;
  final String? token;
  final String? userId;
  final String? email;
  final String? registrationToken;
  final String role;
  final String? idToken;
  final String? firstName;
  final String? lastName;
  final String? avatarPhoto;
  final String? accountStatus;
  final bool restrictedAccess;

  const GoogleAuthFlowResult({
    required this.success,
    required this.nextStep,
    this.message,
    this.token,
    this.userId,
    this.email,
    this.registrationToken,
    this.role = 'patient',
    this.idToken,
    this.firstName,
    this.lastName,
    this.avatarPhoto,
    this.accountStatus,
    this.restrictedAccess = false,
  });

  factory GoogleAuthFlowResult.error(String message) {
    return GoogleAuthFlowResult(
      success: false,
      nextStep: GoogleAuthNextStep.unknown,
      message: message,
    );
  }
}

class AuthState {
  final bool isLoading;
  final String? error;
  final String? token;
  final String? userId;
  final String role;
  final String? nextStep;
  final String? accountStatus;
  final bool restrictedAccess;
  final bool isAuthenticated;

  AuthState({
    this.isLoading = false,
    this.error,
    this.token,
    this.userId,
    this.role = AppRoles.patient,
    this.nextStep,
    this.accountStatus,
    this.restrictedAccess = false,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    String? token,
    String? userId,
    String? role,
    String? nextStep,
    String? accountStatus,
    bool? restrictedAccess,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      token: token ?? this.token,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      nextStep: nextStep,
      accountStatus: accountStatus,
      restrictedAccess: restrictedAccess ?? this.restrictedAccess,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

  static const _androidApplicationId = 'com.rdib.pulsewise';
  static const _debugSha1 =
      '4B:C9:64:28:E0:0A:1F:90:6E:94:20:D9:F5:5B:2C:F2:18:09:FE:35';

  void _logGoogle(String message) {
    if (!kDebugMode) return;
    debugPrint('[Auth][Google] $message');
  }

  String _maskToken(String value) {
    if (value.length <= 12) {
      return '${value.substring(0, value.length > 4 ? 4 : value.length)}...';
    }
    return '${value.substring(0, 6)}...${value.substring(value.length - 4)}';
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final baseUrl = resolveApiBaseUrl();

      final dio = _buildDio(baseUrl);

      final response = await dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final responseData = response.data ?? <String, dynamic>{};
      final token = _extractToken(responseData);
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan pada respons login');
      }
      final userId = _extractUserId(responseData);
      final role = _extractRole(responseData);
      final nextStep = _extractNextStep(responseData);
      final accountStatus = _extractAccountStatus(responseData);
      final restrictedAccess = _extractRestrictedAccess(responseData);

      await AppSessionStore.saveSession(
        token: token,
        userId: userId,
        role: role,
        nextStep: nextStep,
        accountStatus: accountStatus,
      );
      await _syncFcmTokenForCurrentSession('login');

      state = state.copyWith(
        isLoading: false,
        error: null,
        token: token,
        userId: userId,
        role: role,
        nextStep: nextStep,
        accountStatus: accountStatus,
        restrictedAccess: restrictedAccess,
        isAuthenticated:
            normalizeAuthNextStep(nextStep) == AppAuthNextSteps.home,
      );
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      state = state.copyWith(
        isLoading: false,
        error: message,
        nextStep: null,
        accountStatus: null,
        restrictedAccess: false,
        isAuthenticated: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        nextStep: null,
        accountStatus: null,
        restrictedAccess: false,
        isAuthenticated: false,
      );
    }
  }

  Future<GoogleAuthFlowResult> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    _logGoogle('Login flow started');
    try {
      final googleSignIn = buildGoogleSignInClient();
      if (kIsWeb) {
        _logGoogle(
          'Resolved web clientId=${_maskToken(resolveGoogleWebClientId())}',
        );
      } else {
        _logGoogle(
          'Resolved serverClientId=${_maskToken(resolveGoogleServerClientId())}'
          ' source=${_shouldUsePlayStoreGoogleClientId() ? 'play_store_release' : 'default'}',
        );
      }

      // Force account chooser so user can switch account every login attempt.
      try {
        await googleSignIn.disconnect();
        _logGoogle('Disconnected previous Google session');
      } catch (_) {
        await googleSignIn.signOut();
        _logGoogle('No prior grant to disconnect, fallback signOut done');
      }

      _logGoogle('Trying interactive signIn with account chooser');
      final googleUser = await googleSignIn.signIn();
      _logGoogle(
          'Interactive signIn result user=${googleUser?.email ?? 'null'}');

      if (googleUser == null) {
        _logGoogle('Login cancelled by user');
        throw Exception('Login Google dibatalkan');
      }

      _logGoogle('Fetching Google authentication tokens');
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      _logGoogle('idToken available=${idToken != null && idToken.isNotEmpty}');
      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'idToken Google tidak tersedia. Pastikan OAuth client sudah dikonfigurasi.',
        );
      }

      final flowResult = await _completeGoogleAuthWithIdToken(idToken);

      return flowResult;
    } on PlatformException catch (e, st) {
      _logGoogle('PlatformException code=${e.code} message=${e.message}');
      _logGoogle('StackTrace: $st');
      final isApi10 = e.code == 'sign_in_failed' &&
          (e.message ?? '').contains('ApiException: 10');
      final errorMessage = isApi10
          ? 'Google Sign-In gagal (ApiException 10). Cek konfigurasi OAuth Android: applicationId=$_androidApplicationId, SHA1 debug=$_debugSha1, dan pastikan OAuth Android client + Web client ID sudah benar di Google Cloud Console.'
          : e.message ?? e.toString();
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
        accountStatus: null,
        restrictedAccess: false,
        isAuthenticated: false,
      );
      return GoogleAuthFlowResult.error(errorMessage);
    } on DioException catch (e, st) {
      _logGoogle(
        'DioException status=${e.response?.statusCode} message=${e.message} data=${e.response?.data}',
      );
      _logGoogle('StackTrace: $st');
      final message = _extractErrorMessage(e);
      state = state.copyWith(
        isLoading: false,
        error: message,
        accountStatus: null,
        restrictedAccess: false,
        isAuthenticated: false,
      );
      return GoogleAuthFlowResult.error(message);
    } catch (e, st) {
      _logGoogle('Exception: $e');
      _logGoogle('StackTrace: $st');
      final message = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        isLoading: false,
        error: message,
        accountStatus: null,
        restrictedAccess: false,
        isAuthenticated: false,
      );
      return GoogleAuthFlowResult.error(message);
    }
  }

  Future<GoogleAuthFlowResult> loginWithGoogleIdToken(String idToken) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      return await _completeGoogleAuthWithIdToken(idToken);
    } on DioException catch (e, st) {
      _logGoogle(
        'DioException status=${e.response?.statusCode} message=${e.message} data=${e.response?.data}',
      );
      _logGoogle('StackTrace: $st');
      final message = _extractErrorMessage(e);
      state = state.copyWith(
        isLoading: false,
        error: message,
        accountStatus: null,
        restrictedAccess: false,
        isAuthenticated: false,
      );
      return GoogleAuthFlowResult.error(message);
    } catch (e, st) {
      _logGoogle('Exception: $e');
      _logGoogle('StackTrace: $st');
      final message = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        isLoading: false,
        error: message,
        accountStatus: null,
        restrictedAccess: false,
        isAuthenticated: false,
      );
      return GoogleAuthFlowResult.error(message);
    }
  }

  Future<GoogleAuthFlowResult> completeGoogleRegistration({
    required String registrationToken,
    required String username,
    String? firstName,
    String? lastName,
    String role = 'patient',
    required String idToken,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final baseUrl = resolveApiBaseUrl();

      final dio = _buildDio(baseUrl);
      final response = await dio.post<Map<String, dynamic>>(
        '/auth/oauth/google/register',
        data: {
          'registrationToken': registrationToken,
          'username': username,
          'firstName': firstName,
          'lastName': lastName,
          'role': role,
        },
      );

      final body = response.data ?? <String, dynamic>{};
      if (body['success'] != true) {
        throw Exception(
          (body['message'] ?? 'Registrasi Google gagal dilanjutkan').toString(),
        );
      }

      final data = (body['data'] as Map<String, dynamic>?) ?? const {};
      final nextStep =
          _parseGoogleNextStep((data['nextStep'] ?? '').toString());
      final email = (data['email'] ?? '').toString();

      if (nextStep != GoogleAuthNextStep.verifyOtp) {
        throw Exception(
          'Respons registrasi Google tidak valid. nextStep=${data['nextStep']}',
        );
      }

      state = state.copyWith(
        isLoading: false,
        error: null,
        nextStep: null,
        accountStatus: null,
        restrictedAccess: false,
        isAuthenticated: false,
      );
      return GoogleAuthFlowResult(
        success: true,
        nextStep: GoogleAuthNextStep.verifyOtp,
        message: (body['message'] ?? '').toString(),
        email: email,
        role: role,
        idToken: idToken,
      );
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      state = state.copyWith(
        isLoading: false,
        error: message,
        nextStep: null,
        accountStatus: null,
        restrictedAccess: false,
        isAuthenticated: false,
      );
      return GoogleAuthFlowResult.error(message);
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        isLoading: false,
        error: message,
        nextStep: null,
        accountStatus: null,
        restrictedAccess: false,
        isAuthenticated: false,
      );
      return GoogleAuthFlowResult.error(message);
    }
  }

  Future<GoogleAuthFlowResult> verifyGoogleOtpAndFinalize({
    required String email,
    required String otp,
    required String idToken,
    String role = 'patient',
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final baseUrl = resolveApiBaseUrl();

      final dio = _buildDio(baseUrl);
      final verifyResponse = await dio.post<Map<String, dynamic>>(
        '/auth/verifications/email/confirm',
        data: {
          'email': email,
          'otp': otp,
        },
      );

      final verifyBody = verifyResponse.data ?? <String, dynamic>{};
      if (verifyBody['success'] != true) {
        throw Exception(
            (verifyBody['message'] ?? 'Verifikasi OTP gagal').toString());
      }

      final flowResult =
          await _resolveGoogleNextStep(idToken: idToken, role: role);
      state = state.copyWith(
        isLoading: false,
        error: flowResult.success ? null : flowResult.message,
        token: flowResult.token,
        userId: flowResult.userId,
        role: flowResult.role,
        nextStep: _googleNextStepToRaw(flowResult.nextStep),
        accountStatus: flowResult.accountStatus,
        restrictedAccess: flowResult.restrictedAccess,
        isAuthenticated: flowResult.nextStep == GoogleAuthNextStep.home,
      );

      return flowResult;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      state = state.copyWith(
        isLoading: false,
        error: message,
        nextStep: null,
        accountStatus: null,
        restrictedAccess: false,
        isAuthenticated: false,
      );
      return GoogleAuthFlowResult.error(message);
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        isLoading: false,
        error: message,
        nextStep: null,
        accountStatus: null,
        restrictedAccess: false,
        isAuthenticated: false,
      );
      return GoogleAuthFlowResult.error(message);
    }
  }

  Future<void> resendEmailVerificationOtp(String email) async {
    final baseUrl = resolveApiBaseUrl();

    final dio = _buildDio(baseUrl);
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/verifications/email',
      data: {'email': email},
    );

    final body = response.data ?? <String, dynamic>{};
    if (body['success'] != true) {
      throw Exception(
          (body['message'] ?? 'Gagal mengirim ulang OTP').toString());
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      final baseUrl = resolveApiBaseUrl();

      final dio = _buildDio(baseUrl);

      final token = (await AppSessionStore.readToken(allowEnvFallback: false) ??
              state.token ??
              '')
          .trim();
      if (token.trim().isEmpty) {
        throw Exception('Bearer token tidak ditemukan. Silakan login ulang.');
      }

      final response = await dio.post<Map<String, dynamic>>(
        '/auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmNewPassword': confirmNewPassword,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      final body = response.data ?? <String, dynamic>{};
      if (body['success'] != true) {
        throw Exception(
            (body['message'] ?? 'Gagal mengubah kata sandi').toString());
      }

      final data = body['data'] as Map<String, dynamic>? ?? {};
      return data;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final baseUrl = resolveApiBaseUrl();

      final dio = _buildDio(baseUrl);
      final response = await dio.post<Map<String, dynamic>>(
        '/auth/forgot-password',
        data: {'email': email},
      );

      final body = response.data ?? <String, dynamic>{};
      if (body['success'] != true) {
        throw Exception((body['message'] ?? 'Gagal mengirim OTP').toString());
      }

      return (body['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<Map<String, dynamic>> verifyForgotPasswordOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final baseUrl = resolveApiBaseUrl();

      final dio = _buildDio(baseUrl);
      final response = await dio.post<Map<String, dynamic>>(
        '/auth/forgot-password/verify',
        data: {'email': email, 'otp': otp},
      );

      final body = response.data ?? <String, dynamic>{};
      if (body['success'] != true) {
        throw Exception((body['message'] ?? 'OTP tidak valid').toString());
      }

      return (body['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<Map<String, dynamic>> resetForgotPassword({
    required String resetToken,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      final baseUrl = resolveApiBaseUrl();

      final dio = _buildDio(baseUrl);
      final response = await dio.post<Map<String, dynamic>>(
        '/auth/forgot-password/reset',
        data: {
          'resetToken': resetToken,
          'newPassword': newPassword,
          'confirmNewPassword': confirmNewPassword,
        },
      );

      final body = response.data ?? <String, dynamic>{};
      if (body['success'] != true) {
        throw Exception(
            (body['message'] ?? 'Gagal mereset kata sandi').toString());
      }

      return (body['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<GoogleAuthFlowResult> _resolveGoogleNextStep({
    required String idToken,
    String? role,
  }) async {
    final baseUrl = resolveApiBaseUrl();

    final dio = _buildDio(baseUrl);
    _logGoogle('Calling backend /auth/oauth/google');
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/oauth/google',
      data: {
        'idToken': idToken,
        if ((role ?? '').trim().isNotEmpty) 'role': normalizeAppRole(role),
      },
    );
    _logGoogle('Backend response status=${response.statusCode}');

    final body = response.data ?? <String, dynamic>{};
    final success = body['success'] == true;
    if (!success) {
      throw Exception(
          (body['message'] ?? 'Autentikasi Google gagal').toString());
    }

    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    final nextStep = _parseGoogleNextStep((data['nextStep'] ?? '').toString());
    final message = (body['message'] ?? '').toString();
    final resolvedRole = _extractRole(body);
    final accountStatus = _extractAccountStatus(body);
    final restrictedAccess = _extractRestrictedAccess(body);

    if (nextStep == GoogleAuthNextStep.home) {
      final token = _extractToken(body) ?? _extractToken(data);
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan pada respons login Google');
      }

      final userId = _extractUserId(body) ?? _extractUserId(data);

      await AppSessionStore.saveSession(
        token: token,
        userId: userId,
        role: resolvedRole,
        nextStep: AppAuthNextSteps.home,
        accountStatus: accountStatus,
      );
      await _syncFcmTokenForCurrentSession('google_home');

      _logGoogle('Session saved, auth success');
      return GoogleAuthFlowResult(
        success: true,
        nextStep: GoogleAuthNextStep.home,
        message: message,
        token: token,
        userId: userId,
        role: resolvedRole,
        idToken: idToken,
        accountStatus: accountStatus,
      );
    }

    if (nextStep == GoogleAuthNextStep.waitAdminVerification) {
      final token = _extractToken(body) ?? _extractToken(data);
      if (token == null || token.isEmpty) {
        throw Exception(
          'Token tidak ditemukan pada respons verifikasi dokter Google',
        );
      }

      final userId = _extractUserId(body) ?? _extractUserId(data);
      await AppSessionStore.saveSession(
        token: token,
        userId: userId,
        role: resolvedRole,
        nextStep: AppAuthNextSteps.waitAdminVerification,
        accountStatus: accountStatus,
      );

      return GoogleAuthFlowResult(
        success: true,
        nextStep: GoogleAuthNextStep.waitAdminVerification,
        message: message,
        token: token,
        userId: userId,
        role: resolvedRole,
        idToken: idToken,
        accountStatus: accountStatus,
        restrictedAccess: restrictedAccess,
      );
    }

    if (nextStep == GoogleAuthNextStep.completeRegistration) {
      final registrationToken = (data['registrationToken'] ?? '').toString();
      if (registrationToken.isEmpty) {
        throw Exception(
            'registrationToken tidak ditemukan pada respons Google');
      }

      final googleProfile =
          (data['googleProfile'] as Map<String, dynamic>?) ?? const {};

      return GoogleAuthFlowResult(
        success: true,
        nextStep: GoogleAuthNextStep.completeRegistration,
        message: message,
        registrationToken: registrationToken,
        email: (googleProfile['email'] ?? data['email'] ?? '').toString(),
        firstName: (googleProfile['firstName'] ?? '').toString(),
        lastName: (googleProfile['lastName'] ?? '').toString(),
        avatarPhoto: (googleProfile['avatarPhoto'] ?? '').toString(),
        role: resolvedRole,
        idToken: idToken,
        accountStatus: accountStatus,
      );
    }

    if (nextStep == GoogleAuthNextStep.verifyOtp) {
      return GoogleAuthFlowResult(
        success: true,
        nextStep: GoogleAuthNextStep.verifyOtp,
        message: message,
        email: (data['email'] ?? '').toString(),
        role: resolvedRole,
        idToken: idToken,
        accountStatus: accountStatus,
      );
    }

    throw Exception('nextStep Google tidak dikenali: ${data['nextStep']}');
  }

  Future<GoogleAuthFlowResult> _completeGoogleAuthWithIdToken(
    String idToken,
  ) async {
    final flowResult = await _resolveGoogleNextStep(idToken: idToken);
    _applyGoogleFlowState(flowResult);
    return flowResult;
  }

  void _applyGoogleFlowState(GoogleAuthFlowResult flowResult) {
    state = state.copyWith(
      isLoading: false,
      error: flowResult.success ? null : flowResult.message,
      token: flowResult.token,
      userId: flowResult.userId,
      role: flowResult.role,
      nextStep: _googleNextStepToRaw(flowResult.nextStep),
      accountStatus: flowResult.accountStatus,
      restrictedAccess: flowResult.restrictedAccess,
      isAuthenticated: flowResult.nextStep == GoogleAuthNextStep.home,
    );
  }

  GoogleAuthNextStep _parseGoogleNextStep(String raw) {
    switch (raw.toUpperCase().trim()) {
      case 'HOME':
        return GoogleAuthNextStep.home;
      case 'COMPLETE_REGISTRATION':
        return GoogleAuthNextStep.completeRegistration;
      case 'VERIFY_OTP':
        return GoogleAuthNextStep.verifyOtp;
      case 'WAIT_ADMIN_VERIFICATION':
        return GoogleAuthNextStep.waitAdminVerification;
      default:
        return GoogleAuthNextStep.unknown;
    }
  }

  String? _googleNextStepToRaw(GoogleAuthNextStep nextStep) {
    switch (nextStep) {
      case GoogleAuthNextStep.home:
        return AppAuthNextSteps.home;
      case GoogleAuthNextStep.completeRegistration:
        return AppAuthNextSteps.completeRegistration;
      case GoogleAuthNextStep.verifyOtp:
        return AppAuthNextSteps.verifyOtp;
      case GoogleAuthNextStep.waitAdminVerification:
        return AppAuthNextSteps.waitAdminVerification;
      case GoogleAuthNextStep.unknown:
        return null;
    }
  }

  Dio _buildDio(String baseUrl) {
    return createApiDio(baseUrl);
  }

  Future<void> logout() async {
    try {
      await AppFcmService.instance.revokeCurrentTokenForCurrentSession(
        trigger: 'logout',
      );
    } catch (e) {
      debugPrint('[Auth][FCM] Failed to revoke token on logout: $e');
    }

    await AppSessionStore.clearSession();
    state = AuthState();
  }

  Future<void> _syncFcmTokenForCurrentSession(String trigger) async {
    try {
      await AppFcmService.instance.registerTokenForCurrentSession(
        trigger: trigger,
      );
    } catch (e) {
      debugPrint('[Auth][FCM] Failed to sync token for $trigger: $e');
    }
  }

  String? _extractToken(Map<String, dynamic> json) {
    const tokenKeys = [
      'access_token',
      'token',
      'jwt',
      'bearerToken',
      'bearer_token',
    ];

    for (final key in tokenKeys) {
      final value = json[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }

    final data = json['data'];
    if (data is Map<String, dynamic>) {
      for (final key in tokenKeys) {
        final value = data[key];
        if (value is String && value.isNotEmpty) {
          return value;
        }
      }
    }

    return null;
  }

  String? _extractUserId(Map<String, dynamic> json) {
    const userIdKeys = [
      'user_id',
      'userId',
      'patient_id',
      'patientId',
      'id',
    ];

    String? fromMap(Map<String, dynamic> map) {
      for (final key in userIdKeys) {
        final value = map[key];
        if (value is String && value.isNotEmpty) {
          return value;
        }
      }
      return null;
    }

    final rootId = fromMap(json);
    if (rootId != null) return rootId;

    final data = json['data'];
    if (data is Map<String, dynamic>) {
      final dataId = fromMap(data);
      if (dataId != null) return dataId;

      final user = data['user'];
      if (user is Map<String, dynamic>) {
        final userId = fromMap(user);
        if (userId != null) return userId;
      }

      final patient = data['patient'];
      if (patient is Map<String, dynamic>) {
        final patientId = fromMap(patient);
        if (patientId != null) return patientId;
      }
    }

    return null;
  }

  String _extractRole(Map<String, dynamic> json) {
    const roleKeys = ['role', 'userRole', 'user_role'];

    String? fromMap(Map<String, dynamic> map) {
      for (final key in roleKeys) {
        final value = map[key];
        if (value is String && value.trim().isNotEmpty) {
          return value;
        }
      }
      return null;
    }

    final rootRole = fromMap(json);
    if (rootRole != null) return normalizeAppRole(rootRole);

    final data = json['data'];
    if (data is Map<String, dynamic>) {
      final dataRole = fromMap(data);
      if (dataRole != null) return normalizeAppRole(dataRole);

      final user = data['user'];
      if (user is Map<String, dynamic>) {
        final userRole = fromMap(user);
        if (userRole != null) return normalizeAppRole(userRole);
      }
    }

    return AppRoles.patient;
  }

  String? _extractNextStep(Map<String, dynamic> json) {
    String? fromMap(Map<String, dynamic> map) {
      final value = map['nextStep'] ?? map['next_step'];
      if (value is String && value.trim().isNotEmpty) {
        return normalizeAuthNextStep(value);
      }
      return null;
    }

    final rootNextStep = fromMap(json);
    if (rootNextStep != null) return rootNextStep;

    final data = json['data'];
    if (data is Map<String, dynamic>) {
      final dataNextStep = fromMap(data);
      if (dataNextStep != null) return dataNextStep;
    }

    return null;
  }

  String? _extractAccountStatus(Map<String, dynamic> json) {
    String? fromMap(Map<String, dynamic> map) {
      final value = map['accountStatus'] ?? map['account_status'];
      if (value is String && value.trim().isNotEmpty) {
        return normalizeAccountStatus(value);
      }
      return null;
    }

    final rootStatus = fromMap(json);
    if (rootStatus != null) return rootStatus;

    final data = json['data'];
    if (data is Map<String, dynamic>) {
      final dataStatus = fromMap(data);
      if (dataStatus != null) return dataStatus;

      final user = data['user'];
      if (user is Map<String, dynamic>) {
        final userStatus = fromMap(user);
        if (userStatus != null) return userStatus;
      }
    }

    return null;
  }

  bool _extractRestrictedAccess(Map<String, dynamic> json) {
    bool? fromMap(Map<String, dynamic> map) {
      final value = map['restrictedAccess'] ?? map['restricted_access'];
      if (value is bool) {
        return value;
      }
      return null;
    }

    final rootRestricted = fromMap(json);
    if (rootRestricted != null) return rootRestricted;

    final data = json['data'];
    if (data is Map<String, dynamic>) {
      final dataRestricted = fromMap(data);
      if (dataRestricted != null) return dataRestricted;
    }

    return false;
  }

  String _extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }

    return 'Login gagal. Periksa email dan kata sandi.';
  }
}
