import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/features/doctor/presentation/providers/doctor_dashboard_provider.dart';
import 'package:pulsewise/features/doctor_shell/presentation/providers/doctor_dashboard_provider.dart'
    as shell;

class DoctorQrTab extends ConsumerStatefulWidget {
  const DoctorQrTab({super.key});

  @override
  ConsumerState<DoctorQrTab> createState() => _DoctorQrTabState();
}

class _DoctorQrTabState extends ConsumerState<DoctorQrTab> {
  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  final MobileScannerController _controller = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _handled = false;
  bool _isResolvingPatient = false;
  bool _isRestartingScanner = false;
  bool _isCameraRunning = false;
  bool _isSyncingCamera = false;
  bool? _lastShouldRunCamera;

  @override
  void dispose() {
    unawaited(_controller.stop());
    _controller.dispose();
    super.dispose();
  }

  void _syncCameraState(bool shouldRunCamera) {
    if (_lastShouldRunCamera == shouldRunCamera) return;
    _lastShouldRunCamera = shouldRunCamera;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_setCameraRunning(shouldRunCamera));
    });
  }

  Future<void> _setCameraRunning(bool shouldRunCamera) async {
    if (_isSyncingCamera) return;
    if (shouldRunCamera == _isCameraRunning) return;

    _isSyncingCamera = true;
    try {
      if (shouldRunCamera) {
        await _controller.start();
      } else {
        await _controller.stop();
      }
      _isCameraRunning = shouldRunCamera;
    } catch (_) {
      // Let MobileScanner surface the controller error in the UI.
    } finally {
      _isSyncingCamera = false;
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled || _isResolvingPatient) return;

    final rawValue = capture.barcodes.firstOrNull?.rawValue?.trim() ?? '';
    if (rawValue.isEmpty) return;

    if (!_uuidRegex.hasMatch(rawValue)) {
      AppToast.warning(context, 'QR pasien tidak valid.');
      unawaited(_restartScanner());
      return;
    }

    _handled = true;
    unawaited(_openPatientDashboard(rawValue));
  }

  Future<void> _restartScanner() async {
    if (_isRestartingScanner || _isResolvingPatient) return;
    _isRestartingScanner = true;
    try {
      await _controller.stop();
      _isCameraRunning = false;
      await Future<void>.delayed(const Duration(milliseconds: 180));
      await _controller.start();
      _isCameraRunning = true;
      if (mounted) {
        setState(() {
          _handled = false;
        });
      }
    } catch (_) {
      // MobileScanner will surface controller.value.error.
    } finally {
      _isRestartingScanner = false;
    }
  }

  Future<void> _openPatientDashboard(String patientId) async {
    setState(() => _isResolvingPatient = true);
    try {
      final summaryResponse = await ref
          .read(doctorDashboardApiProvider)
          .fetchPatientSummary(patientId);
      final summary = summaryResponse.data;
      if (summary == null) {
        throw Exception('Data pasien dashboard dokter tidak tersedia.');
      }

      await _controller.stop();
      _isCameraRunning = false;

      if (!mounted) return;

      await context.push(
        '/doctor/home/patients/$patientId',
        extra: summary,
      );
    } catch (error) {
      if (!mounted) return;
      AppToast.error(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _handled = false;
          _isResolvingPatient = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final navIndex = ref.watch(shell.doctorDashboardNavIndexProvider);
    final isActive = navIndex == 2;
    _syncCameraState(isActive && !_isResolvingPatient);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              overlayBuilder: (context, constraints) {
                return _DoctorScannerOverlay(constraints: constraints);
              },
              errorBuilder: (context, error, child) {
                final isPermissionDenied =
                    error.errorCode == MobileScannerErrorCode.permissionDenied;
                final message = isPermissionDenied
                    ? 'Izin kamera belum diberikan. Izinkan kamera agar QR pasien bisa dipindai.'
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
                              onPressed:
                                  _isResolvingPatient ? null : _restartScanner,
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
                                onPressed: _isResolvingPatient
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.42),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      'Scan QR Pasien',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.36),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      'Arahkan kamera ke QR pasien. QR berisi userId pasien dan akan membuka dashboard metrik dokter.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _DoctorToolbarActionButton(
                        icon: Icons.flash_on,
                        onTap: _isResolvingPatient
                            ? null
                            : () => _controller.toggleTorch(),
                      ),
                      _DoctorToolbarActionButton(
                        icon: Icons.cameraswitch_rounded,
                        onTap: _isResolvingPatient
                            ? null
                            : () => _controller.switchCamera(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 132),
                ],
              ),
            ),
          ),
          if (_isResolvingPatient)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.55),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 18),
                      Text(
                        'Membuka dashboard pasien...',
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

class _DoctorToolbarActionButton extends StatelessWidget {
  const _DoctorToolbarActionButton({
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

class _DoctorScannerOverlay extends StatelessWidget {
  const _DoctorScannerOverlay({
    required this.constraints,
  });

  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final width = constraints.maxWidth;
    final frameSize = width * 0.68;
    final topOffset = MediaQuery.of(context).padding.top + 180;

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
                child: _DoctorScannerCorner(top: true, left: true),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: _DoctorScannerCorner(top: true, left: false),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: _DoctorScannerCorner(top: false, left: true),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: _DoctorScannerCorner(top: false, left: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorScannerCorner extends StatelessWidget {
  const _DoctorScannerCorner({
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
