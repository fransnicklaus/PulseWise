import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/features/auth/presentation/providers/auth_provider.dart';

class GoogleCompleteRegistrationPage extends ConsumerStatefulWidget {
  final String registrationToken;
  final String email;
  final String role;
  final String idToken;
  final String? firstName;
  final String? lastName;

  const GoogleCompleteRegistrationPage({
    super.key,
    required this.registrationToken,
    required this.email,
    required this.role,
    required this.idToken,
    this.firstName,
    this.lastName,
  });

  @override
  ConsumerState<GoogleCompleteRegistrationPage> createState() =>
      _GoogleCompleteRegistrationPageState();
}

class _GoogleCompleteRegistrationPageState
    extends ConsumerState<GoogleCompleteRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.firstName ?? '';
    _lastNameController.text = widget.lastName ?? '';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    final result = await ref.read(authProvider.notifier).completeGoogleRegistration(
          registrationToken: widget.registrationToken,
          username: _usernameController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          role: widget.role,
          idToken: widget.idToken,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!result.success) {
      AppToast.error(context, result.message ?? 'Registrasi Google gagal');
      return;
    }

    if (result.nextStep == GoogleAuthNextStep.verifyOtp) {
      context.pushReplacement(
        '/login/google-verify-otp',
        extra: {
          'email': result.email,
          'role': result.role,
          'idToken': widget.idToken,
        },
      );
      return;
    }

    AppToast.warning(context, 'Langkah berikutnya tidak dikenali.');
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF9FBFD),
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
        borderSide: const BorderSide(color: Color(0xFFE64060), width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lengkapi Registrasi'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF334155),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lanjutkan registrasi Google',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Email: ${widget.email}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _usernameController,
                  decoration: _decoration('Username'),
                  validator: (value) {
                    final v = (value ?? '').trim();
                    if (v.isEmpty) return 'Username wajib diisi';
                    if (v.length < 3) return 'Username minimal 3 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _firstNameController,
                  decoration: _decoration('Nama Depan'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameController,
                  decoration: _decoration('Nama Belakang'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
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
                            'LANJUT VERIFIKASI OTP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
