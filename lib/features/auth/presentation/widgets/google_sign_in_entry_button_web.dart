import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GoogleSignInEntryButton extends StatelessWidget {
  const GoogleSignInEntryButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
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
    );
  }
}
