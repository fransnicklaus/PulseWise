import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/features/auth/presentation/providers/auth_provider.dart';
import 'package:pulsewise/features/dashboard_shell/presentation/providers/dashboard_provider.dart';
import 'package:pulsewise/features/dashboard/presentation/providers/profile_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _logGoogleUi(String message) {
    debugPrint('[LoginPage][Google] $message');
  }

  @override
  void dispose() {
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
        ref.read(previousNavIndexProvider.notifier).state = 0;
        ref.read(dashboardNavIndexProvider.notifier).state = 0;
        ref.read(healthConnectLoginPromptArmedProvider.notifier).state = true;
        // Invalidate profile-related providers so they refetch with the new token
        ref.invalidate(authMeProvider);
        ref.invalidate(patientProfileProvider);
        context.go('/home');
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

    if (!result.success) {
      _logGoogleUi('Showing error toast');
      // AppToast.error(context, message);
      return;
    }

    if (result.nextStep == GoogleAuthNextStep.home &&
        authState.isAuthenticated) {
      ref.read(previousNavIndexProvider.notifier).state = 0;
      ref.read(dashboardNavIndexProvider.notifier).state = 0;
      ref.read(healthConnectLoginPromptArmedProvider.notifier).state = true;
      // Force refetch of auth/me and profile after Google login
      ref.invalidate(authMeProvider);
      ref.invalidate(patientProfileProvider);
      _logGoogleUi('Navigation to /home');
      context.go('/home');
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

                              // Google Login
                              OutlinedButton.icon(
                                onPressed:
                                    authState.isLoading ? null : _onGoogleLogin,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFAFAFA),
                                  side: const BorderSide(
                                      color: Color(0xFF536278)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(37),
                                  ),
                                  minimumSize: const Size(240, 55),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                ),
                                icon: SvgPicture.asset(
                                  'assets/svgs/google.svg',
                                  width: 32,
                                  height: 32,
                                ),
                                label: const Text(
                                  'Masuk Dengan Google',
                                  style: TextStyle(
                                    color: Color(0xFF536278),
                                    fontSize: 16,
                                  ),
                                ),
                              ),

                              const Spacer(),

                              // Register Text
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Belum punya akun? ',
                                    style: TextStyle(color: Color(0xFF536278)),
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
