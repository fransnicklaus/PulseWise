import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/features/auth/data/models/account_deletion_models.dart';
import 'package:pulsewise/features/auth/presentation/providers/account_deletion_provider.dart';
import 'package:pulsewise/features/auth/presentation/providers/auth_provider.dart';
import 'package:pulsewise/features/dashboard_shell/presentation/providers/dashboard_provider.dart';
import 'package:pulsewise/features/diary/presentation/providers/current_diary_provider.dart';
import 'package:pulsewise/features/emergency_contacts/presentation/providers/emergency_contacts_provider.dart';
import 'package:pulsewise/features/home_dashboard/presentation/providers/dashboard_overview_provider.dart';
import 'package:pulsewise/features/profile/presentation/providers/profile_provider.dart';

class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  final _confirmationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  late List<String> _availableMethods;
  late String _selectedMethod;

  AccountDeletionRequestResult? _requestResult;

  bool _isRequesting = false;
  bool _isConfirming = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _availableMethods = _defaultAvailableMethods();
    _selectedMethod = _pickFirstAvailableMethod(_availableMethods);
  }

  @override
  void dispose() {
    _confirmationController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  bool get _isConfirmationTextValid =>
      _confirmationController.text == accountDeletionConfirmationText;

  int get _currentStepIndex => _requestResult == null ? 0 : 1;

  String get _activeMethod {
    final requestedMethod =
        normalizeAccountDeletionMethod(_requestResult?.reauthMethod);
    if (requestedMethod.isNotEmpty) {
      return requestedMethod;
    }
    return _selectedMethod;
  }

  List<String> _defaultAvailableMethods() {
    return _sanitizeAvailableMethods(
      kIsWeb
          ? const [
              accountDeletionPasswordMethod,
              accountDeletionOtpMethod,
            ]
          : const [
              accountDeletionPasswordMethod,
              accountDeletionOtpMethod,
              accountDeletionGoogleMethod,
            ],
    );
  }

  String _pickFirstAvailableMethod(List<String> methods) {
    if (methods.isNotEmpty) {
      return methods.first;
    }
    return accountDeletionPasswordMethod;
  }

  List<String> _sanitizeAvailableMethods(List<String> methods) {
    const allowedMethods = [
      accountDeletionPasswordMethod,
      accountDeletionOtpMethod,
      accountDeletionGoogleMethod,
    ];

    final sanitized = methods
        .map(normalizeAccountDeletionMethod)
        .where((method) => allowedMethods.contains(method))
        .where((method) => !(kIsWeb && method == accountDeletionGoogleMethod))
        .toSet()
        .toList();

    if (sanitized.isEmpty) {
      return kIsWeb
          ? [
              accountDeletionPasswordMethod,
              accountDeletionOtpMethod,
            ]
          : [
              accountDeletionPasswordMethod,
              accountDeletionOtpMethod,
              accountDeletionGoogleMethod,
            ];
    }

    sanitized.sort((left, right) {
      return allowedMethods
          .indexOf(left)
          .compareTo(allowedMethods.indexOf(right));
    });
    return sanitized;
  }

  Future<void> _submitDeletionRequest() async {
    if (_isRequesting || _isConfirming) return;
    if (!_isConfirmationTextValid) {
      AppToast.warning(
        context,
        'Ketik persis HAPUS AKUN untuk melanjutkan.',
      );
      return;
    }

    setState(() => _isRequesting = true);
    try {
      final result =
          await ref.read(accountDeletionApiProvider).requestAccountDeletion(
                confirmationText: _confirmationController.text,
                reauthMethod: _selectedMethod,
              );
      if (!mounted) return;

      setState(() {
        _availableMethods = result.availableReauthMethods.isEmpty
            ? _availableMethods
            : _sanitizeAvailableMethods(result.availableReauthMethods);
        _requestResult = result;
      });

      if (result.reauthMethod == accountDeletionOtpMethod) {
        final expireText = result.expiresInMinutes == null
            ? ''
            : ' Berlaku selama ${result.expiresInMinutes} menit.';
        AppToast.info(
          context,
          'OTP penghapusan akun sudah dikirim ke email Anda.$expireText',
        );
      } else {
        AppToast.success(
          context,
          'Permintaan penghapusan akun berhasil dibuat.',
        );
      }
    } on AccountDeletionException catch (error) {
      if (!mounted) return;
      final updatedMethods = _sanitizeAvailableMethods(
        error.availableReauthMethods.isEmpty
            ? _availableMethods
            : error.availableReauthMethods,
      );

      setState(() {
        _availableMethods = updatedMethods;
        if (!_availableMethods.contains(_selectedMethod)) {
          _selectedMethod = _pickFirstAvailableMethod(_availableMethods);
        }
      });

      AppToast.error(
        context,
        error.firstFieldError('confirmationText') ?? error.message,
      );
    } catch (error) {
      if (!mounted) return;
      AppToast.error(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  Future<void> _confirmDeletion() async {
    final requestResult = _requestResult;
    if (requestResult == null || _isConfirming || _isRequesting) {
      return;
    }

    final method = requestResult.reauthMethod;
    String? password;
    String? otp;
    String? googleIdToken;

    if (method == accountDeletionPasswordMethod) {
      password = _passwordController.text.trim();
      if (password.isEmpty) {
        AppToast.warning(context, 'Kata sandi saat ini wajib diisi.');
        return;
      }
    } else if (method == accountDeletionOtpMethod) {
      otp = _otpController.text.trim();
      if (otp.length != 6) {
        AppToast.warning(context, 'OTP harus 6 digit angka.');
        return;
      }
    } else if (method == accountDeletionGoogleMethod) {
      googleIdToken = await _reauthenticateWithGoogle();
      if (!mounted || googleIdToken == null) return;
    }

    setState(() => _isConfirming = true);
    try {
      final result =
          await ref.read(accountDeletionApiProvider).confirmAccountDeletion(
                deletionToken: requestResult.deletionToken,
                password: password,
                otp: otp,
                googleIdToken: googleIdToken,
              );

      if (!mounted) return;
      if (!result.deleted) {
        throw Exception('Akun belum berhasil dihapus permanen.');
      }

      await _completeLocalLogout();
    } on AccountDeletionException catch (error) {
      if (!mounted) return;
      AppToast.error(context, error.message);
    } catch (error) {
      if (!mounted) return;
      AppToast.error(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
  }

  Future<String?> _reauthenticateWithGoogle() async {
    if (kIsWeb) {
      AppToast.warning(
        context,
        'Google re-autentikasi di browser belum tersedia. Gunakan OTP email.',
      );
      return null;
    }

    final googleSignIn = buildGoogleSignInClient();
    try {
      try {
        await googleSignIn.disconnect();
      } catch (_) {
        await googleSignIn.signOut();
      }

      final account = await googleSignIn.signIn();
      if (account == null) {
        if (!mounted) return null;
        AppToast.info(context, 'Proses Google dibatalkan.');
        return null;
      }

      final authentication = await account.authentication;
      final idToken = (authentication.idToken ?? '').trim();
      if (idToken.isEmpty) {
        throw Exception('Google ID token tidak tersedia.');
      }
      return idToken;
    } on PlatformException catch (error) {
      throw Exception(
        (error.message ?? 'Google re-autentikasi gagal').trim(),
      );
    }
  }

  Future<void> _completeLocalLogout() async {
    await ref.read(authProvider.notifier).logout();
    ref.invalidate(authMeProvider);
    ref.invalidate(patientProfileProvider);
    ref.invalidate(quickDashboardProvider);
    ref.invalidate(dashboardVitalsProvider);
    ref.invalidate(currentDiaryProvider);
    ref.invalidate(emergencyContactsProvider);
    ref.read(previousNavIndexProvider.notifier).state = 0;
    ref.read(dashboardNavIndexProvider.notifier).state = 0;
    ref.read(healthConnectLoginPromptArmedProvider.notifier).state = false;

    if (!mounted) return;
    AppToast.success(context, 'Akun berhasil dihapus permanen.');
    context.go('/login');
  }

  void _resetToStepOne() {
    setState(() {
      _requestResult = null;
      _passwordController.clear();
      _otpController.clear();
      if (!_availableMethods.contains(_selectedMethod)) {
        _selectedMethod = _pickFirstAvailableMethod(_availableMethods);
      }
    });
  }

  String _methodLabel(String method) {
    switch (method) {
      case accountDeletionPasswordMethod:
        return 'Kata Sandi';
      case accountDeletionOtpMethod:
        return 'OTP Email';
      case accountDeletionGoogleMethod:
        return 'Google';
      default:
        return method;
    }
  }

  String _methodDescription(String method) {
    switch (method) {
      case accountDeletionPasswordMethod:
        return 'Masukkan kata sandi akun Anda untuk konfirmasi terakhir.';
      case accountDeletionOtpMethod:
        return 'Kami kirim OTP 6 digit ke email Anda untuk verifikasi akhir.';
      case accountDeletionGoogleMethod:
        return 'Konfirmasi dengan akun Google yang sedang terhubung.';
      default:
        return 'Gunakan metode ini untuk memverifikasi penghapusan akun.';
    }
  }

  IconData _methodIcon(String method) {
    switch (method) {
      case accountDeletionPasswordMethod:
        return Icons.lock_outline_rounded;
      case accountDeletionOtpMethod:
        return Icons.mark_email_unread_outlined;
      case accountDeletionGoogleMethod:
        return Icons.g_mobiledata_rounded;
      default:
        return Icons.verified_user_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestResult = _requestResult;
    final activeMethod = _activeMethod;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Hapus Akun',
        subtitle: 'Penghapusan akun bersifat permanen',
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                _buildWarningCard(),
                const SizedBox(height: 20),
                if (requestResult == null) ...[
                  _buildConfirmationInput(),
                  const SizedBox(height: 20),
                  _buildMethodSelector(),
                  const SizedBox(height: 24),
                  _buildPrimaryButton(
                    label: 'Lanjutkan Penghapusan',
                    isLoading: _isRequesting,
                    onPressed: _isConfirmationTextValid &&
                            !_isRequesting &&
                            !_isConfirming
                        ? _submitDeletionRequest
                        : null,
                  ),
                ] else ...[
                  _buildVerificationSummary(requestResult),
                  const SizedBox(height: 20),
                  _buildVerificationInput(
                    method: activeMethod,
                    requestResult: requestResult,
                  ),
                  const SizedBox(height: 24),
                  _buildPrimaryButton(
                    label: activeMethod == accountDeletionGoogleMethod
                        ? 'Konfirmasi dengan Google'
                        : 'Hapus Akun Permanen',
                    isLoading: _isConfirming,
                    onPressed: _isConfirming ? null : _confirmDeletion,
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _isConfirming ? null : _resetToStepOne,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                    ),
                    child: const Text(
                      'Pilih metode verifikasi lain',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDA4AF)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFBE123C),
                size: 28,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Perhatian: akun akan dihapus permanen',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF881337),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Menghapus akun akan menghapus seluruh data Anda secara permanen dan tidak dapat dipulihkan.',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Color(0xFF9F1239),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Setelah berhasil, Anda akan langsung keluar dan token lama tidak bisa dipakai lagi.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF9F1239),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    const labels = [
      'Konfirmasi Penghapusan',
      'Verifikasi Akhir',
    ];
    const descriptions = [
      'Cek ulang teks konfirmasi dan metode verifikasi.',
      'Selesaikan verifikasi terakhir untuk menghapus akun.',
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(labels.length, (index) {
              final isActive = index <= _currentStepIndex;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                      right: index == labels.length - 1 ? 0 : 8),
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFE64060)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            labels[_currentStepIndex],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            descriptions[_currentStepIndex],
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationInput() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ketik konfirmasi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Untuk melanjutkan, ketik persis teks berikut:',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              accountDeletionConfirmationText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: Color(0xFFBE123C),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _confirmationController,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Ketik di sini untuk konfirmasi',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Color(0xFFE64060), width: 1.2),
              ),
              suffixIcon: _isConfirmationTextValid
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF16A34A),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSelector() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih metode verifikasi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gunakan metode yang paling mudah untuk Anda selesaikan sekarang.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          for (final method in _availableMethods) ...[
            _buildMethodCard(method),
            if (method != _availableMethods.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildMethodCard(String method) {
    final selected = _selectedMethod == method;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _isRequesting
          ? null
          : () {
              setState(() {
                _selectedMethod = method;
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF1F2) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFFE64060) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFE64060)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _methodIcon(method),
                color: selected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _methodLabel(method),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _methodDescription(method),
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color:
                  selected ? const Color(0xFFE64060) : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationSummary(AccountDeletionRequestResult result) {
    final method = result.reauthMethod;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _methodIcon(method),
                color: const Color(0xFFE64060),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Verifikasi dengan ${_methodLabel(method)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _methodDescription(method),
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Color(0xFF64748B),
            ),
          ),
          if (method == accountDeletionOtpMethod &&
              result.expiresInMinutes != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'OTP sudah dikirim ke email Anda dan berlaku selama ${result.expiresInMinutes} menit.',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerificationInput({
    required String method,
    required AccountDeletionRequestResult requestResult,
  }) {
    if (method == accountDeletionPasswordMethod) {
      return _buildPasswordInput();
    }

    if (method == accountDeletionOtpMethod) {
      return _buildOtpInput(requestResult);
    }

    return _buildGoogleConfirmCard();
  }

  Widget _buildPasswordInput() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Masukkan kata sandi saat ini',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'Kata sandi saat ini',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: Color(0xFFE64060), width: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpInput(AccountDeletionRequestResult requestResult) {
    final delivery = requestResult.delivery == null
        ? ''
        : ' melalui ${requestResult.delivery}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Masukkan OTP penghapusan akun',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gunakan 6 digit kode OTP yang baru saja dikirim$delivery.',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
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
        ],
      ),
    );
  }

  Widget _buildGoogleConfirmCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Konfirmasi dengan akun Google',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Saat Anda menekan tombol di bawah, aplikasi akan meminta login ulang ke Google untuk memastikan penghapusan akun benar-benar dilakukan oleh Anda.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required bool isLoading,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFBE123C),
          disabledBackgroundColor: const Color(0xFFFDA4AF),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

class _OtpDotField extends StatefulWidget {
  const _OtpDotField({
    required this.controller,
    required this.validator,
  });

  final TextEditingController controller;
  final String? Function(String?)? validator;

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
