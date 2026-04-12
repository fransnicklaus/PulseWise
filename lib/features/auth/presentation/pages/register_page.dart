import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/network/api_logger.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

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

  final _addressController = TextEditingController();
  final _heightController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedBirthDate;
  String? _selectedBloodType;

  final _step1Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();
  final _step4Key = GlobalKey<FormState>();

  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _isPasswordVisible = false;
  bool _isResendingOtp = false;
  bool _showProfileValidation = false;
  int _otpResendCooldown = 0;
  Timer? _otpCooldownTimer;

  String? _registeredPatientId;
  String? _bearerToken;

  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'auth_user_id';

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
    _addressController.dispose();
    _heightController.dispose();
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
    final success = body['success'] == true;
    if (!success) {
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

  Future<void> _sendEmailOtp() async {
    final dio = _buildDio();
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/verifications/email',
      data: {
        'email': _emailController.text.trim(),
      },
    );

    final body = response.data ?? <String, dynamic>{};
    if (body['success'] != true) {
      throw Exception((body['message'] ?? 'Gagal mengirim OTP').toString());
    }
  }

  Future<void> _confirmEmailOtp() async {
    final dio = _buildDio();
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/verifications/email/confirm',
      data: {
        'email': _emailController.text.trim(),
        'otp': _otpController.text.trim(),
      },
    );

    final body = response.data ?? <String, dynamic>{};
    if (body['success'] != true) {
      throw Exception((body['message'] ?? 'Verifikasi OTP gagal').toString());
    }
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

  Future<void> _updatePatientProfile(String patientId) async {
    final dio = _buildDio();
    final date = _selectedBirthDate!;
    final dateOfBirth =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final response = await dio.put<Map<String, dynamic>>(
      '/patients/$patientId/profile',
      options: Options(
        headers: {
          'Authorization': 'Bearer $_bearerToken',
        },
      ),
      data: {
        'dateOfBirth': dateOfBirth,
        'sex': (_selectedGender ?? '').toLowerCase(),
        'heightCm': double.parse(_heightController.text.trim()),
        'isSmoking': false,
        'isElectricSmoking': false,
        'bloodType': _selectedBloodType ?? 'O+',
        'address': _addressController.text.trim(),
      },
    );

    final body = response.data ?? <String, dynamic>{};
    if (body['success'] != true) {
      throw Exception((body['message'] ?? 'Update profil gagal').toString());
    }
  }

  Future<void> _persistSession({
    required String token,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userIdKey, userId);
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

    setState(() => _isResendingOtp = true);
    try {
      await _sendEmailOtp();
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

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _showProfileValidation = false;
      });
    }
  }

  Future<void> _nextStep() async {
    final canProceed = switch (_currentStep) {
      0 => _step1Key.currentState?.validate() ?? false,
      1 => true,
      2 => _step3Key.currentState?.validate() ?? false,
      3 => _step4Key.currentState?.validate() ?? false,
      _ => false,
    };

    if (!canProceed || _isSubmitting) return;

    if (_currentStep == 3 && _selectedBirthDate == null) {
      setState(() => _showProfileValidation = true);
      AppToast.warning(context, 'Tanggal lahir wajib dipilih');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (_currentStep == 0) {
        final patientId = await _registerAndGetPatientId();
        if (!mounted) return;
        _registeredPatientId = patientId;
        AppToast.success(context, 'Registrasi akun berhasil');
        setState(() {
          _currentStep = 1;
          _isSubmitting = false;
        });
        return;
      }

      if (_currentStep == 1) {
        await _sendEmailOtp();
        if (!mounted) return;
        AppToast.success(context, 'OTP berhasil dikirim ke email');
        _startOtpCooldown();
        setState(() {
          _currentStep = 2;
          _isSubmitting = false;
        });
        return;
      }

      if (_currentStep == 2) {
        await _confirmEmailOtp();
        final token = await _loginAndGetBearerToken();
        if (!mounted) return;
        _bearerToken = token;
        setState(() {
          _currentStep = 3;
          _showProfileValidation = false;
          _isSubmitting = false;
        });
        return;
      }

      final patientId = _registeredPatientId;
      if (patientId == null || patientId.isEmpty) {
        throw Exception('Data akun belum terdaftar. Ulangi langkah 1.');
      }
      if ((_bearerToken ?? '').isEmpty) {
        throw Exception(
            'Token autentikasi belum tersedia. Ulangi langkah autentikasi.');
      }

      await _updatePatientProfile(patientId);
      if (!mounted) return;
      await _persistSession(
        token: _bearerToken!,
        userId: patientId,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/home');
        }
      });
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
    return switch (_currentStep) {
      0 => 'Langkah 1: Registrasi Akun',
      1 => 'Langkah 2: Kirim OTP',
      2 => 'Langkah 3: Verifikasi OTP',
      _ => 'Langkah 4: Lengkapi Profil',
    };
  }

  String _nextButtonLabel() {
    return switch (_currentStep) {
      1 => 'KIRIM OTP',
      2 => 'VERIFIKASI OTP',
      3 => 'SELESAI',
      _ => 'LANJUT',
    };
  }

  String _birthDateLabel() {
    final date = _selectedBirthDate;
    if (date == null) return 'Pilih tanggal lahir';

    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 15,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF536278)),
      filled: true,
      fillColor: const Color(0xFFF9FBFD),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                decoration: _inputDecoration(
                  hint: 'Last Name',
                  icon: FluentIcons.person_24_regular,
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Last name wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
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
                decoration: _inputDecoration(
                  hint: 'Password',
                  icon: FluentIcons.lock_closed_24_regular,
                ).copyWith(
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => _isPasswordVisible = !_isPasswordVisible);
                    },
                    icon: Icon(
                      _isPasswordVisible
                          ? FluentIcons.eye_24_regular
                          : FluentIcons.eye_off_24_regular,
                      color: const Color(0xFF536278),
                    ),
                  ),
                ),
                validator: (value) {
                  final password = (value ?? '').trim();
                  if (password.isEmpty) return 'Password wajib diisi';
                  if (password.length < 6) return 'Password minimal 6 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isPasswordVisible,
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
          ),
        ),
      1 => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FBFD),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kirim OTP ke Email',
                style: TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Tekan KIRIM OTP untuk mengirim OTP ke ${_emailController.text.trim()}.',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      2 => Form(
          key: _step3Key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
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
              const SizedBox(height: 10),
              const Text(
                'Masukkan kode OTP yang sudah dikirim ke email Anda.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: (_otpResendCooldown > 0 || _isResendingOtp)
                      ? null
                      : _resendOtp,
                  child: _isResendingOtp
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _otpResendCooldown > 0
                              ? 'Kirim Ulang OTP (${_otpResendCooldown}s)'
                              : 'Kirim Ulang OTP',
                        ),
                ),
              ),
            ],
          ),
        ),
      _ => Form(
          key: _step4Key,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedGender,
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                ],
                decoration: _inputDecoration(
                  hint: 'Jenis Kelamin',
                  icon: FluentIcons.person_feedback_24_regular,
                ),
                onChanged: (value) => setState(() => _selectedGender = value),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Jenis kelamin wajib dipilih'
                    : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: _pickBirthDate,
                child: Ink(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FBFD),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        FluentIcons.calendar_24_regular,
                        color: Color(0xFF536278),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _birthDateLabel(),
                          style: TextStyle(
                            color: _selectedBirthDate == null
                                ? const Color(0xFF64748B)
                                : const Color(0xFF1F2937),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_selectedBirthDate == null && _showProfileValidation)
                const Padding(
                  padding: EdgeInsets.only(top: 6, left: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Tanggal lahir wajib dipilih',
                      style: TextStyle(
                        color: Color(0xFFB91C1C),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: _inputDecoration(
                  hint: 'Alamat',
                  icon: FluentIcons.location_24_regular,
                ),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Alamat wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedBloodType,
                items: const [
                  DropdownMenuItem(value: 'A+', child: Text('A+')),
                  DropdownMenuItem(value: 'A-', child: Text('A-')),
                  DropdownMenuItem(value: 'B+', child: Text('B+')),
                  DropdownMenuItem(value: 'B-', child: Text('B-')),
                  DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                  DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                  DropdownMenuItem(value: 'O+', child: Text('O+')),
                  DropdownMenuItem(value: 'O-', child: Text('O-')),
                ],
                decoration: _inputDecoration(
                  hint: 'Golongan Darah',
                  icon: FluentIcons.heart_pulse_24_regular,
                ),
                onChanged: (value) =>
                    setState(() => _selectedBloodType = value),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Golongan darah wajib dipilih'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  hint: 'Tinggi Badan (cm)',
                  icon: FluentIcons.ruler_24_regular,
                ),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) return 'Tinggi badan wajib diisi';
                  if (double.tryParse(text) == null) {
                    return 'Tinggi badan harus angka';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
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
                          padding: const EdgeInsets.fromLTRB(24, 72, 24, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Center(
                                child: Text(
                                  'Buat Akun',
                                  style: TextStyle(
                                    color: Color(0xFF536278),
                                    fontSize: 30,
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
                                  fontSize: 18,
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
                                            color: Color(0xFFE2E8F0)),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: Text(
                                        _currentStep == 0 ? 'BATAL' : 'KEMBALI',
                                        style: const TextStyle(
                                          color: Color(0xFF536278),
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
                                            vertical: 14),
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
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: GestureDetector(
                                  onTap: () => context.pop(),
                                  child: const Text(
                                    'Sudah punya akun? Masuk',
                                    style: TextStyle(
                                      color: Color(0xFFE64060),
                                      fontSize: 15,
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
                            width: 112,
                            height: 112,
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
      children: List.generate(4, (index) {
        final isActive = index <= currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
            height: 8,
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
