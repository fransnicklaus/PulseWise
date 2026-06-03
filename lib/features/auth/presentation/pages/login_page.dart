import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/constants/app_roles.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/features/auth/presentation/providers/auth_provider.dart';
import 'package:pulsewise/features/auth/presentation/widgets/google_sign_in_entry_button.dart';
import 'package:pulsewise/features/doctor_shell/presentation/providers/doctor_dashboard_provider.dart';
import 'package:pulsewise/features/dashboard_shell/presentation/providers/dashboard_provider.dart';
import 'package:pulsewise/features/profile/presentation/providers/profile_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final GoogleSignIn _googleSignIn;
  StreamSubscription<GoogleSignInAccount?>? _googleUserSubscription;
  bool _isHandlingWebGoogleUser = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _googleSignIn = buildGoogleSignInClient();
    if (kIsWeb) {
      _googleUserSubscription = _googleSignIn.onCurrentUserChanged.listen((
        account,
      ) {
        if (account == null || _isHandlingWebGoogleUser) return;
        unawaited(_handleWebGoogleAccount(account));
      });
    }
  }

  void _logGoogleUi(String message) {
    debugPrint('[LoginPage][Google] $message');
  }

  void _navigateAfterLogin({
    required String? role,
    String? nextStep,
    String? accountStatus,
  }) {
    if (!mounted) return;

    final normalizedRole = normalizeAppRole(role);
    final targetRoute = routeForRoleSession(
      role: normalizedRole,
      nextStep: nextStep,
      accountStatus: accountStatus,
    );
    if (normalizedRole == AppRoles.doctor) {
      ref.read(doctorDashboardNavIndexProvider.notifier).state = 0;
      ref.read(healthConnectLoginPromptArmedProvider.notifier).state = false;
      context.go(targetRoute);
      return;
    }

    ref.read(previousNavIndexProvider.notifier).state = 0;
    ref.read(dashboardNavIndexProvider.notifier).state = 0;
    ref.read(healthConnectLoginPromptArmedProvider.notifier).state = true;
    ref.invalidate(authMeProvider);
    ref.invalidate(patientProfileProvider);
    context.go(targetRoute);
  }

  @override
  void dispose() {
    _googleUserSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    if (email.isNotEmpty && password.isNotEmpty) {
      await ref.read(authProvider.notifier).login(email, password);
      if (!mounted) return;

      final authState = ref.read(authProvider);
      if (authState.isAuthenticated) {
        _navigateAfterLogin(
          role: authState.role,
          nextStep: authState.nextStep,
          accountStatus: authState.accountStatus,
        );
      } else if (isDoctorPendingAdminVerification(
        role: authState.role,
        nextStep: authState.nextStep,
        accountStatus: authState.accountStatus,
      )) {
        AppToast.info(
          context,
          'Akun dokter sedang menunggu verifikasi admin. Lengkapi profil dulu ya.',
        );
        _navigateAfterLogin(
          role: authState.role,
          nextStep: authState.nextStep,
          accountStatus: authState.accountStatus,
        );
      } else if (authState.error != null && authState.error!.isNotEmpty) {
        AppToast.error(context, authState.error!);
      }
    } else {
      AppToast.warning(context, 'Email dan kata sandi wajib diisi');
    }
  }

  Future<void> _onGoogleLogin() async {
    _logGoogleUi('Button tapped, dismissing keyboard');
    FocusScope.of(context).unfocus();
    _logGoogleUi('Calling authProvider.loginWithGoogle');
    final result = await ref.read(authProvider.notifier).loginWithGoogle();
    if (!mounted) return;

    final authState = ref.read(authProvider);
    _logGoogleUi(
      'Provider result isAuthenticated=${authState.isAuthenticated} error=${authState.error}',
    );

    _handleGoogleResult(result);
  }

  Future<void> _handleWebGoogleAccount(GoogleSignInAccount account) async {
    _isHandlingWebGoogleUser = true;
    try {
      final authentication = await account.authentication;
      final idToken = authentication.idToken;
      if (!mounted) return;

      if (idToken == null || idToken.isEmpty) {
        AppToast.error(
          context,
          'idToken Google tidak tersedia di browser. Pastikan Web Client ID sudah benar.',
        );
        return;
      }

      final result =
          await ref.read(authProvider.notifier).loginWithGoogleIdToken(idToken);
      if (!mounted) return;
      _handleGoogleResult(result);
    } catch (error) {
      if (!mounted) return;
      AppToast.error(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      _isHandlingWebGoogleUser = false;
    }
  }

  void _handleGoogleResult(GoogleAuthFlowResult result) {
    if (!mounted) return;
    if (!result.success) {
      _logGoogleUi('Showing error toast');
      AppToast.error(
        context,
        result.message ?? 'Login Google gagal. Silakan coba lagi.',
      );
      return;
    }

    if (result.nextStep == GoogleAuthNextStep.home &&
        ref.read(authProvider).isAuthenticated) {
      _logGoogleUi(
        'Navigation to ${homeRouteForRole(result.role)} for role=${result.role}',
      );
      _navigateAfterLogin(
        role: result.role,
        nextStep: AppAuthNextSteps.home,
        accountStatus: result.accountStatus,
      );
      return;
    }

    if (result.nextStep == GoogleAuthNextStep.waitAdminVerification) {
      AppToast.info(
        context,
        'Akun dokter sedang menunggu verifikasi admin. Lengkapi profil dulu ya.',
      );
      _navigateAfterLogin(
        role: result.role,
        nextStep: AppAuthNextSteps.waitAdminVerification,
        accountStatus: result.accountStatus,
      );
      return;
    }

    if (result.nextStep == GoogleAuthNextStep.completeRegistration) {
      _logGoogleUi('Navigation to /login/register (google flow)');
      context.push(
        '/login/register',
        extra: {
          'flow': 'google',
          'registrationToken': result.registrationToken,
          'email': result.email,
          'role': result.role,
          'idToken': result.idToken,
          'firstName': result.firstName,
          'lastName': result.lastName,
          'startAtOtp': false,
        },
      );
      return;
    }

    if (result.nextStep == GoogleAuthNextStep.verifyOtp) {
      _logGoogleUi('Navigation to /login/register (google otp step)');
      context.push(
        '/login/register',
        extra: {
          'flow': 'google',
          'email': result.email,
          'role': result.role,
          'idToken': result.idToken,
          'startAtOtp': true,
        },
      );
      return;
    }

    AppToast.error(
      context,
      'Alur Google tidak dikenali. Silakan coba lagi.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background Gradient
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

          // Scrollable Content
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
                      // White Container
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(
                            top: 56), // space for logo overlap
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
                            children: [
                              const Text(
                                'Masuk',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Product Sans',
                                  color: Color(0xFF536278),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  hintText: 'Alamat Email',
                                  hintStyle: const TextStyle(
                                    color: Color.fromRGBO(83, 98, 120, 0.5),
                                    fontWeight: FontWeight.normal,
                                  ),
                                  prefixIcon: const Icon(
                                    FluentIcons.mail_24_regular,
                                    color: Color(0xFF536278),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF9FBFD),
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 18, horizontal: 16),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE64060)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  hintText: 'Kata Sandi',
                                  hintStyle: const TextStyle(
                                    color: Color.fromRGBO(83, 98, 120, 0.5),
                                    fontWeight: FontWeight.normal,
                                  ),
                                  prefixIcon: const Icon(
                                    FluentIcons.lock_closed_24_regular,
                                    color: Color(0xFF536278),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? FluentIcons.eye_24_regular
                                          : FluentIcons.eye_off_24_regular,
                                      color: const Color(0xFF536278),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF9FBFD),
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 18, horizontal: 16),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE64060)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Forgot Password aligned right
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () =>
                                      context.push('/login/forgot-password'),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Lupa Sandi',
                                    style: TextStyle(
                                      color: Color(0xFF536278),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // MASUK Button
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed:
                                      authState.isLoading ? null : _onLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE64060),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: authState.isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'MASUK',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Or login with
                              const Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Color(0xFFE2E8F0),
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Text(
                                      'atau masuk dengan',
                                      style: TextStyle(
                                        color: Color(0xFF536278),
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Color(0xFFE2E8F0),
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              GoogleSignInEntryButton(
                                googleSignIn: _googleSignIn,
                                isLoading: authState.isLoading,
                                onPressed: _onGoogleLogin,
                              ),

                              const Spacer(),

                              // Register Text
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Belum punya akun? ',
                                    style: TextStyle(
                                        color: Color(0xFF536278), fontSize: 14),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      context.go('/login/register');
                                    },
                                    child: const Text(
                                      'Buat Akun',
                                      style: TextStyle(
                                        color: Color(0xFFE64060),
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Color(0xFFE64060),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Heart Logo (Positioned explicitly to overlap container)
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
          )
        ],
      ),
    );
  }
}
