import 'package:flutter/material.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/core/widgets/wellness_disclaimer_card.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: const CustomAppBar(
        title: 'Tentang PulseWise',
        subtitle: 'Informasi aplikasi dan disclaimer penggunaan',
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
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
                      Color(0xFFFFEEF1),
                      Color(0xFFFFE2E8),
                      Color(0xFFFFD3DC),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12E64060),
                      blurRadius: 22,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'APP INFO',
                      style: TextStyle(
                        color: Color(0xFFBE123C),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.favorite_outline_rounded,
                            color: Color(0xFFE64060),
                            size: 32,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PulseWise',
                                style: TextStyle(
                                  color: Color(0xFF111827),
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Aplikasi pendamping wellness harian untuk rutinitas, kebiasaan, dan ringkasan pribadi.',
                                style: TextStyle(
                                  color: Color(0xFF6B4B63),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const WellnessDisclaimerCard(
                title: 'Disclaimer penggunaan',
                caption:
                    'Simpan halaman ini sebagai referensi kapan pun Anda ingin meninjau batas penggunaan PulseWise.',
                icon: Icons.policy_outlined,
                badgeLabel: 'INFO PENTING',
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE8EAF0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D0F172A),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cocok digunakan untuk',
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 16),
                    _AboutBullet(
                      text:
                          'Menyimpan catatan harian, kebiasaan, dan pengingat rutin pribadi.',
                    ),
                    SizedBox(height: 14),
                    _AboutBullet(
                      text:
                          'Melihat ringkasan dan tren umum sebagai bahan refleksi gaya hidup.',
                    ),
                    SizedBox(height: 14),
                    _AboutBullet(
                      text:
                          'Mengelola informasi wellness pribadi bersama fitur aplikasi yang tersedia.',
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

class _AboutBullet extends StatelessWidget {
  const _AboutBullet({required this.text});

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
              color: Color(0xFF475569),
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.65,
            ),
          ),
        ),
      ],
    );
  }
}
