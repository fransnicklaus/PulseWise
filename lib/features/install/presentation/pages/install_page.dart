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
  bool _manualInstructionsExpanded = false;

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
                    final showManualInstall = !isInstalled && !canPrompt;
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
                                'assets/images/group_8.png',
                                width: 72,
                                height: 72,
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
                          FilledButton(
                            onPressed: isInstalled
                                ? null
                                : canPrompt
                                    ? _handleInstallPressed
                                    : _toggleManualInstructions,
                            style: FilledButton.styleFrom(
                              backgroundColor: InstallPage.accent,
                              disabledBackgroundColor: const Color(0xFFF1F5F9),
                              disabledForegroundColor: const Color(0xFF94A3B8),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              isInstalled
                                  ? 'App Sudah Terpasang'
                                  : canPrompt
                                      ? 'Install App'
                                      : _manualInstructionsExpanded
                                          ? 'Sembunyikan Cara Install Manual'
                                          : 'Lihat Cara Install Manual',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (showManualInstall)
                            Text(
                              _manualInstructionsExpanded
                                  ? 'Petunjuk manual sedang terbuka di bawah.'
                                  : 'Prompt install belum tersedia. Buka petunjuk manual di bawah.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: InstallPage.subtext,
                                fontSize: 15,
                                height: 1.6,
                              ),
                            ),
                          if (showManualInstall) const SizedBox(height: 12),
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
                              expanded: _manualInstructionsExpanded,
                              instructions: instructions,
                              onToggle: _toggleManualInstructions,
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
        _expandManualInstructions();
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
        _expandManualInstructions();
        break;
      case PwaInstallOutcome.error:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Gagal membuka prompt install.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
    }
  }

  void _toggleManualInstructions() {
    setState(() {
      _manualInstructionsExpanded = !_manualInstructionsExpanded;
    });
  }

  void _expandManualInstructions() {
    if (_manualInstructionsExpanded) return;
    setState(() {
      _manualInstructionsExpanded = true;
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
      return 'Browser ini sudah siap menampilkan prompt install. Tekan tombol di bawah lalu konfirmasi install langsung dari browser.';
    }

    switch (platform) {
      case PwaInstallPlatform.iosSafari:
        return 'Safari di iPhone atau iPad biasanya tidak memberi prompt install otomatis. Pakai menu Share lalu pilih Add to Home Screen.';
      case PwaInstallPlatform.chromium:
        return 'Prompt install otomatis belum muncul, tapi kamu masih bisa pasang PulseWise secara manual dari menu browser.';
      case PwaInstallPlatform.other:
        return 'Browser ini belum menampilkan prompt install otomatis. Ikuti langkah manual di bawah atau coba Chrome/Edge.';
    }
  }

  String _statusLabel({
    required bool isInstalled,
    required bool canPrompt,
    required PwaInstallPlatform platform,
  }) {
    if (isInstalled) return 'App terpasang';
    if (canPrompt) return 'Prompt install tersedia';

    switch (platform) {
      case PwaInstallPlatform.iosSafari:
        return 'Ikuti langkah manual';
      case PwaInstallPlatform.chromium:
        return 'Install manual tersedia';
      case PwaInstallPlatform.other:
        return 'Gunakan cara manual';
    }
  }

  List<String> _manualStepsFor(PwaInstallPlatform platform) {
    switch (platform) {
      case PwaInstallPlatform.iosSafari:
        return const [
          'Tekan tombol Share di Safari.',
          'Pilih Add to Home Screen.',
          'Konfirmasi agar PulseWise muncul di layar utama.',
        ];
      case PwaInstallPlatform.chromium:
        return const [
          'Coba tombol install di atas terlebih dahulu.',
          'Kalau tidak muncul, buka menu browser.',
          'Pilih Install App atau Add to Home Screen.',
        ];
      case PwaInstallPlatform.other:
        return const [
          'Buka halaman ini di Chrome, Edge, atau Safari iPhone.',
          'Kalau browser mendukung, prompt install bisa muncul otomatis.',
          'Kalau tidak, gunakan opsi Add to Home Screen dari menu browser.',
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
    required this.expanded,
    required this.instructions,
    required this.onToggle,
  });

  final bool expanded;
  final List<String> instructions;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: InstallPage.border),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Cara install manual',
                      style: TextStyle(
                        color: InstallPage.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: InstallPage.subtext,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Ikuti langkah berikut dari menu browser:',
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
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }
}
