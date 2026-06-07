import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/storage/wellness_disclaimer_store.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/core/widgets/wellness_disclaimer_card.dart';

class WellnessDisclaimerPage extends StatefulWidget {
  const WellnessDisclaimerPage({super.key});

  @override
  State<WellnessDisclaimerPage> createState() => _WellnessDisclaimerPageState();
}

class _WellnessDisclaimerPageState extends State<WellnessDisclaimerPage> {
  bool _isSubmitting = false;

  Future<void> _acknowledgeDisclaimer() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await WellnessDisclaimerStore.markAcknowledged();
      if (!mounted) return;
      context.pop(true);
    } catch (_) {
      if (!mounted) return;
      AppToast.warning(
        context,
        'Persetujuan belum bisa disimpan. Coba lagi beberapa saat lagi.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFBF5),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -80,
                right: -40,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFD7A8).withOpacity(0.45),
                  ),
                ),
              ),
              Positioned(
                top: 90,
                left: -50,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFE9CF).withOpacity(0.75),
                  ),
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFFF4D6),
                            Color(0xFFFFE7BE),
                            Color(0xFFFFD8A6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1AB45309),
                            blurRadius: 24,
                            offset: Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFB45309),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    'WAJIB DIBACA',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                const Text(
                                  'Sebelum memakai PulseWise',
                                  style: TextStyle(
                                    color: Color(0xFF111827),
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    height: 1.08,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'PulseWise hadir sebagai aplikasi wellness untuk membantu Anda mencatat rutinitas, kebiasaan, dan ringkasan data pribadi sehari-hari.',
                                  style: TextStyle(
                                    color: Color(0xFF6B4B1B),
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                    height: 1.65,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 18),
                          Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.78),
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
                              size: 40,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const WellnessDisclaimerCard(
                      title: 'Pahami batas penggunaan aplikasi ini',
                      caption:
                          'Silakan baca pernyataan berikut sebelum melanjutkan ke beranda.',
                      icon: Icons.gavel_rounded,
                      badgeLabel: 'DISCLAIMER',
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFF1E5CB)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x120F172A),
                            blurRadius: 18,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Yang bisa Anda lakukan di PulseWise',
                            style: TextStyle(
                              color: Color(0xFF111827),
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 16),
                          _DisclaimerBullet(
                            text:
                                'Mencatat kebiasaan harian, pengingat rutin, dan ringkasan metrik pribadi.',
                          ),
                          SizedBox(height: 14),
                          _DisclaimerBullet(
                            text:
                                'Melihat tren umum untuk membantu refleksi gaya hidup dari waktu ke waktu.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _isSubmitting ? null : _acknowledgeDisclaimer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE64060),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(62),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Saya Mengerti, Lanjutkan',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        'Anda hanya perlu menyetujui ini satu kali.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF8A4B12),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
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

class _DisclaimerBullet extends StatelessWidget {
  const _DisclaimerBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            color: Color(0xFFE64060),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}
