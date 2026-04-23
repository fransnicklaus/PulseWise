import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/network/api_logger.dart';
import 'package:pulsewise/core/utils/app_toast.dart';

class RegisterPage extends StatefulWidget {
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
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
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
  bool _isResendingOtp = false;
  int _otpResendCooldown = 0;
  Timer? _otpCooldownTimer;
  bool _googleRegistrationCompleted = false;

  String? _registeredPatientId;
  String _registrationEmail = '';

  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'auth_user_id';

  bool get _isGoogleFlow {
    return (widget.googleEmail ?? '').isNotEmpty &&
        (widget.googleIdToken ?? '').isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
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
    final baseUrl = dotenv.env['API_BASE_URL'] ??
        'https://pulsewise-backend.vercel.app/api/v1';

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: const {'Accept': 'application/json'},
      ),
    );
    ApiLogger.attach(dio);
    return dio;
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

  Future<String> _registerAndGetPatientId() async {
    final dio = _buildDio();
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'username': _usernameController.text.trim(),
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'role': 'patient',
      },
    );

    final body = response.data ?? <String, dynamic>{};
    if (body['success'] != true) {
      throw Exception((body['message'] ?? 'Registrasi gagal').toString());
    }

    String patientId = '';
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      patientId = _extractIdFromMap(data);

      if (patientId.isEmpty && data['patient'] is Map<String, dynamic>) {
        patientId = _extractIdFromMap(data['patient'] as Map<String, dynamic>);
      }

      if (patientId.isEmpty && data['user'] is Map<String, dynamic>) {
        patientId = _extractIdFromMap(data['user'] as Map<String, dynamic>);
      }
    }

    if (patientId.isEmpty) {
      patientId = _extractIdFromMap(body);
    }

    if (patientId.isEmpty) {
      throw Exception('patientId/userId tidak ditemukan pada respons register');
    }

    return patientId;
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

  Future<String> _loginAndGetBearerToken() async {
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

    return token;
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
        'role': widget.googleRole,
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
        'role': widget.googleRole,
      },
    );

    final body = response.data ?? <String, dynamic>{};
    if (body['success'] != true) {
      throw Exception(
          (body['message'] ?? 'Autentikasi Google gagal').toString());
    }

    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    final nextStep = (data['nextStep'] ?? '').toString().toUpperCase().trim();
    if (nextStep != 'HOME') {
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

    return _SessionData(token: token, userId: userId);
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

  Future<void> _nextStep() async {
    final canProceed = switch (_currentStep) {
      0 => _step1Key.currentState?.validate() ?? false,
      1 => _step2Key.currentState?.validate() ?? false,
      _ => false,
    };

    if (!canProceed || _isSubmitting) return;

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
          final patientId = await _registerAndGetPatientId();
          _registeredPatientId = patientId;
          _registrationEmail = _emailController.text.trim();
          await _sendEmailOtp(email: _registrationEmail);
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
          final token = await _loginAndGetBearerToken();
          final patientId = _registeredPatientId;
          if (patientId == null || patientId.isEmpty) {
            throw Exception('Data akun belum terdaftar. Ulangi registrasi.');
          }
          session = _SessionData(token: token, userId: patientId);
        }

        if (!mounted) return;
        setState(() => _isSubmitting = false);
        context.push(
          '/login/register/profile-setup',
          extra: {
            _tokenKey: session.token,
            _userIdKey: session.userId,
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
        color: Color(0xFF64748B),
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

  Widget _buildStepContent() {
    return switch (_currentStep) {
      0 => Form(
          key: _step1Key,
          child: Column(
            children: [
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
                            () => _isPasswordVisible = !_isPasswordVisible);
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
                    if (password.isEmpty) return 'Password wajib diisi';
                    if (password.length < 6)
                      return 'Password minimal 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isPasswordVisible,
                  style:
                      const TextStyle(fontSize: 18, color: Color(0xFF1F2937)),
                  decoration: _inputDecoration(
                    hint: 'Confirm Password',
                    icon: FluentIcons.lock_closed_24_regular,
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
            ],
          ),
        ),
      1 => Form(
          key: _step2Key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(fontSize: 20, letterSpacing: 1.2),
                decoration: _inputDecoration(
                  hint: 'Masukkan 6 digit OTP',
                  icon: FluentIcons.password_24_regular,
                ).copyWith(counterText: ''),
                validator: (value) {
                  final otp = (value ?? '').trim();
                  if (otp.isEmpty) return 'OTP wajib diisi';
                  if (otp.length != 6) return 'OTP harus 6 digit';
                  if (int.tryParse(otp) == null)
                    return 'OTP harus berupa angka';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Masukkan kode OTP yang dikirim ke ${_registrationEmail.isNotEmpty ? _registrationEmail : _emailController.text.trim()}.',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 16,
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _otpResendCooldown > 0
                              ? 'Kirim Ulang OTP (${_otpResendCooldown}s)'
                              : 'Kirim Ulang OTP',
                          style: const TextStyle(fontSize: 17),
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
                        top: 0,
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

  const _SessionData({required this.token, required this.userId});
}
