import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/notifications/fcm_service.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/features/medication/data/models/manual_medication_reminder_notification_response.dart';
import 'package:pulsewise/features/medication/presentation/providers/manual_medication_reminder_notification_provider.dart';

class FcmTokenPage extends ConsumerStatefulWidget {
  const FcmTokenPage({super.key});

  @override
  ConsumerState<FcmTokenPage> createState() => _FcmTokenPageState();
}

class _FcmTokenPageState extends ConsumerState<FcmTokenPage> {
  static const _testUserId = '7bb66c07-5ee0-41a2-bf44-a2a598eb9c55';
  static const _testMedicationId = '23150c85-f0a6-4c96-ace2-1d5b0238b092';
  static const _testReminderId = '0413f417-b909-4078-8ae1-959d7eeb352a';
  static const _testStatus = 'Open';

  bool _isLoading = true;
  bool _isSendingReminderTest = false;
  String? _appId;
  String? _token;
  String? _error;
  NotificationSettings? _notificationSettings;
  DateTime? _lastReminderScheduledAt;
  String? _lastReminderError;
  ManualMedicationReminderNotificationResponse? _lastReminderResponse;

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
    final appId = await AppFcmService.instance.getOrCreateAppId(
      printToDebugger: true,
    );
    final token = await AppFcmService.instance.getBestAvailableToken(
      printToDebugger: true,
    );
    final notificationSettings =
        await AppFcmService.instance.getNotificationSettings();

    if (!mounted) return;
    setState(() {
      _appId = appId;
      _token = token;
      _notificationSettings = notificationSettings;
      _error = AppFcmService.instance.lastError;
      _isLoading = false;
    });
  }

  Future<void> _copyAppId() async {
    final appId = _appId;
    if (appId == null || appId.trim().isEmpty) {
      AppToast.warning(context, 'App ID belum tersedia.');
      return;
    }

    await Clipboard.setData(ClipboardData(text: appId));
    debugPrint('[FCM_APP_ID] $appId');

    if (!mounted) return;
    AppToast.success(context, 'App ID disalin dan dicetak ke debugger.');
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

  Future<void> _printToken(String appId) async {
    final token = await AppFcmService.instance.getBestAvailableToken(
      printToDebugger: true,
    );

    if (!mounted) return;
    if (token == null || token.trim().isEmpty) {
      AppToast.warning(context, 'Token FCM belum tersedia.');
      return;
    }

    print('[FCM_APP_ID] $appId');
    print('[FCM_TOKEN] $token');

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

  Future<void> _sendMedicationReminderTest() async {
    if (_isSendingReminderTest) return;

    final scheduledAt = DateTime.now();

    setState(() {
      _isSendingReminderTest = true;
      _lastReminderScheduledAt = scheduledAt;
      _lastReminderError = null;
    });

    try {
      final response = await ref
          .read(manualMedicationReminderNotificationApiProvider)
          .sendReminder(
            userId: _testUserId,
            medicationId: _testMedicationId,
            reminderId: _testReminderId,
            scheduledAt: scheduledAt,
            status: _testStatus,
          );

      if (!mounted) return;
      setState(() {
        _isSendingReminderTest = false;
        _lastReminderResponse = response;
        _lastReminderError = null;
      });

      AppToast.success(context, response.message);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');

      setState(() {
        _isSendingReminderTest = false;
        _lastReminderResponse = null;
        _lastReminderError = message;
      });

      AppToast.error(context, message);
    }
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

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatScheduledAt(DateTime date) {
    return '${_formatDate(date)} ${_formatTime(date)}';
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
                                  'App ID Installasi',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SelectableText(
                                  (_appId != null && _appId!.trim().isNotEmpty)
                                      ? _appId!
                                      : 'Belum ada App ID yang tersedia.',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF475569),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
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
                          label: 'Salin App ID',
                          onPressed: _copyAppId,
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
                          onPressed: () => _printToken(_appId ?? ''),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFED7AA)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Test Manual Reminder',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF9A3412),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tombol ini akan memanggil endpoint manual medication reminder dengan tanggal hari ini dan jam saat tombol ditekan.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF9A3412),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const _DetailTextBlock(
                            label: 'User ID',
                            value: _testUserId,
                          ),
                          const SizedBox(height: 10),
                          const _DetailTextBlock(
                            label: 'Medication ID',
                            value: _testMedicationId,
                          ),
                          const SizedBox(height: 10),
                          const _DetailTextBlock(
                            label: 'Reminder ID',
                            value: _testReminderId,
                          ),
                          const SizedBox(height: 10),
                          const _DetailTextBlock(
                            label: 'Status',
                            value: _testStatus,
                          ),
                          if (_lastReminderScheduledAt != null) ...[
                            const SizedBox(height: 10),
                            _DetailTextBlock(
                              label: 'Scheduled At',
                              value: _formatScheduledAt(
                                _lastReminderScheduledAt!,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          _ActionButton(
                            label: 'Tes Reminder Obat',
                            onPressed: _sendMedicationReminderTest,
                            isPrimary: true,
                            isLoading: _isSendingReminderTest,
                          ),
                          if (_lastReminderResponse != null ||
                              _lastReminderError != null) ...[
                            const SizedBox(height: 16),
                            _ManualReminderResultCard(
                              response: _lastReminderResponse,
                              errorMessage: _lastReminderError,
                            ),
                          ],
                        ],
                      ),
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
  final Future<void> Function()? onPressed;
  final bool isPrimary;
  final bool isLoading;

  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.isLoading = false,
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
        onPressed: (onPressed == null || isLoading)
            ? null
            : () async {
                await onPressed!.call();
              },
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
        child: isLoading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        foregroundColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Mengirim...',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : Text(
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

class _DetailTextBlock extends StatelessWidget {
  final String label;
  final String value;

  const _DetailTextBlock({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF9A3412),
          ),
        ),
        const SizedBox(height: 6),
        SelectableText(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF7C2D12),
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _ManualReminderResultCard extends StatelessWidget {
  final ManualMedicationReminderNotificationResponse? response;
  final String? errorMessage;

  const _ManualReminderResultCard({
    required this.response,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final firstResult = (response?.data?.results.isNotEmpty ?? false)
        ? response!.data!.results.first
        : null;
    final isError = errorMessage != null && errorMessage!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isError ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isError ? 'Hasil Terakhir: Error' : 'Hasil Terakhir',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color:
                  isError ? const Color(0xFFB91C1C) : const Color(0xFF166534),
            ),
          ),
          const SizedBox(height: 10),
          if (isError)
            Text(
              errorMessage!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFFB91C1C),
                height: 1.5,
              ),
            )
          else ...[
            _DetailTextBlock(
              label: 'Pesan',
              value: response?.message ?? '-',
            ),
            const SizedBox(height: 10),
            _DetailTextBlock(
              label: 'Sent Count',
              value: '${response?.data?.sentCount ?? 0}',
            ),
            const SizedBox(height: 10),
            _DetailTextBlock(
              label: 'Failed Count',
              value: '${response?.data?.failedCount ?? 0}',
            ),
            if (firstResult != null) ...[
              const SizedBox(height: 10),
              _DetailTextBlock(
                label: 'Result Status',
                value: firstResult.status,
              ),
              const SizedBox(height: 10),
              _DetailTextBlock(
                label: 'Platform',
                value: firstResult.platform ?? '-',
              ),
              if ((firstResult.messageId ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                _DetailTextBlock(
                  label: 'Message ID',
                  value: firstResult.messageId!,
                ),
              ],
              if ((firstResult.error ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                _DetailTextBlock(
                  label: 'Error',
                  value: firstResult.error!,
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}
