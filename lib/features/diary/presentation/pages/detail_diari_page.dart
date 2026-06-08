import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_app_bar.dart';

class DetailDiariPage extends StatelessWidget {
  final int entryIndex;

  const DetailDiariPage({
    super.key,
    required this.entryIndex,
  });

  // Sample diary entry data (in a real app, this would come from a database/API)
  Map<String, dynamic> get _diaryEntry => {
        'date': '12 October 2025',
        'condition': 'Baik',
        'conditionIcon': Icons.sentiment_satisfied,
        'conditionColor': Color(0xFF2D9744),
        'conditionBgColor': Color(0xFFF6FFF8),
        'metrics': {
          'berat': 72,
          'beratUnit': 'Kg',
          'sistolik': 120,
          'diastolik': 80,
          'detak': 72,
        },
        'gejala': 'Tidak ada gejala hari ini',
        'aktivitas': ['Jalan Kaki', 'Senam'],
        'konsumsi': [
          {
            'waktu': 'Sarapan Pagi',
            'deskripsi': 'Nasi goreng, telur mata sapi, teh manis'
          },
          {
            'waktu': 'Makan Siang',
            'deskripsi': 'Nasi putih, ikan bakar, sayur bayam, tempe goreng'
          },
          {
            'waktu': 'Makan Malam',
            'deskripsi': 'Nasi merah, ayam rebus, sup sayuran'
          },
          {
            'waktu': 'Camilan',
            'deskripsi': 'Buah apel, biskuit gandum, kopi tanpa gula'
          },
        ],
        'catatan':
            'Kondisi tubuh terasa baik hari ini. Sudah menjalankan rutinitas pagi sesuai jadwal. Jalan pagi selama 20 menit di taman. Tidur nyenyak semalam.',
      };

  @override
  Widget build(BuildContext context) {
    final entry = _diaryEntry;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Detail Catatan',
        subtitle: entry['date'],
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kondisi Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kondisi',
                    style: TextStyle(
                      color: Color(0xFF525252),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: entry['conditionBgColor'],
                      border: Border.all(
                        color: entry['conditionColor'].withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          entry['conditionIcon'],
                          color: entry['conditionColor'],
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          entry['condition'],
                          style: TextStyle(
                            color: entry['conditionColor'],
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Metriks Kesehatan Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          color: Color(0xFF525252),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Berat Badan
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Berat Badan',
                          style: TextStyle(
                            color: Color(0xFF62748E),
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${entry['metrics']['berat']} ${entry['metrics']['beratUnit']}',
                          style: const TextStyle(
                            color: Color(0xFF525252),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tekanan Darah
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sistolik',
                                style: TextStyle(
                                  color: Color(0xFF62748E),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    entry['metrics']['sistolik'].toString(),
                                    style: const TextStyle(
                                      color: Color(0xFF525252),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'mmHg',
                                    style: TextStyle(
                                      color: Color(0xFF62748E),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Diastolik',
                                style: TextStyle(
                                  color: Color(0xFF62748E),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    entry['metrics']['diastolik'].toString(),
                                    style: const TextStyle(
                                      color: Color(0xFF525252),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'mmHg',
                                    style: TextStyle(
                                      color: Color(0xFF62748E),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Detak Jantung
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Detak Jantung',
                          style: TextStyle(
                            color: Color(0xFF62748E),
                            fontSize: 13,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              entry['metrics']['detak'].toString(),
                              style: const TextStyle(
                                color: Color(0xFF525252),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'BPM',
                              style: TextStyle(
                                color: Color(0xFF62748E),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Gejala Section
            _buildSection(
              icon: Icons.info_outline,
              iconColor: const Color(0xFFF59E0B),
              title: 'Gejala',
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  border: Border.all(color: const Color(0xFFFBD34D)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  entry['gejala'],
                  style: const TextStyle(
                    color: Color(0xFF62748E),
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Aktivitas Section
            _buildSection(
              icon: Icons.directions_run,
              iconColor: const Color(0xFF285DBE),
              title: 'Aktivitas',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (entry['aktivitas'] as List<String>)
                    .map((activity) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            border: Border.all(color: const Color(0xFFCBDCFE)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            activity,
                            style: const TextStyle(
                              color: Color(0xFF285DBE),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Asupan Harian Section
            _buildSection(
              icon: Icons.restaurant,
              iconColor: const Color(0xFF16A34A),
              title: 'Asupan Harian',
              child: Column(
                children: (entry['konsumsi'] as List<Map<String, dynamic>>)
                    .map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['waktu'],
                                  style: const TextStyle(
                                    color: Color(0xFF525252),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['deskripsi'],
                                  style: const TextStyle(
                                    color: Color(0xFF62748E),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Catatan Tambahan Section
            _buildSection(
              icon: Icons.note,
              iconColor: const Color(0xFF9366CC),
              title: 'Catatan Tambahan',
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  entry['catatan'],
                  style: const TextStyle(
                    color: Color(0xFF62748E),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF525252),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
