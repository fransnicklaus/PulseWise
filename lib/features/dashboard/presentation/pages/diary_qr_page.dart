import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DiaryQrPage extends StatefulWidget {
  const DiaryQrPage({super.key});

  @override
  State<DiaryQrPage> createState() => _DiaryQrPageState();
}

class _DiaryQrPageState extends State<DiaryQrPage> {
  String? _lastScannedCode;

  @override
  Widget build(BuildContext context) {
    const userId = 'PW-USER-938271';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                    ),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'QR User ID',
                    style: TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () async {
                      final scanned =
                          await context.push<String>('/home/diary-qr/scan');
                      if (!mounted || scanned == null || scanned.isEmpty)
                        return;
                      setState(() => _lastScannedCode = scanned);
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFFE5EA),
                    ),
                    icon: const Icon(
                      Icons.qr_code_scanner,
                      color: Color(0xFFE64060),
                    ),
                    tooltip: 'Scan QR',
                  ),
                ],
              ),
            ),
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
                          'Scan QR untuk identifikasi pengguna',
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
                          child: QrImageView(
                            data: userId,
                            version: QrVersions.auto,
                            size: 220,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'User ID',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          userId,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                        if (_lastScannedCode != null) ...[
                          const SizedBox(height: 18),
                          const Divider(color: Color(0xFFE2E8F0), height: 1),
                          const SizedBox(height: 14),
                          const Text(
                            'Hasil Scan Terakhir',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            _lastScannedCode!,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
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
