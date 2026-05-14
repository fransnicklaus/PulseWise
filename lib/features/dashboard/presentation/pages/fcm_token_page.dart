import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pulsewise/core/notifications/fcm_service.dart';
import 'package:pulsewise/core/utils/app_toast.dart';

class FcmTokenPage extends StatefulWidget {
  const FcmTokenPage({super.key});

  @override
  State<FcmTokenPage> createState() => _FcmTokenPageState();
}

class _FcmTokenPageState extends State<FcmTokenPage> {
  bool _isLoading = true;
  String? _token;
  String? _error;
  NotificationSettings? _notificationSettings;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    setState(() {
      _isLoading = true;
    });

    await AppFcmService.instance.initialize();
    final token = await AppFcmService.instance.getBestAvailableToken(
      printToDebugger: true,
    );
    final notificationSettings =
        await AppFcmService.instance.getNotificationSettings();

    if (!mounted) return;
    setState(() {
      _token = token;
      _notificationSettings = notificationSettings;
      _error = AppFcmService.instance.lastError;
      _isLoading = false;
    });
  }

  Future<void> _copyToken() async {
    final token = _token;
    if (token == null || token.trim().isEmpty) {
      AppToast.warning(context, 'Token FCM belum tersedia.');
      return;
    }

    await Clipboard.setData(ClipboardData(text: token));
    debugPrint('[FCM_TOKEN] $token');

    if (!mounted) return;
    AppToast.success(context, 'Token FCM disalin dan dicetak ke debugger.');
  }

  Future<void> _printToken() async {
    final token = await AppFcmService.instance.getBestAvailableToken(
      printToDebugger: true,
    );

    if (!mounted) return;
    if (token == null || token.trim().isEmpty) {
      AppToast.warning(context, 'Token FCM belum tersedia.');
      return;
    }

    AppToast.info(context, 'Token FCM dicetak ke debugger.');
  }

  Future<void> _requestPermission() async {
    final settings =
        await AppFcmService.instance.requestNotificationPermission();
    final token = await AppFcmService.instance.getBestAvailableToken(
      printToDebugger: true,
    );

    if (!mounted) return;
    setState(() {
      _notificationSettings = settings ?? _notificationSettings;
      _token = token ?? _token;
      _error = AppFcmService.instance.lastError;
    });

    AppToast.info(
      context,
      'Status izin notifikasi diperbarui.',
    );
  }

  String _permissionLabel(NotificationSettings? settings) {
    final status = settings?.authorizationStatus;
    if (status == null) return 'Belum diketahui';

    switch (status) {
      case AuthorizationStatus.authorized:
        return 'Diizinkan';
      case AuthorizationStatus.denied:
        return 'Ditolak';
      case AuthorizationStatus.notDetermined:
        return 'Belum diminta';
      case AuthorizationStatus.provisional:
        return 'Provisional';
      default:
        return status.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'FCM Device Token',
          style: TextStyle(
            color: Color(0xFF334155),
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
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
                      'Token ini dipakai untuk testing push notification FCM ke perangkat ini.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoTile(
                            title: 'Firebase',
                            value: AppFcmService.instance.isReady
                                ? 'Siap'
                                : 'Belum siap',
                            valueColor: AppFcmService.instance.isReady
                                ? const Color(0xFF15803D)
                                : const Color(0xFFB91C1C),
                            backgroundColor: AppFcmService.instance.isReady
                                ? const Color(0xFFECFDF3)
                                : const Color(0xFFFEF2F2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _InfoTile(
                            title: 'Izin Notifikasi',
                            value: _permissionLabel(_notificationSettings),
                            valueColor: const Color(0xFF334155),
                            backgroundColor: const Color(0xFFF8FAFC),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: _isLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Token Perangkat',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SelectableText(
                                  (_token != null && _token!.trim().isNotEmpty)
                                      ? _token!
                                      : 'Belum ada token FCM yang tersedia.',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF475569),
                                    height: 1.5,
                                  ),
                                ),
                                if (_error != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    _error!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFB91C1C),
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _ActionButton(
                          label: 'Refresh Token',
                          onPressed: _loadToken,
                          isPrimary: true,
                        ),
                        _ActionButton(
                          label: 'Salin Token',
                          onPressed: _copyToken,
                        ),
                        _ActionButton(
                          label: 'Minta Izin',
                          onPressed: _requestPermission,
                        ),
                        _ActionButton(
                          label: 'Print Debugger',
                          onPressed: _printToken,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;
  final Color backgroundColor;

  const _InfoTile({
    required this.title,
    required this.value,
    required this.valueColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Future<void> Function() onPressed;
  final bool isPrimary;

  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isPrimary ? Colors.white : const Color(0xFF475569);
    final backgroundColor = isPrimary ? const Color(0xFFE64060) : Colors.white;
    final sideColor =
        isPrimary ? const Color(0xFFE64060) : const Color(0xFFD9E2EC);

    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          foregroundColor: foregroundColor,
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          side: BorderSide(color: sideColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
