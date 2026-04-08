import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_app_bar.dart';

class RiwayatDiariPage extends StatefulWidget {
  const RiwayatDiariPage({super.key});

  @override
  State<RiwayatDiariPage> createState() => _RiwayatDiariPageState();
}

class _RiwayatDiariPageState extends State<RiwayatDiariPage> {
  final List<Map<String, dynamic>> diaryEntries = [
    {
      'date': '12 October 2025',
      'time': '08:30',
      'condition': 'Baik',
      'conditionIcon': Icons.sentiment_satisfied,
      'conditionColor': Color(0xFF2D9744),
      'conditionBgColor': Color(0xFFF6FFF8),
      'metrics': {
        'berat': '72 KG',
        'tekanan': '120/80',
        'detak': '72 BPM',
      },
      'note': '',
    },
    {
      'date': '11 October 2025',
      'time': '10:15',
      'condition': 'Cukup',
      'conditionIcon': Icons.sentiment_neutral,
      'conditionColor': Color(0xFFF59E0B),
      'conditionBgColor': Color(0xFFFEF3C7),
      'metrics': {
        'berat': '72 KG',
        'tekanan': '128/82',
        'detak': '75 BPM',
      },
      'note':
          'Sedikit lelah setelah aktivitas, tapi obat sudah diminum teratur',
    },
    {
      'date': '10 October 2025',
      'time': '09:00',
      'condition': 'Baik',
      'conditionIcon': Icons.sentiment_satisfied,
      'conditionColor': Color(0xFF2D9744),
      'conditionBgColor': Color(0xFFF6FFF8),
      'metrics': {
        'berat': '72 KG',
        'tekanan': '120/80',
        'detak': '72 BPM',
      },
      'note': 'Kondisi baik, tekanan darah normal, jalan pagi 20 menit',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Riwayat Diari',
        subtitle: 'Semua catatan kesehatan Anda',
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Periode
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.filter_list, size: 18),
                label: const Text('Filter Periode'),
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF525252),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Diary Entries
            ...List.generate(diaryEntries.length, (index) {
              final entry = diaryEntries[index];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GestureDetector(
                  onTap: () => context.push('/home/diary/detail/$index'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: entry['conditionBgColor'],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                entry['conditionIcon'],
                                color: entry['conditionColor'],
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry['date'],
                                    style: const TextStyle(
                                      color: Color(0xFF525252),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    entry['condition'],
                                    style: TextStyle(
                                      color: entry['conditionColor'],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Quick metrics
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMetricCard(
                                'Berat', entry['metrics']['berat']),
                            _buildMetricCard(
                                'Tekanan', entry['metrics']['tekanan']),
                            _buildMetricCard(
                                'Detak', entry['metrics']['detak']),
                          ],
                        ),
                        if (entry['note'].isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            entry['note'],
                            style: const TextStyle(
                              color: Color(0xFF62748E),
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F8FF),
          border: Border.all(color: const Color(0xFFCBDCFE)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF62748E),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF525252),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
