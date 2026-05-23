import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/utils/app_toast.dart';

class AddDiaryPage extends StatefulWidget {
  const AddDiaryPage({super.key});

  @override
  State<AddDiaryPage> createState() => _AddDiaryPageState();
}

class _AddDiaryPageState extends State<AddDiaryPage> {
  late TextEditingController _notesController;
  bool _expandedDiariMalam = true;
  bool _expandedMetriks = false;
  bool _expandedKonsumsi = false;
  bool _expandedGejala = false;
  bool _expandedAktivitas = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Tambah Diari',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Diari Malam Section
            _ExpandableSection(
              title: 'Diari Malam',
              subtitle: '19.00 PM',
              isExpanded: _expandedDiariMalam,
              onTap: () {
                setState(() {
                  _expandedDiariMalam = !_expandedDiariMalam;
                });
              },
              children: [
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kondisi',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF62748E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Baik',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2D9744),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Metriks Kesehatan Section
            _ExpandableSection(
              title: 'Metriks Kesehatan',
              subtitle: 'Sudah di isi',
              isExpanded: _expandedMetriks,
              onTap: () {
                setState(() {
                  _expandedMetriks = !_expandedMetriks;
                });
              },
              children: [
                const SizedBox(height: 12),
                _MetricRow(
                  label: 'Berat Badan',
                  value: '72',
                  unit: 'Kg',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricRow(
                        label: 'Sistolik',
                        value: '120',
                        unit: 'mmHg',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricRow(
                        label: 'Diastolik',
                        value: '80',
                        unit: 'mmHg',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _MetricRow(
                  label: 'Detak Jantung',
                  value: '72',
                  unit: 'BPM',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Konsumsi Harian Section
            _ExpandableSection(
              title: 'Konsumsi Harian',
              subtitle: 'Makanan & Minuman',
              isExpanded: _expandedKonsumsi,
              onTap: () {
                setState(() {
                  _expandedKonsumsi = !_expandedKonsumsi;
                });
              },
              children: [
                const SizedBox(height: 12),
                _ConsumptionItem(
                  title: 'Sarapan Pagi',
                  description: 'Nasi goreng, telur mata sapi',
                ),
                const SizedBox(height: 8),
                _ConsumptionItem(
                  title: 'Makan Siang',
                  description: 'Nasi putih, ikan bakar, sayur bayam',
                ),
                const SizedBox(height: 8),
                _ConsumptionItem(
                  title: 'Makan Malam',
                  description: 'Nasi merah, ayam rebus',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Gejala Section
            _ExpandableSection(
              title: 'Gejala',
              subtitle: 'Belum ada gejala',
              isExpanded: _expandedGejala,
              onTap: () {
                setState(() {
                  _expandedGejala = !_expandedGejala;
                });
              },
              children: [
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Belum ada gejala',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF62748E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Aktivitas Section
            _ExpandableSection(
              title: 'Aktivitas',
              subtitle: 'Belum ada aktivitas',
              isExpanded: _expandedAktivitas,
              onTap: () {
                setState(() {
                  _expandedAktivitas = !_expandedAktivitas;
                });
              },
              children: [
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Belum ada aktivitas',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF62748E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Catatan Tambahan Section
            const Text(
              'Catatan Tambahan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF525252),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tulis catatan...',
                hintStyle: const TextStyle(color: Color(0xFFBCBCBC)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFFE64060), width: 2),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 24),

            // Simpan Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE64060),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  // TODO: Implement save logic
                  AppToast.success(context, 'Diari disimpan');
                  context.pop();
                },
                child: const Text(
                  'Simpan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ExpandableSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isExpanded;
  final VoidCallback onTap;
  final List<Widget> children;

  const _ExpandableSection({
    required this.title,
    required this.subtitle,
    required this.isExpanded,
    required this.onTap,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
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
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF62748E),
                      ),
                    ),
                  ],
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: const Color(0xFF62748E),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF62748E),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF525252),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              unit,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF62748E),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ConsumptionItem extends StatelessWidget {
  final String title;
  final String description;

  const _ConsumptionItem({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF525252),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF62748E),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
