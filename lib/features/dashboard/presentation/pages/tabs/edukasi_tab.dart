import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EdukasiTab extends StatelessWidget {
  const EdukasiTab({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        children: [
          SizedBox(height: topPadding),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edukasi',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF525252),
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.bookmark_border,
                    color: Color(0xFFE64060),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SizedBox(
              height: 48,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Cari Artikel',
                  hintStyle: const TextStyle(color: Color(0xFF62748E)),
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF62748E)),
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: _WearableConnectionCard(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kategori',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF525252),
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: const [
                    _CategoryCard(
                      icon: Icons.favorite,
                      label: 'Penyakit\nJantung',
                      backgroundColor: Color(0xFFFFE7E7),
                      iconColor: Color(0xFFE64060),
                    ),
                    _CategoryCard(
                      icon: Icons.circle_outlined,
                      label: 'Gejala',
                      backgroundColor: Color(0xFFFFEDD5),
                      iconColor: Color(0xFFE08B3D),
                    ),
                    _CategoryCard(
                      icon: Icons.music_note,
                      label: 'Nutrisi',
                      backgroundColor: Color(0xFFE8F5E9),
                      iconColor: Color(0xFF2D9744),
                    ),
                    _CategoryCard(
                      icon: Icons.trending_up,
                      label: 'Aktivitas',
                      backgroundColor: Color(0xFFE3F2FD),
                      iconColor: Color(0xFF285DBE),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Artikel Terbaru',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF525252),
                  ),
                ),
                SizedBox(height: 12),
                _ArticleCard(
                  category: 'Aktivitas',
                  categoryColor: Color(0xFF285DBE),
                  readTime: '7 Menit',
                  title: 'Olahraga Aman untuk Pasien Jantung',
                  description: 'Panduan berolahraga yang aman bagi pasien ...',
                ),
                SizedBox(height: 12),
                _ArticleCard(
                  category: 'Penyakit Jantung',
                  categoryColor: Color(0xFFE64060),
                  readTime: '5 Menit',
                  title: 'Mengenal Penyakit Jantung Koroner',
                  description: 'Pelajari tentang penyebab, gejala, dan ...',
                ),
                SizedBox(height: 12),
                _ArticleCard(
                  category: 'Gejala',
                  categoryColor: Color(0xFFE08B3D),
                  readTime: '4 Menit',
                  title: 'Kenali Gejala Serangan Jantung',
                  description:
                      'Tanda-tanda serangan jantung yang harus Anda...',
                ),
                SizedBox(height: 12),
                _ArticleCard(
                  category: 'Nutrisi',
                  categoryColor: Color(0xFF2D9744),
                  readTime: '7 Menit',
                  title: 'Makanan Sehat untuk Jantung',
                  description: 'Daftar makanan yang baik untuk kesehatan ...',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WearableConnectionCard extends StatelessWidget {
  const _WearableConnectionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFBCDD6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE7E7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.watch_outlined,
                  color: Color(0xFFE64060),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Koneksi Wearable',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE64060),
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Hubungkan PulseWise dengan smartwatch Anda',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Sambungkan PulseWise ke Health Connect agar aplikasi bisa membaca data langkah, detak jantung, tidur, dan aktivitas dari wearable Anda.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(label: 'Langkah'),
              _InfoChip(label: 'Detak Jantung'),
              _InfoChip(label: 'Tidur'),
              _InfoChip(label: 'Aktivitas'),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.push('/home/health-connect'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE64060),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text(
                'Lihat Panduan Health Connect',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFBCDD6)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF475569),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;

  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF525252),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final String category;
  final Color categoryColor;
  final String readTime;
  final String title;
  final String description;

  const _ArticleCard({
    required this.category,
    required this.categoryColor,
    required this.readTime,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: categoryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.access_time, size: 14, color: Color(0xFF62748E)),
              const SizedBox(width: 4),
              Text(
                readTime,
                style: const TextStyle(
                  color: Color(0xFF62748E),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF525252),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF62748E),
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
