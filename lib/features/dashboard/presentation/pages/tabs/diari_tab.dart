import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DiariTab extends StatelessWidget {
  const DiariTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: Stack(
            children: [
              // Red gradient background header
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 120,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(35),
                    bottomRight: Radius.circular(35),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFE75480),
                          Color(0xFFE64060),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Diari Kesehatan',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Senin, 13 Oktober 2025',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => context.push('/home/diary'),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.history,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.grid_3x3,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Health Metrics Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(20),
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
                            const Icon(Icons.favorite,
                                color: Color(0xFFE64060), size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Metriks Kesehatan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF525252),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Berat Badan',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF62748E),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '72',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF525252),
                              ),
                            ),
                            const Text(
                              'Kg',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF62748E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Sistolik',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF62748E),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Text(
                                        '120',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF525252),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'mmHg',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF62748E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Diastolik',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF62748E),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Text(
                                        '80',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF525252),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'mmHg',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF62748E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Detak Jantung',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF62748E),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '72',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF525252),
                              ),
                            ),
                            const Text(
                              'BPM',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF62748E),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Filter Periode
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: [
                        const Icon(Icons.tune, color: Color(0xFF62748E)),
                        const SizedBox(width: 8),
                        const Text(
                          'Filter Periode',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF525252),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Kodisi Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.favorite,
                                color: Color(0xFF2D9744)),
                            const SizedBox(width: 8),
                            const Text(
                              'Kodisi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF525252),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _ConditionItem(
                          title: 'Pagi',
                          status: 'Baik - 07.00 AM',
                          icon: Icons.sentiment_satisfied,
                          color: const Color(0xFF2D9744),
                          onDelete: () {},
                        ),
                        const SizedBox(height: 8),
                        _ConditionItem(
                          title: 'Siang',
                          status: 'Baik - 13.00 PM',
                          icon: Icons.sentiment_satisfied,
                          color: const Color(0xFF2D9744),
                          onDelete: () {},
                        ),
                        const SizedBox(height: 8),
                        _ConditionItem(
                          title: 'Malam',
                          status: 'Malam - 22.00 PM',
                          icon: Icons.help_outline,
                          color: const Color(0xFF62748E),
                          onDelete: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Gejala Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: Color(0xFFE08B3D)),
                              const SizedBox(width: 8),
                              const Text(
                                'Gejala',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF525252),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Tidak ada gejala hari ini',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF62748E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Aktivitas Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.directions_run,
                                  color: Color(0xFF285DBE)),
                              const SizedBox(width: 8),
                              const Text(
                                'Aktivitas',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF525252),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: [
                              _TagChip(label: 'Jalan Kaki'),
                              _TagChip(label: 'Senam'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Konsumsi Harian Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.restaurant,
                                color: Color(0xFF2D9744)),
                            const SizedBox(width: 8),
                            const Text(
                              'Konsumsi Harian',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF525252),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _MealItem(
                          title: 'Sarapan Pagi',
                          description:
                              'Nasi goreng, telur mata sapi, teh manis',
                        ),
                        const SizedBox(height: 12),
                        _MealItem(
                          title: 'Makan Siang',
                          description:
                              'Nasi putih, ikan bakar, sayur bayam, tempe goreng',
                        ),
                        const SizedBox(height: 12),
                        _MealItem(
                          title: 'Makan Malam',
                          description: 'Nasi merah, ayam rebus, sup sayuran',
                        ),
                        const SizedBox(height: 12),
                        _MealItem(
                          title: 'Camilan',
                          description:
                              'Buah apel, biskuit gandum, kopi tanpa gula',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/home/add-diary');
        },
        backgroundColor: const Color(0xFFE64060),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah Diari',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _ConditionItem extends StatelessWidget {
  final String title;
  final String status;
  final IconData icon;
  final Color color;
  final VoidCallback onDelete;

  const _ConditionItem({
    required this.title,
    required this.status,
    required this.icon,
    required this.color,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF525252),
                  ),
                ),
                Text(
                  status,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF62748E),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE7E7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.delete_outline, size: 16),
              color: const Color(0xFFE64060),
              padding: EdgeInsets.zero,
              onPressed: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBDCFE)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF285DBE),
        ),
      ),
    );
  }
}

class _MealItem extends StatelessWidget {
  final String title;
  final String description;

  const _MealItem({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF525252),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF62748E),
            ),
          ),
        ],
      ),
    );
  }
}
