import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/network/api_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final bool isLoading;
  final String? error;
  final String? token;
  final String? userId;
  final bool isAuthenticated;

  AuthState({
    this.isLoading = false,
    this.error,
    this.token,
    this.userId,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    String? token,
    String? userId,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      token: token ?? this.token,
      userId: userId ?? this.userId,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'auth_user_id';

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
      if (baseUrl.isEmpty) {
        throw Exception('API_BASE_URL belum diatur di file .env');
      }

      final dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          headers: const {'Accept': 'application/json'},
        ),
      );
      ApiLogger.attach(dio);

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

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      if (userId != null && userId.isNotEmpty) {
        await prefs.setString(_userIdKey, userId);
      }

      state = state.copyWith(
        isLoading: false,
        error: null,
        token: token,
        userId: userId,
        isAuthenticated: true,
      );
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      state = state.copyWith(
        isLoading: false,
        error: message,
        isAuthenticated: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isAuthenticated: false,
      );
    }
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Mock google login delay
      await Future.delayed(const Duration(seconds: 2));
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    state = AuthState();
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
