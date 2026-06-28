import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/features/install/presentation/services/pwa_install_prompt.dart';

class InstallPage extends StatefulWidget {
  const InstallPage({super.key});

  static const accent = Color(0xFFE64060);
  static const accentSoft = Color(0xFFFFEEF2);
  static const text = Color(0xFF0F172A);
  static const subtext = Color(0xFF475569);
  static const border = Color(0xFFE2E8F0);

  @override
  State<InstallPage> createState() => _InstallPageState();
}

class _InstallPageState extends State<InstallPage> {
  final _controller = pwaInstallPromptController;
  bool _showManualInstallFallback = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFBFC), Color(0xFFF8FAFC)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final isInstalled = _controller.isInstalled;
                    final canPrompt = _controller.canPromptInstall;
                    final showManualInstall = !isInstalled &&
                        (!canPrompt || _showManualInstallFallback);
                    final instructions = _manualStepsFor(_controller.platform);

                    return Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: InstallPage.border),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x120F172A),
                            blurRadius: 28,
                            offset: Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                'assets/images/android12_splash_icon.png',
                                width: 108,
                                height: 108,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Center(
                            child: Text(
                              'Install PulseWise',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: InstallPage.text,
                                fontSize: 42,
                                height: 1.05,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _descriptionForCurrentState(
                              isInstalled: isInstalled,
                              canPrompt: canPrompt,
                              platform: _controller.platform,
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: InstallPage.subtext,
                              fontSize: 18,
                              height: 1.65,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: InstallPage.accentSoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _statusLabel(
                                  isInstalled: isInstalled,
                                  canPrompt: canPrompt,
                                  platform: _controller.platform,
                                ),
                                style: const TextStyle(
                                  color: InstallPage.accent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (isInstalled || canPrompt)
                            FilledButton(
                              onPressed:
                                  isInstalled ? null : _handleInstallPressed,
                              style: FilledButton.styleFrom(
                                backgroundColor: InstallPage.accent,
                                disabledBackgroundColor:
                                    const Color(0xFFF1F5F9),
                                disabledForegroundColor:
                                    const Color(0xFF94A3B8),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: Text(
                                isInstalled
                                    ? 'App Sudah Terpasang'
                                    : 'Install App',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: const Text(
                              'Masuk tanpa install',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: InstallPage.text,
                              ),
                            ),
                          ),
                          if (showManualInstall) const SizedBox(height: 20),
                          if (showManualInstall)
                            _ManualInstructionsSection(
                              instructions: instructions,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleInstallPressed() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await _controller.promptInstall();
    if (!mounted) return;

    switch (result) {
      case PwaInstallOutcome.accepted:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Prompt install dibuka. Ikuti konfirmasi browser.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case PwaInstallOutcome.dismissed:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Install dibatalkan.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case PwaInstallOutcome.unavailable:
        _showManualInstructionsFallback();
        break;
      case PwaInstallOutcome.alreadyInstalled:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('PulseWise sudah terpasang di perangkat ini.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case PwaInstallOutcome.unsupported:
        _showManualInstructionsFallback();
        break;
      case PwaInstallOutcome.error:
        _showManualInstructionsFallback();
        break;
    }
  }

  void _showManualInstructionsFallback() {
    if (_showManualInstallFallback) return;
    setState(() {
      _showManualInstallFallback = true;
    });
  }

  String _descriptionForCurrentState({
    required bool isInstalled,
    required bool canPrompt,
    required PwaInstallPlatform platform,
  }) {
    if (isInstalled) {
      return 'PulseWise sudah terpasang di perangkat ini. Kamu bisa langsung lanjut ke login atau buka app dari home screen.';
    }

    if (canPrompt) {
      return 'Browser ini sudah siap untuk install langsung. Tekan tombol di bawah lalu konfirmasi install dari browser.';
    }

    return 'PulseWise tetap bisa dipasang dari menu browser. Langkah install sudah langsung tersedia di bawah.';
  }

  String _statusLabel({
    required bool isInstalled,
    required bool canPrompt,
    required PwaInstallPlatform platform,
  }) {
    if (isInstalled) return 'App terpasang';
    if (canPrompt) return 'Install langsung tersedia';
    return 'Install dari browser';
  }

  List<String> _manualStepsFor(PwaInstallPlatform platform) {
    switch (platform) {
      case PwaInstallPlatform.iosSafari:
        return const [
          'Buka menu browser pada halaman ini.',
          'Pilih Add to Home Screen.',
          'Konfirmasi agar PulseWise muncul di layar utama.',
        ];
      case PwaInstallPlatform.chromium:
        return const [
          'Buka menu browser.',
          'Pilih Install App atau Add to Home Screen.',
          'Konfirmasi agar PulseWise tersimpan di perangkat kamu.',
        ];
      case PwaInstallPlatform.other:
        return const [
          'Buka menu browser pada halaman ini.',
          'Cari opsi seperti Install App atau Add to Home Screen.',
          'Kalau opsi itu tidak ada, coba buka halaman ini di Chrome atau Edge.',
        ];
    }
  }
}

class _InstructionRow extends StatelessWidget {
  const _InstructionRow({
    required this.number,
    required this.text,
  });

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: InstallPage.accentSoft,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: InstallPage.accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: const TextStyle(
                color: InstallPage.subtext,
                fontSize: 16,
                height: 1.55,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ManualInstructionsSection extends StatelessWidget {
  const _ManualInstructionsSection({
    required this.instructions,
  });

  final List<String> instructions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: InstallPage.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Text(
              'Cara install manual',
              style: TextStyle(
                color: InstallPage.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Langkah install dari menu browser:',
                    style: TextStyle(
                      color: InstallPage.subtext,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ),
                for (var index = 0; index < instructions.length; index++) ...[
                  _InstructionRow(
                    number: '${index + 1}',
                    text: instructions[index],
                  ),
                  if (index != instructions.length - 1)
                    const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
