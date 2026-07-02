import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/constants/app_roles.dart';
import 'package:pulsewise/core/constants/legal_links.dart';
import 'package:pulsewise/core/network/api_dio_provider.dart';
import 'package:pulsewise/core/session/account_scoped_state.dart';
import 'package:pulsewise/core/storage/app_session_store.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:url_launcher/url_launcher.dart';

class RegisterPage extends ConsumerStatefulWidget {
  final String? googleRegistrationToken;
  final String? googleEmail;
  final String? googleIdToken;
  final String googleRole;
  final String? googleFirstName;
  final String? googleLastName;
  final bool startAtOtp;

  const RegisterPage({
    super.key,
    this.googleRegistrationToken,
    this.googleEmail,
    this.googleIdToken,
    this.googleRole = 'patient',
    this.googleFirstName,
    this.googleLastName,
    this.startAtOtp = false,
  });

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isResendingOtp = false;
  int _otpResendCooldown = 0;
  Timer? _otpCooldownTimer;
  bool _googleRegistrationCompleted = false;
  String _selectedRole = AppRoles.patient;
  bool _hasAgreedPrivacyPolicy = false;

  String? _registeredUserId;
  String _registrationEmail = '';

  bool get _isGoogleFlow {
    return (widget.googleEmail ?? '').isNotEmpty &&
        (widget.googleIdToken ?? '').isNotEmpty;
  }

  String get _registrationRole {
    return _selectedRole;
  }

  @override
  void initState() {
    super.initState();
    _selectedRole = normalizeAppRole(widget.googleRole);
    _firstNameController.text = widget.googleFirstName ?? '';
    _lastNameController.text = widget.googleLastName ?? '';

    final googleEmail = (widget.googleEmail ?? '').trim();
    if (googleEmail.isNotEmpty) {
      _emailController.text = googleEmail;
      _registrationEmail = googleEmail;
    }

    _currentStep = widget.startAtOtp ? 1 : 0;
    if (_isGoogleFlow && widget.startAtOtp) {
      _googleRegistrationCompleted = true;
    }
  }

  @override
  void dispose() {
    _otpCooldownTimer?.cancel();
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Dio _buildDio() {
    return createApiDio(resolveApiBaseUrl());
  }

  String _extractApiError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      }
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  String _extractIdFromMap(Map<String, dynamic> map) {
    const keys = ['patientId', 'userId', 'id', 'patient_id', 'user_id'];
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  String _extractTokenFromMap(Map<String, dynamic> map) {
    const tokenKeys = [
      'access_token',
      'token',
      'jwt',
      'bearerToken',
      'bearer_token',
    ];

    for (final key in tokenKeys) {
      final value = map[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  String _extractRoleFromMap(Map<String, dynamic> map) {
    const roleKeys = ['role', 'userRole', 'user_role'];
    for (final key in roleKeys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return normalizeAppRole(value);
      }
    }
    return AppRoles.patient;
  }

  String? _extractNextStepFromMap(Map<String, dynamic> map) {
    final value = map['nextStep'] ?? map['next_step'];
    if (value is String && value.trim().isNotEmpty) {
      return normalizeAuthNextStep(value);
    }
    return null;
  }

  String? _extractAccountStatusFromMap(Map<String, dynamic> map) {
    final value = map['accountStatus'] ?? map['account_status'];
    if (value is String && value.trim().isNotEmpty) {
      return normalizeAccountStatus(value);
    }
    return null;
  }

  Future<String> _registerAndGetUserId() async {
    final dio = _buildDio();
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'username': _usernameController.text.trim(),
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'role': _registrationRole,
      },
    );

    final body = response.data ?? <String, dynamic>{};
    if (body['success'] != true) {
      throw Exception((body['message'] ?? 'Registrasi gagal').toString());
    }

    String userId = '';
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      userId = _extractIdFromMap(data);

      if (userId.isEmpty && data['patient'] is Map<String, dynamic>) {
        userId = _extractIdFromMap(data['patient'] as Map<String, dynamic>);
      }

      if (userId.isEmpty && data['user'] is Map<String, dynamic>) {
        userId = _extractIdFromMap(data['user'] as Map<String, dynamic>);
      }
    }

    if (userId.isEmpty) {
      userId = _extractIdFromMap(body);
    }

    if (userId.isEmpty) {
      throw Exception('userId tidak ditemukan pada respons register');
    }

    return userId;
  }

  Future<void> _sendEmailOtp({required String email}) async {
    final dio = _buildDio();
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/verifications/email',
      data: {'email': email},
    );

    final body = response.data ?? <String, dynamic>{};
    if (body['success'] != true) {
      throw Exception((body['message'] ?? 'Gagal mengirim OTP').toString());
    }
  }

  Future<void> _confirmEmailOtp({required String email}) async {
    final dio = _buildDio();
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/verifications/email/confirm',
      data: {
        'email': email,
        'otp': _otpController.text.trim(),
      },
    );

    final body = response.data ?? <String, dynamic>{};
    if (body['success'] != true) {
      throw Exception((body['message'] ?? 'Verifikasi OTP gagal').toString());
    }
  }

  Future<_SessionData> _loginAndGetSessionData() async {
    final dio = _buildDio();
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
      },
    );

    final body = response.data ?? <String, dynamic>{};
    var token = _extractTokenFromMap(body);

    final data = body['data'];
    if (token.isEmpty && data is Map<String, dynamic>) {
      token = _extractTokenFromMap(data);
    }

    if (token.isEmpty) {
      throw Exception('Token login tidak ditemukan pada respons');
    }

    var userId = _extractIdFromMap(body);
    String role = _registrationRole;
    String? nextStep = _extractNextStepFromMap(body);
    String? accountStatus = _extractAccountStatusFromMap(body);

    if (data is Map<String, dynamic>) {
      if (userId.isEmpty) {
        userId = _extractIdFromMap(data);
      }

      role = _extractRoleFromMap(data);
      nextStep ??= _extractNextStepFromMap(data);
      accountStatus ??= _extractAccountStatusFromMap(data);

      final user = data['user'];
      if (user is Map<String, dynamic>) {
        if (userId.isEmpty) {
          userId = _extractIdFromMap(user);
        }
        role = _extractRoleFromMap(user);
        accountStatus ??= _extractAccountStatusFromMap(user);
      }
    }

    if (userId.isEmpty) {
      throw Exception('userId tidak ditemukan pada respons login');
    }

    return _SessionData(
      token: token,
      userId: userId,
      role: role,
      nextStep: nextStep,
      accountStatus: accountStatus,
    );
  }

  Future<void> _completeGoogleRegistrationAndPrepareOtp() async {
    final registrationToken = (widget.googleRegistrationToken ?? '').trim();
    if (registrationToken.isEmpty) {
      throw Exception('registrationToken Google tidak tersedia');
    }

    final dio = _buildDio();
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/oauth/google/register',
      data: {
        'registrationToken': registrationToken,
        'username': _usernameController.text.trim(),
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'role': _registrationRole,
      },
    );

    final body = response.data ?? <String, dynamic>{};
    if (body['success'] != true) {
      throw Exception(
        (body['message'] ?? 'Registrasi Google gagal dilanjutkan').toString(),
      );
    }

    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    final nextStep = (data['nextStep'] ?? '').toString().toUpperCase().trim();
    if (nextStep != 'VERIFY_OTP') {
      throw Exception('Respons Google register tidak valid: $nextStep');
    }

    final email = (data['email'] ?? widget.googleEmail ?? '').toString().trim();
    if (email.isEmpty) {
      throw Exception('Email verifikasi tidak ditemukan');
    }

    _registrationEmail = email;
    _googleRegistrationCompleted = true;
  }

  Future<_SessionData> _finalizeGoogleAndGetSession() async {
    final idToken = (widget.googleIdToken ?? '').trim();
    if (idToken.isEmpty) {
      throw Exception('idToken Google tidak tersedia');
    }

    final dio = _buildDio();
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/oauth/google',
      data: {
        'idToken': idToken,
        'role': _registrationRole,
      },
    );

    final body = response.data ?? <String, dynamic>{};
    if (body['success'] != true) {
      throw Exception(
          (body['message'] ?? 'Autentikasi Google gagal').toString());
    }

    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    final nextStep = (data['nextStep'] ?? '').toString().toUpperCase().trim();
    if (nextStep != AppAuthNextSteps.home &&
        nextStep != AppAuthNextSteps.waitAdminVerification) {
      throw Exception('Akun belum siap masuk. nextStep=$nextStep');
    }

    var token = _extractTokenFromMap(body);
    if (token.isEmpty) {
      token = _extractTokenFromMap(data);
    }
    if (token.isEmpty) {
      throw Exception('Token tidak ditemukan pada respons Google');
    }

    var userId = _extractIdFromMap(body);
    if (userId.isEmpty) {
      userId = _extractIdFromMap(data);
    }

    final user = data['user'];
    if (userId.isEmpty && user is Map<String, dynamic>) {
      userId = _extractIdFromMap(user);
    }

    final patient = data['patient'];
    if (userId.isEmpty && patient is Map<String, dynamic>) {
      userId = _extractIdFromMap(patient);
    }

    if (userId.isEmpty) {
      throw Exception('userId/patientId tidak ditemukan pada respons Google');
    }

    return _SessionData(
      token: token,
      userId: userId,
      role:
          _extractRoleFromMap((data['user'] as Map<String, dynamic>?) ?? data),
      nextStep: nextStep,
      accountStatus: _extractAccountStatusFromMap(body) ??
          _extractAccountStatusFromMap(data) ??
          _extractAccountStatusFromMap(
            (data['user'] as Map<String, dynamic>?) ?? const {},
          ),
    );
  }

  void _startOtpCooldown() {
    _otpCooldownTimer?.cancel();
    setState(() => _otpResendCooldown = 30);

    _otpCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_otpResendCooldown <= 1) {
        timer.cancel();
        setState(() => _otpResendCooldown = 0);
        return;
      }
      setState(() => _otpResendCooldown--);
    });
  }

  Future<void> _resendOtp() async {
    if (_otpResendCooldown > 0 || _isResendingOtp || _isSubmitting) return;

    final email = _registrationEmail.isNotEmpty
        ? _registrationEmail
        : _emailController.text.trim();
    if (email.isEmpty) {
      AppToast.warning(context, 'Email belum tersedia untuk kirim OTP');
      return;
    }

    setState(() => _isResendingOtp = true);
    try {
      await _sendEmailOtp(email: email);
      if (!mounted) return;
      AppToast.success(context, 'OTP baru berhasil dikirim');
      _startOtpCooldown();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, _extractApiError(e));
    } finally {
      if (mounted) {
        setState(() => _isResendingOtp = false);
      }
    }
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(privacyPolicyUrl);
    final openedExternally = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (openedExternally || !mounted) return;

    final openedInApp = await launchUrl(uri);
    if (openedInApp || !mounted) return;

    AppToast.warning(
      context,
      'Tautan kebijakan privasi tidak dapat dibuka saat ini.',
    );
  }

  Future<void> _nextStep() async {
    final canProceed = switch (_currentStep) {
      0 => _step1Key.currentState?.validate() ?? false,
      1 => _step2Key.currentState?.validate() ?? false,
      _ => false,
    };

    if (!canProceed || _isSubmitting) return;

    if (_currentStep == 0 && !_hasAgreedPrivacyPolicy) {
      AppToast.warning(
        context,
        'Anda perlu menyetujui kebijakan privasi terlebih dahulu.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (_currentStep == 0) {
        if (_isGoogleFlow) {
          if (!_googleRegistrationCompleted) {
            await _completeGoogleRegistrationAndPrepareOtp();
          }
          if (!mounted) return;
          AppToast.success(
              context, 'Registrasi Google selesai, OTP sudah dikirim');
        } else {
          final userId = await _registerAndGetUserId();
          _registeredUserId = userId;
          _registrationEmail = _emailController.text.trim();
          if (!mounted) return;
          AppToast.success(context, 'Registrasi berhasil, OTP sudah dikirim');
        }

        _startOtpCooldown();
        setState(() {
          _currentStep = 1;
          _isSubmitting = false;
        });
        return;
      }

      if (_currentStep == 1) {
        final email = _registrationEmail.isNotEmpty
            ? _registrationEmail
            : _emailController.text.trim();
        if (email.isEmpty) {
          throw Exception('Email verifikasi tidak tersedia');
        }

        await _confirmEmailOtp(email: email);

        late final _SessionData session;
        if (_isGoogleFlow) {
          session = await _finalizeGoogleAndGetSession();
        } else {
          final loginSession = await _loginAndGetSessionData();
          final registeredUserId = _registeredUserId;
          if (registeredUserId == null || registeredUserId.isEmpty) {
            throw Exception('Data akun belum terdaftar. Ulangi registrasi.');
          }
          session = _SessionData(
            token: loginSession.token,
            userId: loginSession.userId.isEmpty
                ? registeredUserId
                : loginSession.userId,
            role: loginSession.role,
            nextStep: loginSession.nextStep,
            accountStatus: loginSession.accountStatus,
          );
        }

        if (!mounted) return;
        setState(() => _isSubmitting = false);

        if (normalizeAppRole(session.role) == AppRoles.doctor) {
          await AppSessionStore.saveSession(
            token: session.token,
            userId: session.userId,
            role: session.role,
            nextStep: session.nextStep,
            accountStatus: session.accountStatus,
          );
          prepareAppForAuthenticatedSession(
            ref,
            armHealthConnectPrompt: false,
          );
          if (!mounted) return;
          if (isDoctorPendingAdminVerification(
            role: session.role,
            nextStep: session.nextStep,
            accountStatus: session.accountStatus,
          )) {
            AppToast.info(
              context,
              'Email dokter berhasil diverifikasi. Lengkapi profil sambil menunggu verifikasi admin.',
            );
          } else {
            AppToast.success(context, 'Akun dokter berhasil dibuat');
          }
          context.go(
            routeForRoleSession(
              role: session.role,
              nextStep: session.nextStep,
              accountStatus: session.accountStatus,
            ),
          );
          return;
        }

        context.push(
          '/login/register/profile-setup',
          extra: {
            AppSessionStore.tokenPrefsKey: session.token,
            AppSessionStore.userIdPrefsKey: session.userId,
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, _extractApiError(e));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _previousStep() {
    if (_currentStep == 0) {
      context.pop();
      return;
    }
    setState(() => _currentStep--);
  }

  String _stepTitle() {
    if (_currentStep == 0) {
      return _isGoogleFlow
          ? 'Langkah 1: Lengkapi Registrasi'
          : 'Langkah 1: Registrasi Akun';
    }
    return 'Langkah 2: Verifikasi OTP';
  }

  String _nextButtonLabel() {
    return _currentStep == 1 ? 'VERIFIKASI OTP' : 'LANJUT';
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 17,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF536278), size: 26),
      filled: true,
      fillColor: const Color(0xFFF9FBFD),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      errorStyle: const TextStyle(fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFE64060), width: 1.3),
      ),
    );
  }

  Widget _buildRoleSelector() {
    final isDoctor = _selectedRole == AppRoles.doctor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RoleOptionChip(
              label: 'Pasien',
              icon: Icons.favorite_outline_rounded,
              selected: !isDoctor,
              onTap: () => setState(() => _selectedRole = AppRoles.patient),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _RoleOptionChip(
              label: 'Dokter',
              icon: Icons.medical_services_outlined,
              selected: isDoctor,
              onTap: () => setState(() => _selectedRole = AppRoles.doctor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    return switch (_currentStep) {
      0 => Form(
          key: _step1Key,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _isGoogleFlow
                      ? 'Lanjutkan akun Google sebagai'
                      : 'Daftar sebagai',
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildRoleSelector(),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                style: const TextStyle(fontSize: 18, color: Color(0xFF1F2937)),
                decoration: _inputDecoration(
                  hint: 'Username',
                  icon: FluentIcons.person_accounts_24_regular,
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Username wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _firstNameController,
                style: const TextStyle(fontSize: 18, color: Color(0xFF1F2937)),
                decoration: _inputDecoration(
                  hint: 'First Name',
                  icon: FluentIcons.person_24_regular,
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'First name wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastNameController,
                style: const TextStyle(fontSize: 18, color: Color(0xFF1F2937)),
                decoration: _inputDecoration(
                  hint: 'Last Name',
                  icon: FluentIcons.person_24_regular,
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Last name wajib diisi'
                    : null,
              ),
              if (_isGoogleFlow) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FBFD),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        FluentIcons.mail_24_regular,
                        color: Color(0xFF536278),
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Email Google',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _registrationEmail,
                              style: const TextStyle(
                                color: Color(0xFF1F2937),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style:
                      const TextStyle(fontSize: 18, color: Color(0xFF1F2937)),
                  decoration: _inputDecoration(
                    hint: 'Masukkan email',
                    icon: FluentIcons.mail_24_regular,
                  ),
                  validator: (value) {
                    final email = (value ?? '').trim();
                    if (email.isEmpty) return 'Email wajib diisi';
                    if (!email.contains('@')) return 'Format email tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  style:
                      const TextStyle(fontSize: 18, color: Color(0xFF1F2937)),
                  decoration: _inputDecoration(
                    hint: 'Password',
                    icon: FluentIcons.lock_closed_24_regular,
                  ).copyWith(
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(
                          () => _isPasswordVisible = !_isPasswordVisible,
                        );
                      },
                      icon: Icon(
                        _isPasswordVisible
                            ? FluentIcons.eye_24_regular
                            : FluentIcons.eye_off_24_regular,
                        color: const Color(0xFF536278),
                        size: 26,
                      ),
                    ),
                  ),
                  validator: (value) {
                    final password = (value ?? '').trim();
                    if (password.isEmpty) {
                      return 'Password wajib diisi';
                    }
                    if (password.length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  style:
                      const TextStyle(fontSize: 18, color: Color(0xFF1F2937)),
                  decoration: _inputDecoration(
                    hint: 'Confirm Password',
                    icon: FluentIcons.lock_closed_24_regular,
                  ).copyWith(
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(
                          () => _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible,
                        );
                      },
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? FluentIcons.eye_24_regular
                            : FluentIcons.eye_off_24_regular,
                        color: const Color(0xFF536278),
                        size: 26,
                      ),
                    ),
                  ),
                  validator: (value) {
                    final confirmPassword = (value ?? '').trim();
                    if (confirmPassword.isEmpty) {
                      return 'Confirm password wajib diisi';
                    }
                    if (confirmPassword != _passwordController.text.trim()) {
                      return 'Confirm password tidak sama';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FBFD),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.translate(
                      offset: const Offset(-8, -6),
                      child: Checkbox(
                        value: _hasAgreedPrivacyPolicy,
                        activeColor: const Color(0xFFE64060),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _hasAgreedPrivacyPolicy = value ?? false;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Saya telah membaca dan menyetujui Kebijakan Privasi PulseWise.',
                            style: TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: _openPrivacyPolicy,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFE64060),
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              alignment: Alignment.centerLeft,
                            ),
                            child: const Text(
                              'Baca Kebijakan Privasi',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFFE64060),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      1 => Form(
          key: _step2Key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OtpDotField(
                controller: _otpController,
                validator: (value) {
                  final otp = (value ?? '').trim();
                  if (otp.isEmpty) {
                    return 'OTP wajib diisi';
                  }
                  if (otp.length != 6) {
                    return 'OTP harus 6 digit';
                  }
                  if (int.tryParse(otp) == null) {
                    return 'OTP harus berupa angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Masukkan kode OTP yang dikirim ke ${_registrationEmail.isNotEmpty ? _registrationEmail : _emailController.text.trim()}.',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: (_otpResendCooldown > 0 || _isResendingOtp)
                      ? null
                      : _resendOtp,
                  child: _isResendingOtp
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFFE64060)),
                        )
                      : Text(
                          _otpResendCooldown > 0
                              ? 'Kirim Ulang OTP (${_otpResendCooldown}s)'
                              : 'Kirim Ulang OTP',
                          style: const TextStyle(
                              fontSize: 17, color: Color(0xFFE64060)),
                        ),
                ),
              ),
            ],
          ),
        ),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFADB5),
                  Color(0xFFE64060),
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(height: size.height * 0.08),
                ),
                SliverToBoxAdapter(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Color.fromRGBO(195, 78, 80, 0.16),
                            offset: Offset(0, 3.98),
                            blurRadius: 17.6,
                          ),
                        ],
                      ),
                      children: [
                        TextSpan(
                          text: 'Pulse ',
                          style: TextStyle(color: Colors.white),
                        ),
                        TextSpan(
                          text: 'Wise',
                          style: TextStyle(color: Color(0xFFE64060)),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: size.height * 0.05),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 56),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(47),
                            topRight: Radius.circular(47),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 72, 24, 36),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Text(
                                  _isGoogleFlow
                                      ? 'Lanjutkan Akun Google'
                                      : 'Buat Akun',
                                  style: const TextStyle(
                                    color: Color(0xFF536278),
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Product Sans',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              _StepIndicator(currentStep: _currentStep),
                              const SizedBox(height: 18),
                              Text(
                                _stepTitle(),
                                style: const TextStyle(
                                  color: Color(0xFF525252),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: _buildStepContent(),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed:
                                          _isSubmitting ? null : _previousStep,
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Color(0xFFE2E8F0),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 18,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: Text(
                                        _currentStep == 0 ? 'BATAL' : 'KEMBALI',
                                        style: const TextStyle(
                                          color: Color(0xFF536278),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed:
                                          _isSubmitting ? null : _nextStep,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFE64060),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 18,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _isSubmitting
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              _nextButtonLabel(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              if (!_isGoogleFlow)
                                Center(
                                  child: GestureDetector(
                                    onTap: () => context.pop(),
                                    child: const Text(
                                      'Sudah punya akun? Masuk',
                                      style: TextStyle(
                                        color: Color(0xFFE64060),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Color(0xFFE64060),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 11,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/svgs/pulsewise_logo.svg',
                            width: 122,
                            height: 122,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(2, (index) {
        final isActive = index <= currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == 1 ? 0 : 8),
            height: 8,
            constraints: const BoxConstraints(minHeight: 10),
            decoration: BoxDecoration(
              color:
                  isActive ? const Color(0xFFE64060) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

class _SessionData {
  final String token;
  final String userId;
  final String role;
  final String? nextStep;
  final String? accountStatus;

  const _SessionData({
    required this.token,
    required this.userId,
    this.role = AppRoles.patient,
    this.nextStep,
    this.accountStatus,
  });
}

class _RoleOptionChip extends StatelessWidget {
  const _RoleOptionChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE64060) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFFE64060).withOpacity(0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : const Color(0xFF536278),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF334155),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpDotField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const _OtpDotField({
    required this.controller,
    required this.validator,
  });

  @override
  State<_OtpDotField> createState() => _OtpDotFieldState();
}

class _OtpDotFieldState extends State<_OtpDotField> {
  final FocusNode _focusNode = FocusNode();
  FormFieldState<String>? _formFieldState;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleValueChanged);
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleValueChanged);
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleValueChanged() {
    final field = _formFieldState;
    final shouldRevalidate = field?.hasError ?? false;
    field?.didChange(widget.controller.text);
    if (shouldRevalidate) {
      field?.validate();
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _handleFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: widget.controller.text,
      validator: widget.validator,
      autovalidateMode: AutovalidateMode.disabled,
      builder: (field) {
        _formFieldState = field;
        final otp = widget.controller.text;
        final activeIndex = otp.length.clamp(0, 5);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 58,
              child: Stack(
                children: [
                  IgnorePointer(
                    child: Row(
                      children: List.generate(6 * 2 - 1, (index) {
                        if (index.isOdd) {
                          return const SizedBox(width: 10);
                        }

                        final slotIndex = index ~/ 2;
                        final isFilled = slotIndex < otp.length;
                        final isActive = _focusNode.hasFocus &&
                            slotIndex == activeIndex &&
                            otp.length < 6;
                        final digit = isFilled ? otp[slotIndex] : '';
                        final borderColor = field.hasError
                            ? const Color(0xFFDC2626)
                            : isActive
                                ? const Color(0xFFE64060)
                                : const Color(0xFFE2E8F0);

                        return Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            height: 58,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FBFD),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: borderColor,
                                width: isActive ? 1.6 : 1.2,
                              ),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFE64060,
                                        ).withOpacity(0.12),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                switchInCurve: Curves.easeOut,
                                switchOutCurve: Curves.easeOut,
                                child: isFilled
                                    ? Text(
                                        digit,
                                        key: ValueKey('digit_$slotIndex$digit'),
                                        style: const TextStyle(
                                          color: Color(0xFFE64060),
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      )
                                    : Container(
                                        key:
                                            ValueKey('dot_$slotIndex$isActive'),
                                        width: isActive ? 10 : 8,
                                        height: isActive ? 10 : 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isActive
                                              ? const Color(0xFFF8A3B2)
                                              : const Color(0xFFD7DEE7),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.02,
                      child: TextField(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        showCursor: false,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.transparent,
                          height: 1,
                        ),
                        cursorColor: Colors.transparent,
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isCollapsed: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Ketuk kotak di atas lalu masukkan 6 digit OTP.',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (field.hasError) ...[
              const SizedBox(height: 8),
              Text(
                field.errorText ?? '',
                style: const TextStyle(
                  color: Color(0xFFDC2626),
                  fontSize: 16,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
