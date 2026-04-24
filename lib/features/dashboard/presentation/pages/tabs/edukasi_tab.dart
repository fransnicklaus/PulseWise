import 'package:flutter/material.dart';

class EdukasiTab extends StatelessWidget {
  const EdukasiTab({super.key});

  @override
  Widget build(BuildContext context) {
    double topPadding = MediaQuery.of(context).padding.top;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        children: [
          SizedBox(height: topPadding),
          // Header with title and bookmark
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

          // Search Bar
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

          // Categories Section
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
                  children: [
                    _CategoryCard(
                      icon: Icons.favorite,
                      label: 'Penyakit\nJantung',
                      backgroundColor: const Color(0xFFFFE7E7),
                      iconColor: const Color(0xFFE64060),
                    ),
                    _CategoryCard(
                      icon: Icons.circle_outlined,
                      label: 'Gejala',
                      backgroundColor: const Color(0xFFFFEDD5),
                      iconColor: const Color(0xFFE08B3D),
                    ),
                    _CategoryCard(
                      icon: Icons.music_note,
                      label: 'Nutrisi',
                      backgroundColor: const Color(0xFFE8F5E9),
                      iconColor: const Color(0xFF2D9744),
                    ),
                    _CategoryCard(
                      icon: Icons.trending_up,
                      label: 'Aktivitas',
                      backgroundColor: const Color(0xFFE3F2FD),
                      iconColor: const Color(0xFF285DBE),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Articles Section
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Artikel Terbaru',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF525252),
                  ),
                ),
                const SizedBox(height: 12),
                _ArticleCard(
                  category: 'Aktivitas',
                  categoryColor: const Color(0xFF285DBE),
                  readTime: '7 Menit',
                  title: 'Olahraga Aman untuk Pasien Jantung',
                  description: 'Panduan berolahraga yang aman bagi pasien ...',
                ),
                const SizedBox(height: 12),
                _ArticleCard(
                  category: 'Penyakit Jantung',
                  categoryColor: const Color(0xFFE64060),
                  readTime: '5 Menit',
                  title: 'Mengenal Penyakit Jantung Koroner',
                  description: 'Pelajari tentang penyebab, gejala, dan ...',
                ),
                const SizedBox(height: 12),
                _ArticleCard(
                  category: 'Gejala',
                  categoryColor: const Color(0xFFE08B3D),
                  readTime: '4 Menit',
                  title: 'Kenali Gejala Serangan Jantung',
                  description:
                      'Tanda-tanda serangan jantung yang harus Anda...',
                ),
                const SizedBox(height: 12),
                _ArticleCard(
                  category: 'Nutrisi',
                  categoryColor: const Color(0xFF2D9744),
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
