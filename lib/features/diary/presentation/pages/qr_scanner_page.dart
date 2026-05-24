import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/features/dashboard_shell/presentation/providers/dashboard_provider.dart';
import 'package:pulsewise/features/diary/presentation/providers/dashboard_pairing_session_provider.dart';

class QrScannerPage extends ConsumerStatefulWidget {
  const QrScannerPage({super.key});

  @override
  ConsumerState<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends ConsumerState<QrScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    autoStart: true,
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _handled = false;
  bool _isConfirming = false;
  bool _isRestartingScanner = false;

  @override
  void dispose() {
    unawaited(_controller.stop());
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled || _isConfirming) return;

    final code = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (code == null || code.isEmpty) return;

    _handled = true;
    unawaited(_confirmPairing(code));
  }

  Future<void> _restartScanner() async {
    if (_isRestartingScanner || _isConfirming) return;
    _isRestartingScanner = true;
    try {
      await _controller.stop();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await _controller.start();
    } catch (_) {
      // The MobileScanner widget reacts to controller.value.error.
    } finally {
      _isRestartingScanner = false;
    }
  }

  Future<void> _confirmPairing(String qrPayload) async {
    final pairingToken = _extractPairingToken(qrPayload);
    if (pairingToken.isEmpty) {
      if (!mounted) return;
      AppToast.warning(context, 'QR pairing tidak valid.');
      setState(() {
        _handled = false;
        _isConfirming = false;
      });
      return;
    }

    setState(() => _isConfirming = true);

    try {
      final message = await ref
          .read(dashboardPairingSessionApiProvider)
          .confirmPairing(pairingToken: pairingToken);

      if (!mounted) return;

      ref.read(dashboardNavIndexProvider.notifier).state = 2;
      ref.read(pendingDiaryToastMessageProvider.notifier).state = message;
      context.go('/home');
    } catch (error) {
      if (!mounted) return;
      AppToast.error(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
      setState(() {
        _handled = false;
        _isConfirming = false;
      });
      unawaited(_restartScanner());
    }
  }

  String _extractPairingToken(String rawValue) {
    final normalized = rawValue.trim();
    if (normalized.isEmpty) return '';

    try {
      final decoded = jsonDecode(normalized);
      if (decoded is Map) {
        final pairingToken = (decoded['pairingToken'] ??
                decoded['pairing_token'] ??
                decoded['token'])
            ?.toString()
            .trim();
        if ((pairingToken ?? '').isNotEmpty) {
          return pairingToken!;
        }
      }
    } catch (_) {
      // Fallback to URI/plain-string parsing.
    }

    final uri = Uri.tryParse(normalized);
    if (uri != null) {
      for (final key in const ['pairingToken', 'pairing_token', 'token']) {
        final candidate = uri.queryParameters[key]?.trim() ?? '';
        if (candidate.isNotEmpty) {
          return candidate;
        }
      }
    }

    return normalized;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'Scan QR',
        onBackPressed: _isConfirming ? null : () => context.pop(),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              overlayBuilder: (context, constraints) {
                return _ScannerOverlay(constraints: constraints);
              },
              errorBuilder: (context, error, child) {
                final isPermissionDenied =
                    error.errorCode == MobileScannerErrorCode.permissionDenied;
                final message = isPermissionDenied
                    ? 'Izin kamera belum diberikan. Izinkan kamera agar QR bisa dipindai.'
                    : (error.errorDetails?.message?.trim().isNotEmpty ?? false)
                        ? error.errorDetails!.message!
                        : 'Kamera gagal dibuka. Coba lagi.';

                return ColoredBox(
                  color: const Color(0xFF101828),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: 56,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Kamera Belum Siap',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isConfirming ? null : _restartScanner,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE64060),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text(
                                'Coba Lagi',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          if (isPermissionDenied) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _isConfirming
                                    ? null
                                    : () => openAppSettings(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white24),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(Icons.settings_outlined),
                                label: const Text(
                                  'Buka Pengaturan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 172,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ToolbarActionButton(
                  icon: Icons.flash_on,
                  onTap: _isConfirming ? null : () => _controller.toggleTorch(),
                ),
                _ToolbarActionButton(
                  icon: Icons.cameraswitch_rounded,
                  onTap:
                      _isConfirming ? null : () => _controller.switchCamera(),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ScannerBottomPanel(
              isBusy: _isConfirming,
              onShowQrCode: () => context.push('/home/diary-qr'),
            ),
          ),
          if (_isConfirming)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.55),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.white,
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Menghubungkan dashboard dokter...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ToolbarActionButton extends StatelessWidget {
  const _ToolbarActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: onTap == null ? 0.45 : 1,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.78),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay({
    required this.constraints,
  });

  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final width = constraints.maxWidth;
    final frameSize = width * 0.68;
    final topOffset = MediaQuery.of(context).padding.top + 118;

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: topOffset),
        child: SizedBox(
          width: frameSize,
          height: frameSize,
          child: const Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                child: _ScannerCorner(
                  top: true,
                  left: true,
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: _ScannerCorner(
                  top: true,
                  left: false,
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: _ScannerCorner(
                  top: false,
                  left: true,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: _ScannerCorner(
                  top: false,
                  left: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerCorner extends StatelessWidget {
  const _ScannerCorner({
    required this.top,
    required this.left,
  });

  final bool top;
  final bool left;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        border: Border(
          top: top
              ? const BorderSide(color: Color(0xFF475467), width: 4)
              : BorderSide.none,
          bottom: !top
              ? const BorderSide(color: Color(0xFF475467), width: 4)
              : BorderSide.none,
          left: left
              ? const BorderSide(color: Color(0xFF475467), width: 4)
              : BorderSide.none,
          right: !left
              ? const BorderSide(color: Color(0xFF475467), width: 4)
              : BorderSide.none,
        ),
      ),
    );
  }
}

class _ScannerBottomPanel extends StatelessWidget {
  const _ScannerBottomPanel({
    required this.isBusy,
    required this.onShowQrCode,
  });

  final bool isBusy;
  final VoidCallback onShowQrCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Container(
            //   width: 44,
            //   height: 5,
            //   decoration: BoxDecoration(
            //     color: const Color(0xFFE2E8F0),
            //     borderRadius: BorderRadius.circular(999),
            //   ),
            // ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isBusy ? null : onShowQrCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.white.withOpacity(0.9),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                    color: const Color(0xFF9E9E9E).withOpacity(0.3),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.qr_code_2_rounded,
                    color: Color(0xFF101828)),
                label: const Text(
                  'Tampilkan QR Kode',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Arahkan kamera ke QR pairing dashboard dokter untuk menghubungkan sesi dengan cepat.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
