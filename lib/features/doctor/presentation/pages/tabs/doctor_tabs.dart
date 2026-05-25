import 'package:flutter/material.dart';

class DoctorHomeTab extends StatelessWidget {
  const DoctorHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DoctorPlaceholderTab(
      title: 'Beranda Dokter',
      subtitle:
          'Ringkasan cepat pasien, aktivitas pairing, dan insight dokter akan muncul di sini.',
      icon: Icons.medical_services_rounded,
      accent: Color(0xFF0F766E),
      cardTitle: 'Home',
      bullets: [
        'Statistik pairing dokter dan pasien.',
        'Ringkasan aktivitas pasien terbaru.',
        'Shortcut ke daftar pasien dan monitoring harian.',
      ],
    );
  }
}

class DoctorPredictionTab extends StatelessWidget {
  const DoctorPredictionTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DoctorPlaceholderTab(
      title: 'Prediksi',
      subtitle:
          'Halaman ini nanti akan menampilkan hasil prediksi, riwayat, dan follow-up klinis.',
      icon: Icons.analytics_rounded,
      accent: Color(0xFF2563EB),
      cardTitle: 'Prediksi ML',
      bullets: [
        'Antrian hasil prediksi pasien.',
        'Status readiness dan data yang masih kurang.',
        'Aksi cepat untuk review dan tindak lanjut dokter.',
      ],
    );
  }
}

class DoctorDiaryTab extends StatelessWidget {
  const DoctorDiaryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DoctorPlaceholderTab(
      title: 'Diari Pasien',
      subtitle:
          'Tab ini akan menjadi tempat dokter membaca diary pasien yang sudah terhubung.',
      icon: Icons.menu_book_rounded,
      accent: Color(0xFF7C3AED),
      cardTitle: 'Monitoring Diari',
      bullets: [
        'Lihat konsumsi, aktivitas, tidur, dan gejala pasien.',
        'Filter berdasarkan pasien atau tanggal.',
        'Buka detail harian untuk evaluasi dokter.',
      ],
    );
  }
}

class _DoctorPlaceholderTab extends StatelessWidget {
  const _DoctorPlaceholderTab({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.cardTitle,
    required this.bullets,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String cardTitle;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent,
                      Color.lerp(accent, Colors.white, 0.22) ?? accent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFFF8FAFC),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x110F172A),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cardTitle,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...bullets.map(
                      (text) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 6),
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                text,
                                style: const TextStyle(
                                  color: Color(0xFF334155),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
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
