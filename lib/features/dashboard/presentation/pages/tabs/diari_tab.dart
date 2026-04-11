import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/features/dashboard/presentation/providers/current_diary_provider.dart';
import 'package:pulsewise/features/dashboard/presentation/widgets/diary_section_bottom_sheet.dart';

class DiariTab extends ConsumerStatefulWidget {
  const DiariTab({super.key});

  @override
  ConsumerState<DiariTab> createState() => _DiariTabState();
}

class _DiariTabState extends ConsumerState<DiariTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentDiaryProvider.notifier).loadCurrentDiaryForToday();
    });
  }

  Future<void> _openSectionModal(
      BuildContext context, String sectionTitle) async {
    await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.80,
        minChildSize: 0.25,
        maxChildSize: 0.98,
        builder: (context, scrollController) => DiarySectionBottomSheet(
          title: sectionTitle,
          scrollController: scrollController,
        ),
      ),
    );

    await ref.read(currentDiaryProvider.notifier).loadCurrentDiaryForToday();
  }

  String _todayLabel() {
    const dayNames = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const monthNames = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final now = DateTime.now();
    final dayName = dayNames[now.weekday - 1];
    final monthName = monthNames[now.month - 1];
    return '$dayName, ${now.day} $monthName ${now.year}';
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _refreshDiary() async {
    await ref.read(currentDiaryProvider.notifier).loadCurrentDiaryForToday();
  }

  @override
  Widget build(BuildContext context) {
    final diaryState = ref.watch(currentDiaryProvider);
    final diary = diaryState.diary;
    final latestMetric = (diary?.bodyMetrics.isNotEmpty ?? false)
        ? diary!.bodyMetrics.first
        : null;
    final conditions = (diary?.bodyMetrics ?? const [])
        .where((m) => (m.conditionTag ?? '').isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshDiary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Diari Kesehatan',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _todayLabel(),
                                style: const TextStyle(
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
                              GestureDetector(
                                onTap: () => context.push('/home/diary-qr'),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.qr_code_scanner,
                                    color: Colors.white,
                                    size: 20,
                                  ),
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
                              const Spacer(),
                              _SectionAddButton(
                                onTap: () => _openSectionModal(
                                    context, 'Metriks Kesehatan'),
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
                              Text(
                                latestMetric?.bodyWeight?.toString() ?? '-',
                                style: const TextStyle(
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
                                        Text(
                                          latestMetric?.systolicPressure
                                                  ?.toString() ??
                                              '-',
                                          style: const TextStyle(
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
                                        Text(
                                          latestMetric?.diastolicPressure
                                                  ?.toString() ??
                                              '-',
                                          style: const TextStyle(
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
                              Text(
                                (diary?.activities.isNotEmpty ?? false)
                                    ? (diary!.activities.first.heartRate
                                            ?.toString() ??
                                        '-')
                                    : '-',
                                style: const TextStyle(
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

                    // Kondisi Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: _SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.favorite,
                                    color: Color(0xFF2D9744)),
                                const SizedBox(width: 8),
                                const Text(
                                  'Kondisi',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF525252),
                                  ),
                                ),
                                const Spacer(),
                                _SectionAddButton(
                                  onTap: () =>
                                      _openSectionModal(context, 'Kondisi'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (conditions.isEmpty)
                              const Text(
                                'Belum ada kondisi hari ini',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF62748E),
                                ),
                              )
                            else
                              ...conditions.map((metric) {
                                final tag = metric.conditionTag ?? 'Kondisi';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _ConditionItem(
                                    title:
                                        tag[0].toUpperCase() + tag.substring(1),
                                    status:
                                        '${tag.toUpperCase()} - ${_formatTime(metric.timeStamp)}',
                                    icon: Icons.sentiment_satisfied,
                                    color: const Color(0xFF2D9744),
                                    onDelete: () {},
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Gejala Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: _SectionCard(
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
                                const Spacer(),
                                _SectionAddButton(
                                  onTap: () =>
                                      _openSectionModal(context, 'Gejala'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              (diary?.symptoms.isNotEmpty ?? false)
                                  ? diary!.symptoms
                                      .map((s) => s.symptomName)
                                      .join(', ')
                                  : 'Tidak ada gejala hari ini',
                              style: const TextStyle(
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
                      child: _SectionCard(
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
                                const Spacer(),
                                _SectionAddButton(
                                  onTap: () =>
                                      _openSectionModal(context, 'Aktivitas'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (diary?.activities.isEmpty ?? true)
                              const Text(
                                'Belum ada aktivitas hari ini',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF62748E),
                                ),
                              )
                            else
                              Wrap(
                                spacing: 8,
                                children: (diary?.activities ?? const [])
                                    .map((activity) =>
                                        _TagChip(label: activity.name))
                                    .toList(),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Konsumsi Harian Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: _SectionCard(
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
                                const Spacer(),
                                _SectionAddButton(
                                  onTap: () => _openSectionModal(
                                      context, 'Konsumsi Harian'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (diary?.consumptions.isEmpty ?? true)
                              const Text(
                                'Belum ada konsumsi hari ini',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF62748E),
                                ),
                              )
                            else
                              ...diary!.consumptions.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _MealItem(
                                    title: item.name,
                                    description:
                                        item.portion ?? item.note ?? '-',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (diaryState.error != null) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          diaryState.error!,
                          style: const TextStyle(
                            color: Color(0xFFB91C1C),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionAddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SectionAddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFFFFE7EE),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.add,
          color: Color(0xFFE64060),
          size: 18,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
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
