import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/custom_app_bar.dart';

class RiwayatDiariPage extends StatefulWidget {
  const RiwayatDiariPage({super.key});

  @override
  State<RiwayatDiariPage> createState() => _RiwayatDiariPageState();
}

class _RiwayatDiariPageState extends State<RiwayatDiariPage> {
  final ScrollController _scrollController = ScrollController();
  int? _expandedIndex;
  late final List<GlobalKey> _itemKeys;

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
      ],
      'catatan':
          'Kondisi tubuh stabil dan cukup bertenaga. Sudah minum obat tepat waktu.',
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
      'gejala': 'Lemas ringan setelah siang hari',
      'aktivitas': ['Jalan Kaki'],
      'konsumsi': [
        {
          'waktu': 'Sarapan Pagi',
          'deskripsi': 'Bubur ayam, teh hangat'
        },
        {
          'waktu': 'Makan Malam',
          'deskripsi': 'Sup sayur, ikan kukus'
        },
      ],
      'catatan':
          'Perlu istirahat lebih banyak. Besok coba kurangi aktivitas berat.',
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
      'gejala': 'Tidak ada gejala berarti',
      'aktivitas': ['Jalan Kaki'],
      'konsumsi': [
        {
          'waktu': 'Makan Siang',
          'deskripsi': 'Nasi putih, ayam rebus, tumis bayam'
        },
      ],
      'catatan':
          'Tidur cukup semalam. Nafsu makan baik dan tidak ada keluhan tambahan.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _itemKeys = List.generate(diaryEntries.length, (_) => GlobalKey());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleEntry(int index) {
    final isAlreadyExpanded = _expandedIndex == index;

    setState(() {
      _expandedIndex = isAlreadyExpanded ? null : index;
    });

    if (!isAlreadyExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final itemContext = _itemKeys[index].currentContext;
        if (itemContext != null) {
          Scrollable.ensureVisible(
            itemContext,
            alignment: 0,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

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
        controller: _scrollController,
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
              final isExpanded = _expandedIndex == index;

              return Padding(
                key: _itemKeys[index],
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GestureDetector(
                  onTap: () => _toggleEntry(index),
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                              AnimatedCrossFade(
                                firstChild: const SizedBox.shrink(),
                                secondChild: Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: _ExpandedDiaryContent(entry: entry),
                                ),
                                crossFadeState: isExpanded
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,
                                duration: const Duration(milliseconds: 220),
                              ),
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          turns: isExpanded ? 0.25 : 0,
                          duration: const Duration(milliseconds: 220),
                          child: const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.chevron_right,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
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
}

class _ExpandedDiaryContent extends StatelessWidget {
  final Map<String, dynamic> entry;

  const _ExpandedDiaryContent({required this.entry});

  @override
  Widget build(BuildContext context) {
    final metrics = (entry['metrics'] as Map<String, dynamic>?) ?? {};
    final konsumsi = (entry['konsumsi'] as List?) ?? const [];
    final aktivitas = (entry['aktivitas'] as List?) ?? const [];
    final tekanan = (metrics['tekanan']?.toString() ?? '').split('/');
    final sistolik = tekanan.isNotEmpty ? tekanan[0] : '-';
    final diastolik = tekanan.length > 1 ? tekanan[1] : '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kondisi',
          style: TextStyle(
            color: Color(0xFF525252),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: entry['conditionBgColor'],
            border: Border.all(
              color: (entry['conditionColor'] as Color).withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                entry['conditionIcon'],
                color: entry['conditionColor'],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${entry['condition']} - ${entry['time']}',
                style: TextStyle(
                  color: entry['conditionColor'],
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Metriks Kesehatan',
          style: TextStyle(
            color: Color(0xFF525252),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Berat: ${metrics['berat'] ?? '-'}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
              Text(
                'Detak: ${metrics['detak'] ?? '-'}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _MetricPill(label: 'Sistolik', value: sistolik),
            _MetricPill(label: 'Diastolik', value: diastolik),
            _MetricPill(label: 'Tekanan', value: metrics['tekanan'] ?? '-'),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Gejala',
          style: TextStyle(
            color: Color(0xFF525252),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            border: Border.all(color: const Color(0xFFFBD34D)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            entry['gejala']?.toString().isNotEmpty == true
                ? entry['gejala']
                : '-',
            style: const TextStyle(color: Color(0xFF62748E), fontSize: 12),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Aktivitas',
          style: TextStyle(
            color: Color(0xFF525252),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: aktivitas
              .map(
                (activity) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    border: Border.all(color: const Color(0xFFCBDCFE)),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    activity.toString(),
                    style: const TextStyle(
                      color: Color(0xFF285DBE),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 14),
        const Text(
          'Konsumsi Harian',
          style: TextStyle(
            color: Color(0xFF525252),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...konsumsi.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['waktu']?.toString() ?? '-',
                    style: const TextStyle(
                      color: Color(0xFF525252),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['deskripsi']?.toString() ?? '-',
                    style: const TextStyle(
                      color: Color(0xFF62748E),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Catatan Tambahan',
          style: TextStyle(
            color: Color(0xFF525252),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            (entry['catatan']?.toString().isNotEmpty == true
                    ? entry['catatan']
                    : entry['note'])
                .toString(),
            style: const TextStyle(
              color: Color(0xFF62748E),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final dynamic value;

  const _MetricPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
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
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: const TextStyle(
                color: Color(0xFF525252),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
