import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/features/diary/data/models/patient_share_models.dart';
import 'package:pulsewise/features/diary/presentation/providers/patient_share_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DiaryQrPage extends ConsumerStatefulWidget {
  const DiaryQrPage({super.key});

  @override
  ConsumerState<DiaryQrPage> createState() => _DiaryQrPageState();
}

class _DiaryQrPageState extends ConsumerState<DiaryQrPage> {
  PatientShare? _share;
  String? _shareError;
  bool _isLoadingShare = true;

  @override
  void initState() {
    super.initState();
    _createShare();
  }

  Future<void> _createShare() async {
    setState(() {
      _isLoadingShare = true;
      _share = null;
      _shareError = null;
    });

    try {
      final share = await ref.read(patientShareApiProvider).createShare(
            expiresInHours: 24,
          );
      if (!mounted) return;
      setState(() {
        _share = share;
        _isLoadingShare = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _share = null;
        _shareError = error.toString().replaceFirst('Exception: ', '');
        _isLoadingShare = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'QR Share Pasien',
        // subtitle: 'Tambahkan kontak darurat baru',
        showBackButton: true,
        onBackPressed: () => context.pop(),
        // action: IconButton(
        //   onPressed: () async {
        //     final scanned = await context.push<String>('/home/diary-qr/scan');
        //     if (!mounted || scanned == null || scanned.isEmpty) return;
        //     setState(() => _lastScannedCode = scanned);
        //   },
        //   style: IconButton.styleFrom(
        //     backgroundColor: const Color(0xFFFFE5EA),
        //   ),
        //   icon: const Icon(
        //     Icons.qr_code_scanner,
        //     color: Color(0xFFE64060),
        //   ),
        //   tooltip: 'Scan QR',
        // ),
      ),
      body: SafeArea(
        key: const Key('patient_diary_qr_share_content'),
        child: Column(
          children: [
            // Container(
            //   width: double.infinity,
            //   padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            //   decoration: const BoxDecoration(
            //     color: Colors.white,
            //     border: Border(
            //       bottom: BorderSide(color: Color(0xFFE2E8F0)),
            //     ),
            //   ),
            //   child: Row(
            //     children: [
            //       IconButton(
            //         onPressed: () => context.pop(),
            //         style: IconButton.styleFrom(
            //           backgroundColor: const Color(0xFFF1F5F9),
            //         ),
            //         icon: const Icon(
            //           Icons.arrow_back,
            //           color: Color(0xFF475569),
            //         ),
            //       ),
            //       const SizedBox(width: 10),
            //       const Text(
            //         'QR User ID',
            //         style: TextStyle(
            //           color: Color(0xFF334155),
            //           fontSize: 20,
            //           fontWeight: FontWeight.w700,
            //         ),
            //       ),
            //       const Spacer(),
            //       IconButton(
            //         onPressed: () async {
            //           final scanned =
            //               await context.push<String>('/home/diary-qr/scan');
            //           if (!mounted || scanned == null || scanned.isEmpty)
            //             return;
            //           setState(() => _lastScannedCode = scanned);
            //         },
            //         style: IconButton.styleFrom(
            //           backgroundColor: const Color(0xFFFFE5EA),
            //         ),
            //         icon: const Icon(
            //           Icons.qr_code_scanner,
            //           color: Color(0xFFE64060),
            //         ),
            //         tooltip: 'Scan QR',
            //       ),
            //     ],
            //   ),
            // ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Tunjukkan QR ini ke dokter untuk menghubungkan akun.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: _isLoadingShare
                              ? const SizedBox(
                                  width: 220,
                                  height: 220,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : _share != null
                                  ? QrImageView(
                                      data: _share!.qrData,
                                      version: QrVersions.auto,
                                      size: 220,
                                      backgroundColor: Colors.white,
                                    )
                                  : SizedBox(
                                      width: 220,
                                      height: 220,
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Text(
                                            _shareError ??
                                                'QR share tidak tersedia.\nSilakan coba lagi.',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Color(0xFF64748B),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                        ),
                        const SizedBox(height: 16),
                        if (_share != null) ...[
                          const Text(
                            'Kode Share',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            _share!.shareCode,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                          if (_share!.expiresAt.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Berlaku hingga ${_share!.expiresAt}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ] else ...[
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isLoadingShare ? null : _createShare,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFE64060),
                                side: const BorderSide(
                                  color: Color(0xFFE64060),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text(
                                'Buat Ulang QR',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (_share != null) ...[
                          const SizedBox(height: 18),
                          const Divider(color: Color(0xFFE2E8F0), height: 1),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isLoadingShare ? null : _createShare,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFE64060),
                                side: const BorderSide(
                                  color: Color(0xFFFBC9D4),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text(
                                'Buat QR Baru',
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
