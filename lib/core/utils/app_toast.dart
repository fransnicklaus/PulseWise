import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

class AppToast {
  static Future<void> success(BuildContext context, String message) {
    return _show(
      context,
      message: message,
      title: 'Sukses',
      icon: Icons.check_circle_rounded,
      color: const Color(0xFF16A34A),
    );
  }

  static Future<void> warning(BuildContext context, String message) {
    return _show(
      context,
      message: message,
      title: 'Peringatan',
      icon: Icons.warning_amber_rounded,
      color: const Color(0xFFD97706),
    );
  }

  static Future<void> info(BuildContext context, String message) {
    return _show(
      context,
      message: message,
      title: 'Info',
      icon: Icons.info_rounded,
      color: const Color(0xFF2563EB),
    );
  }

  static Future<void> error(BuildContext context, String message) {
    return _show(
      context,
      message: message,
      title: 'Error',
      icon: Icons.error_rounded,
      color: const Color(0xFFDC2626),
    );
  }

  static Future<void> _show(
    BuildContext context, {
    required String message,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Flushbar<void>(
      titleText: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 17,
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      icon: Icon(icon, color: Colors.white, size: 30),
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      borderRadius: BorderRadius.circular(12),
      backgroundColor: color,
      animationDuration: const Duration(milliseconds: 250),
    ).show(context);
  }
}
