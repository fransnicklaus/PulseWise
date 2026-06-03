import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';

class GoogleSignInEntryButton extends StatelessWidget {
  const GoogleSignInEntryButton({
    super.key,
    required this.googleSignIn,
    required this.isLoading,
    required this.onPressed,
  });

  final GoogleSignIn googleSignIn;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final platform = GoogleSignInPlatform.instance;
    if (platform is! GoogleSignInPlugin) {
      return OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFFAFAFA),
          side: const BorderSide(color: Color(0xFF536278)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(37),
          ),
          minimumSize: const Size(240, 55),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        icon: const Icon(Icons.login_rounded, color: Color(0xFF536278)),
        label: const Text(
          'Masuk Dengan Google',
          style: TextStyle(
            color: Color(0xFF536278),
            fontSize: 16,
          ),
        ),
      );
    }

    return IgnorePointer(
      ignoring: isLoading,
      child: Opacity(
        opacity: isLoading ? 0.72 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 46,
              child: platform.renderButton(
                configuration: GSIButtonConfiguration(
                  theme: GSIButtonTheme.outline,
                  text: GSIButtonText.continueWith,
                  size: GSIButtonSize.large,
                  shape: GSIButtonShape.pill,
                  logoAlignment: GSIButtonLogoAlignment.left,
                  minimumWidth: 320,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gunakan tombol Google resmi untuk login di browser.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
