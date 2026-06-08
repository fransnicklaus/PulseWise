import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/constants/app_roles.dart';
import 'package:pulsewise/core/constants/release_feature_flags.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/features/auth/presentation/providers/auth_provider.dart';
import 'package:pulsewise/features/doctor_shell/presentation/providers/doctor_dashboard_provider.dart';
import 'package:pulsewise/features/dashboard_shell/presentation/providers/dashboard_provider.dart';

class GoogleVerifyOtpPage extends ConsumerStatefulWidget {
  final String email;
  final String role;
  final String idToken;

  const GoogleVerifyOtpPage({
    super.key,
    required this.email,
    required this.role,
    required this.idToken,
  });

  @override
  ConsumerState<GoogleVerifyOtpPage> createState() =>
      _GoogleVerifyOtpPageState();
}

class _GoogleVerifyOtpPageState extends ConsumerState<GoogleVerifyOtpPage> {
  final _otpController = TextEditingController();
  bool _isSubmitting = false;
  bool _isResending = false;
  int _cooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = 30);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldown <= 1) {
        timer.cancel();
        setState(() => _cooldown = 0);
        return;
      }
      setState(() => _cooldown--);
    });
  }

  Future<void> _resendOtp() async {
    if (_isResending || _cooldown > 0) return;
    setState(() => _isResending = true);
    try {
      await ref
          .read(authProvider.notifier)
          .resendEmailVerificationOtp(widget.email);
      if (!mounted) return;
      _startCooldown();
      AppToast.success(context, 'OTP berhasil dikirim ulang');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (_isSubmitting) return;
    if (otp.length != 6 || int.tryParse(otp) == null) {
      AppToast.warning(context, 'OTP harus 6 digit angka');
      return;
    }

    setState(() => _isSubmitting = true);
    final result =
        await ref.read(authProvider.notifier).verifyGoogleOtpAndFinalize(
              email: widget.email,
              otp: otp,
              idToken: widget.idToken,
              role: widget.role,
            );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!result.success) {
      AppToast.error(context, result.message ?? 'Verifikasi OTP gagal');
      return;
    }

    if (result.nextStep == GoogleAuthNextStep.home) {
      final normalizedRole = normalizeAppRole(result.role);
      if (normalizedRole == AppRoles.doctor) {
        ref.read(doctorDashboardNavIndexProvider.notifier).state = 0;
        ref.read(healthConnectLoginPromptArmedProvider.notifier).state = false;
      } else {
        ref.read(previousNavIndexProvider.notifier).state = 0;
        ref.read(dashboardNavIndexProvider.notifier).state = 0;
        ref.read(healthConnectLoginPromptArmedProvider.notifier).state =
            isHealthConnectEnabledForRelease;
      }
      AppToast.success(context, 'Email berhasil diverifikasi');
      context.go(
        routeForRoleSession(
          role: normalizedRole,
          nextStep: AppAuthNextSteps.home,
          accountStatus: result.accountStatus,
        ),
      );
      return;
    }

    if (result.nextStep == GoogleAuthNextStep.waitAdminVerification) {
      ref.read(doctorDashboardNavIndexProvider.notifier).state = 0;
      ref.read(healthConnectLoginPromptArmedProvider.notifier).state = false;
      AppToast.info(
        context,
        'Email berhasil diverifikasi. Akun dokter Anda sedang menunggu verifikasi admin.',
      );
      context.go(
        routeForRoleSession(
          role: result.role,
          nextStep: AppAuthNextSteps.waitAdminVerification,
          accountStatus: result.accountStatus,
        ),
      );
      return;
    }

    AppToast.warning(
      context,
      'OTP berhasil, tetapi akun belum dapat masuk. Silakan coba login Google lagi.',
    );
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi OTP'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF334155),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Masukkan OTP',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kode OTP dikirim ke ${widget.email}',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: 'Masukkan 6 digit OTP',
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFFF9FBFD),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Color(0xFFE64060), width: 1.2),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed:
                      (_isResending || _cooldown > 0) ? null : _resendOtp,
                  child: _isResending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _cooldown > 0
                              ? 'Kirim Ulang OTP (${_cooldown}s)'
                              : 'Kirim Ulang OTP',
                        ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE64060),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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
                      : const Text(
                          'VERIFIKASI OTP',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
