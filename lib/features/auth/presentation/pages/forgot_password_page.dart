import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/features/auth/presentation/providers/auth_provider.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _isPasswordVisible = false;
  bool _isResendingOtp = false;
  int _otpResendCooldown = 0;
  Timer? _otpCooldownTimer;

  String? _resetToken;

  @override
  void dispose() {
    _otpCooldownTimer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      AppToast.warning(context, 'Email belum tersedia untuk kirim OTP');
      return;
    }

    setState(() => _isResendingOtp = true);
    try {
      await ref.read(authProvider.notifier).forgotPassword(email: email);
      if (!mounted) return;
      AppToast.success(context, 'OTP baru berhasil dikirim');
      _startOtpCooldown();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isResendingOtp = false);
    }
  }

  Future<void> _nextStep() async {
    final canProceed = switch (_currentStep) {
      0 => _step1Key.currentState?.validate() ?? false,
      1 => _step2Key.currentState?.validate() ?? false,
      2 => _step3Key.currentState?.validate() ?? false,
      _ => false,
    };

    if (!canProceed || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      if (_currentStep == 0) {
        // Step 1: Send OTP
        await ref
            .read(authProvider.notifier)
            .forgotPassword(email: _emailController.text.trim());
        if (!mounted) return;
        AppToast.success(context, 'OTP berhasil dikirim ke email Anda');

        _startOtpCooldown();
        setState(() {
          _isSubmitting = false;
          _currentStep = 1;
        });
      } else if (_currentStep == 1) {
        // Step 2: Verify OTP
        final data =
            await ref.read(authProvider.notifier).verifyForgotPasswordOtp(
                  email: _emailController.text.trim(),
                  otp: _otpController.text.trim(),
                );
        final resetToken = (data['resetToken'] ?? '').toString();
        if (resetToken.isEmpty) {
          throw Exception('Token reset tidak diterima dari server');
        }
        _resetToken = resetToken;
        if (!mounted) return;
        AppToast.success(
            context, 'OTP valid. Silakan masukkan kata sandi baru');

        setState(() {
          _isSubmitting = false;
          _currentStep = 2;
        });
      } else if (_currentStep == 2) {
        // Step 3: Reset Password
        if (_resetToken == null || _resetToken!.isEmpty) {
          throw Exception('Token reset tidak tersedia');
        }
        await ref.read(authProvider.notifier).resetForgotPassword(
              resetToken: _resetToken!,
              newPassword: _newPasswordController.text.trim(),
              confirmNewPassword: _confirmPasswordController.text.trim(),
            );
        if (!mounted) return;
        AppToast.success(
            context, 'Kata sandi berhasil direset. Silakan masuk kembali.');
        context.go('/login');
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
      setState(() => _isSubmitting = false);
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
      0 => 'Langkah 1: Masukkan Email',
      1 => 'Langkah 2: Verifikasi OTP',
      2 => 'Langkah 3: Reset Kata Sandi',
      _ => '',
    };
  }

  String _nextButtonLabel() {
    return switch (_currentStep) {
      0 => 'KIRIM OTP',
      1 => 'VERIFIKASI OTP',
      2 => 'SIMPAN SANDI',
      _ => 'LANJUT',
    };
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Masukkan email yang terdaftar. Kami akan mengirimkan 6 digit kode OTP.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 18, color: Color(0xFF1F2937)),
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
                  if (int.tryParse(otp) == null) {
                    return 'OTP harus berupa angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Masukkan kode OTP yang dikirim ke ${_emailController.text.trim()}.',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 16),
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
      2 => Form(
          key: _step3Key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _newPasswordController,
                obscureText: !_isPasswordVisible,
                style: const TextStyle(fontSize: 18, color: Color(0xFF1F2937)),
                decoration: _inputDecoration(
                  hint: 'Kata Sandi Baru',
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
                      size: 26,
                    ),
                  ),
                ),
                validator: (value) {
                  final password = (value ?? '').trim();
                  if (password.isEmpty) return 'Kata sandi wajib diisi';
                  if (password.length < 6) return 'Minimal 6 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isPasswordVisible,
                style: const TextStyle(fontSize: 18, color: Color(0xFF1F2937)),
                decoration: _inputDecoration(
                  hint: 'Konfirmasi Kata Sandi',
                  icon: FluentIcons.lock_closed_24_regular,
                ),
                validator: (value) {
                  final confirmPassword = (value ?? '').trim();
                  if (confirmPassword.isEmpty) {
                    return 'Konfirmasi wajib diisi';
                  }
                  if (confirmPassword != _newPasswordController.text.trim()) {
                    return 'Konfirmasi tidak cocok';
                  }
                  return null;
                },
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
                const SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Pulse',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Outfit',
                          shadows: [
                            Shadow(
                              color: Color.fromRGBO(195, 78, 80, 0.16),
                              offset: Offset(0, 3.98),
                              blurRadius: 17.6,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Wise',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE64060),
                          fontFamily: 'Outfit',
                          shadows: [
                            Shadow(
                              color: Color.fromRGBO(195, 78, 80, 0.16),
                              offset: Offset(0, 3.98),
                              blurRadius: 17.6,
                            ),
                          ],
                        ),
                      ),
                    ],
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
                              const Center(
                                child: Text(
                                  'Lupa Sandi',
                                  style: TextStyle(
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
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 15,
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
      children: List.generate(3, (index) {
        final isActive = index <= currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
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
