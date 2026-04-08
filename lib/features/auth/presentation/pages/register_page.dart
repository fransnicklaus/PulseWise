import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/utils/app_toast.dart';

// Assuming we reuse AuthProvider for now, or you can create a separate RegisterProvider
import '../providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegister() async {
    if (_formKey.currentState!.validate()) {
      // Simulate registration
      ref.read(authProvider.notifier).login(
            _emailController.text,
            _passwordController.text,
          );
      // Wait for loading to finish, then go back to login or straight to home
      // For now, simpler to just pop back to login if successful
      if (mounted) {
        AppToast.success(context, 'Simulated Registration Success!');
        context.pop();
      }
    }
  }

  void _onRegisterWithGoogle() {
    ref.read(authProvider.notifier).loginWithGoogle();
    if (mounted) {
      AppToast.info(context, 'Simulated Google Registration Success!');
      context.pop();
    }
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
                      // White Card Container
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(
                            top: 56), // fixed offset for half logo height
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(47),
                            topRight: Radius.circular(47),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 72, 24, 32),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                const Text(
                                  'Buat Akun',
                                  style: TextStyle(
                                    color: Color(0xFF536278),
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Product Sans',
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Username Input
                                TextFormField(
                                  controller: _usernameController,
                                  decoration: InputDecoration(
                                    hintText: 'Nama Pengguna',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF536278),
                                      fontSize: 16,
                                    ),
                                    prefixIcon: const Icon(
                                      FluentIcons.person_24_regular,
                                      color: Color(0xFF536278),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF9FBFD),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Silakan masukkan nama pengguna';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Email Input
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    hintText: 'Alamat Email',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF536278),
                                      fontSize: 16,
                                    ),
                                    prefixIcon: const Icon(
                                      FluentIcons.mail_24_regular,
                                      color: Color(0xFF536278),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF9FBFD),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Silakan masukkan alamat email';
                                    }
                                    // Basic email validation
                                    if (!value.contains('@')) {
                                      return 'Masukkan email yang valid';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Password Input
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: !_isPasswordVisible,
                                  decoration: InputDecoration(
                                    hintText: 'Kata Sandi',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF536278),
                                      fontSize: 16,
                                    ),
                                    prefixIcon: const Icon(
                                      FluentIcons.lock_closed_24_regular,
                                      color: Color(0xFF536278),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? FluentIcons.eye_24_regular
                                            : FluentIcons.eye_off_24_regular,
                                        color: const Color(0xFF536278),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible =
                                              !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF9FBFD),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Silakan masukkan kata sandi';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Confirm Password Input
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: !_isConfirmPasswordVisible,
                                  decoration: InputDecoration(
                                    hintText: 'Ulangi Kata Sandi',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF536278),
                                      fontSize: 16,
                                    ),
                                    prefixIcon: const Icon(
                                      FluentIcons.lock_closed_24_regular,
                                      color: Color(0xFF536278),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isConfirmPasswordVisible
                                            ? FluentIcons.eye_24_regular
                                            : FluentIcons.eye_off_24_regular,
                                        color: const Color(0xFF536278),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isConfirmPasswordVisible =
                                              !_isConfirmPasswordVisible;
                                        });
                                      },
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF9FBFD),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0),
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Silakan ulangi kata sandi';
                                    }
                                    if (value != _passwordController.text) {
                                      return 'Kata sandi tidak cocok';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 32),

                                // Submit Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton(
                                    onPressed: authState.isLoading
                                        ? null
                                        : _onRegister,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFE64060),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: authState.isLoading
                                        ? const CircularProgressIndicator(
                                            color: Colors.white,
                                          )
                                        : const Text(
                                            'BUAT AKUN',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Divider "atau masuk dengan"
                                const Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: Color(0xFF536278),
                                        thickness: 1,
                                      ),
                                    ),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'atau masuk dengan',
                                        style: TextStyle(
                                          color: Color(0xFF536278),
                                          fontSize: 16,
                                          fontStyle: FontStyle.italic,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: Color(0xFF536278),
                                        thickness: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Google Login Button
                                SizedBox(
                                  height: 55,
                                  child: OutlinedButton.icon(
                                    onPressed: authState.isLoading
                                        ? null
                                        : _onRegisterWithGoogle,
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFAFAFA),
                                      side: const BorderSide(
                                          color: Color(0xFF536278)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(37),
                                      ),
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
                                ),

                                const SizedBox(height: 10),

                                // Bottom Text "Sudah punya akun? Masuk"
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Sudah punya akun? ',
                                      style: TextStyle(
                                        color: Color(0xFF536278),
                                        fontSize: 16,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        context
                                            .pop(); // Returns to /login route
                                      },
                                      child: const Text(
                                        'Masuk',
                                        style: TextStyle(
                                          color: Color(0xFFE64060),
                                          fontSize: 16,
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
                      ),

                      // Heart Logo (Positioned explicitly to overlap container)
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
