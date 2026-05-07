import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/features/dashboard/presentation/providers/current_diary_provider.dart';
import 'package:pulsewise/features/dashboard/presentation/widgets/diary_section_bottom_sheet.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
      ref.read(currentDiaryProvider.notifier).ensureCurrentDiaryLoaded();
    });
  }

  Future<void> _openSectionModal(String sectionTitle) async {
    final normalizedSection = sectionTitle.trim().toLowerCase();
    final result = await showModalBottomSheet<Map<String, dynamic>>(
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
          onSubmitGejala: normalizedSection == 'gejala'
              ? (payload) => ref
                  .read(currentDiaryProvider.notifier)
                  .addSymptomsFromModal(payload)
              : null,
          onSubmitKonsumsi: normalizedSection.contains('konsumsi')
              ? (payload) => ref
                  .read(currentDiaryProvider.notifier)
                  .addConsumptionsFromModal(payload)
              : null,
          onSubmitAktivitas: normalizedSection.contains('aktivitas')
              ? (payload) => ref
                  .read(currentDiaryProvider.notifier)
                  .addActivitiesFromModal(payload)
              : null,
          onSubmitMetriks: normalizedSection.contains('metriks')
              ? (payload) => ref
                  .read(currentDiaryProvider.notifier)
                  .addBodyMetricsFromModal(payload)
              : null,
          onSubmitTidur: normalizedSection == 'tidur'
              ? (payload) => ref
                  .read(currentDiaryProvider.notifier)
                  .addSleepFromModal(payload)
              : null,
        ),
      ),
    );

    if (!mounted || result == null) return;

    final section = (result['section'] ?? '').toString().trim().toLowerCase();
    try {
      if (section == 'gejala') {
        if (result['saved'] == true) {
          await ref
              .read(currentDiaryProvider.notifier)
              .invalidateCurrentDiaryQuery();
          if (!mounted) return;
          AppToast.success(context, 'Gejala berhasil disimpan');
        } else if ((result['symptoms'] as List?)?.isNotEmpty == true) {
          await ref
              .read(currentDiaryProvider.notifier)
              .addSymptomsFromModal(result);
          await ref
              .read(currentDiaryProvider.notifier)
              .invalidateCurrentDiaryQuery();
          if (!mounted) return;
          AppToast.success(context, 'Gejala berhasil disimpan');
        }
      } else if (section.contains('konsumsi')) {
        if (result['saved'] == true) {
          await ref
              .read(currentDiaryProvider.notifier)
              .invalidateCurrentDiaryQuery();
          if (!mounted) return;
          AppToast.success(context, 'Konsumsi harian berhasil disimpan');
        } else if ((result['name'] ?? '').toString().trim().isNotEmpty) {
          await ref
              .read(currentDiaryProvider.notifier)
              .addConsumptionsFromModal(result);
          await ref
              .read(currentDiaryProvider.notifier)
              .invalidateCurrentDiaryQuery();
          if (!mounted) return;
          AppToast.success(context, 'Konsumsi harian berhasil disimpan');
        }
      } else if (section.contains('aktivitas')) {
        if (result['saved'] == true) {
          await ref
              .read(currentDiaryProvider.notifier)
              .invalidateCurrentDiaryQuery();
          if (!mounted) return;
          AppToast.success(context, 'Aktivitas berhasil disimpan');
        } else if (((result['name'] ?? result['activity']) ?? '')
            .toString()
            .trim()
            .isNotEmpty) {
          await ref
              .read(currentDiaryProvider.notifier)
              .addActivitiesFromModal(result);
          await ref
              .read(currentDiaryProvider.notifier)
              .invalidateCurrentDiaryQuery();
          if (!mounted) return;
          AppToast.success(context, 'Aktivitas berhasil disimpan');
        }
      } else if (section.contains('metriks')) {
        if (result['saved'] == true) {
          await ref
              .read(currentDiaryProvider.notifier)
              .invalidateCurrentDiaryQuery();
          if (!mounted) return;
          AppToast.success(context, 'Metriks kesehatan berhasil disimpan');
        } else if (result['bodyHeight'] != null ||
            result['bodyWeight'] != null ||
            result['systolicPressure'] != null ||
            result['diastolicPressure'] != null ||
            result['heartRate'] != null) {
          await ref
              .read(currentDiaryProvider.notifier)
              .addBodyMetricsFromModal(result);
          await ref
              .read(currentDiaryProvider.notifier)
              .invalidateCurrentDiaryQuery();
          if (!mounted) return;
          AppToast.success(context, 'Metriks kesehatan berhasil disimpan');
        }
      } else if (section == 'tidur') {
        if (result['saved'] == true) {
          await ref
              .read(currentDiaryProvider.notifier)
              .invalidateCurrentDiaryQuery();
          if (!mounted) return;
          AppToast.success(context, 'Data tidur berhasil disimpan');
        } else if (result['sleepTime'] != null && result['wakeTime'] != null) {
          await ref
              .read(currentDiaryProvider.notifier)
              .addSleepFromModal(result);
          await ref
              .read(currentDiaryProvider.notifier)
              .invalidateCurrentDiaryQuery();
          if (!mounted) return;
          AppToast.success(context, 'Data tidur berhasil disimpan');
        }
      } else {
        await ref
            .read(currentDiaryProvider.notifier)
            .loadCurrentDiaryForToday();
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
    }
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

  String _formatConditionTag(String? tag) {
    switch ((tag ?? '').toLowerCase()) {
      case 'morning':
        return 'Pagi';
      case 'afternoon':
        return 'Siang';
      case 'evening':
        return 'Malam';
      default:
        return (tag ?? '').isEmpty ? '-' : tag!;
    }
  }

  String _formatConsumptionType(String type) {
    switch (type.toLowerCase()) {
      case 'food':
        return 'Makanan';
      case 'drink':
        return 'Minuman';
      case 'medication':
        return 'Obat';
      case 'snack':
        return 'Snack';
      default:
        return type.isEmpty ? '-' : type;
    }
  }

  Future<void> _refreshDiary() async {
    await ref.read(currentDiaryProvider.notifier).loadCurrentDiaryForToday();
  }

  @override
  Widget build(BuildContext context) {
    final diaryState = ref.watch(currentDiaryProvider);
    final diary = diaryState.diary;
    final isSkeleton = diaryState.isLoading;
    final isRefreshing = diaryState.isRefreshing;
    int compareByTimeDesc(DateTime? a, DateTime? b) {
      final at = a ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    }

    final bodyMetrics = [...?diary?.bodyMetrics]
      ..sort((a, b) => compareByTimeDesc(a.timeStamp, b.timeStamp));
    final symptoms = [...?diary?.symptoms]
      ..sort((a, b) => compareByTimeDesc(a.timeStamp, b.timeStamp));
    final activities = [...?diary?.activities]
      ..sort((a, b) => compareByTimeDesc(a.timeStamp, b.timeStamp));
    final consumptions = [...?diary?.consumptions]
      ..sort((a, b) => compareByTimeDesc(a.timeStamp, b.timeStamp));

    final latestMetric = (diary?.bodyMetrics.isNotEmpty ?? false)
        ? diary!.bodyMetrics.first
        : null;
    final weightDisplay =
        isSkeleton ? '74.0' : (latestMetric?.bodyWeight?.toString() ?? '-');
    final systolicDisplay = isSkeleton
        ? '122'
        : (latestMetric?.systolicPressure?.toString() ?? '-');
    final diastolicDisplay = isSkeleton
        ? '78'
        : (latestMetric?.diastolicPressure?.toString() ?? '-');
    String heartRateDisplay;
    if (diary?.latestHeartRate?.toString() == null) {
      heartRateDisplay =
          isSkeleton ? '98' : (latestMetric?.heartRate?.toString() ?? '-');
      // print(
      //     'Debug Info: diary?.latestHeartRate: ${diary?.latestHeartRate}, diary?.heartRate: ${diary?.heartRate}');
    } else {
      heartRateDisplay = isSkeleton
          ? '98'
          : (latestMetric?.latestHeartRate?.toString() ?? '-');
    }

    final oxygenSatDisplay =
        isSkeleton ? '98' : (diary?.latestOxygenSaturation?.toString() ?? '-');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(1.14),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshDiary,
            color: const Color(0xFFE64060),
            backgroundColor: Colors.white,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 130),
              child: Skeletonizer(
                enabled: isSkeleton,
                effect: const ShimmerEffect(
                  baseColor: Color(0xFFE9EDF2),
                  highlightColor: Color(0xFFF6F8FB),
                  duration: Duration(milliseconds: 1300),
                ),
                child: Stack(
                  children: [
                    if (isRefreshing)
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                          minHeight: 2,
                          color: Color(0xFFE64060),
                          backgroundColor: Color(0xFFF1F5F9),
                        ),
                      ),
                    // Red gradient background header
                    // Positioned(
                    //   top: 0,
                    //   left: 0,
                    //   right: 0,
                    //   height: 120,
                    //   child: ClipRRect(
                    //     borderRadius: const BorderRadius.only(
                    //       bottomLeft: Radius.circular(35),
                    //       bottomRight: Radius.circular(35),
                    //     ),
                    //     child: Container(
                    //       decoration: const BoxDecoration(
                    //         color: Color(0xFFE64060),
                    //         // gradient: LinearGradient(
                    //         //   begin: Alignment.topCenter,
                    //         //   end: Alignment.bottomCenter,
                    //         //   colors: [
                    //         //     Color(0xFFE75480),
                    //         //     Color(0xFFE64060),
                    //         //   ],
                    //         // ),
                    //       ),
                    //     ),
                    //   ),
                    // ),

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
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF525252),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _todayLabel(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF525252),
                                    ),
                                  ),
                                ],
                              ),
                              if (!isSkeleton)
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => context.push('/home/diary'),
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          border: Border.all(
                                              color:
                                                  Colors.grey.withOpacity(0.2)),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.history,
                                          color: Color(0xFFE64060),
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    GestureDetector(
                                      onTap: () =>
                                          context.push('/home/diary-qr'),
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          border: Border.all(
                                              color:
                                                  Colors.grey.withOpacity(0.2)),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.qr_code_scanner,
                                          color: Color(0xFFE64060),
                                          size: 24,
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
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.025),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Icon(Icons.favorite,
                                      color: Color(0xFFE64060), size: 24),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Metriks Kesehatan',
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF525252),
                                    ),
                                  ),
                                  if (!isSkeleton) ...[
                                    const Spacer(),
                                    _SectionAddButton(
                                      onTap: () => _openSectionModal(
                                          'Metriks Kesehatan'),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Berat Badan',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF62748E),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    weightDisplay,
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF525252),
                                    ),
                                  ),
                                  const Text(
                                    'Kg',
                                    style: TextStyle(
                                      fontSize: 18,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Sistolik',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Color(0xFF62748E),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              systolicDisplay,
                                              style: const TextStyle(
                                                fontSize: 30,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF525252),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'mmHg',
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
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Diastolik',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Color(0xFF62748E),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              diastolicDisplay,
                                              style: const TextStyle(
                                                fontSize: 30,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF525252),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'mmHg',
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
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Detak Jantung',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF62748E),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    heartRateDisplay,
                                    style: const TextStyle(
                                      fontSize: 33,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF525252),
                                    ),
                                  ),
                                  const Text(
                                    'BPM',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF62748E),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Saturasi Oksigen (SpO2)',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF62748E),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    oxygenSatDisplay,
                                    style: const TextStyle(
                                      fontSize: 33,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF525252),
                                    ),
                                  ),
                                  const Text(
                                    '%',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF62748E),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(
                                  color: Color(0xFFE2E8F0), height: 1),
                              const SizedBox(height: 14),
                              const Text(
                                'Riwayat Metriks Hari Ini',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (bodyMetrics.isEmpty && !isSkeleton)
                                const Text(
                                  'Belum ada metrik tersimpan',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF62748E),
                                  ),
                                )
                              else
                                ...(isSkeleton && bodyMetrics.isEmpty
                                        ? List.generate(2, (index) => index)
                                        : bodyMetrics.asMap().keys)
                                    .map(
                                  (entry) => Padding(
                                    padding: EdgeInsets.only(
                                      bottom: isSkeleton
                                          ? (entry == 1 ? 0 : 10)
                                          : (entry == bodyMetrics.length - 1
                                              ? 0
                                              : 10),
                                    ),
                                    child: _BodyMetricEntryItem(
                                      conditionLabel: isSkeleton
                                          ? 'Pagi'
                                          : _formatConditionTag(
                                              bodyMetrics[entry].conditionTag,
                                            ),
                                      recordedTime: isSkeleton
                                          ? '07:10'
                                          : _formatTime(
                                              bodyMetrics[entry].timeStamp,
                                            ),
                                      bodyHeight: isSkeleton
                                          ? 170
                                          : bodyMetrics[entry].bodyHeight,
                                      bodyWeight: isSkeleton
                                          ? 74
                                          : bodyMetrics[entry].bodyWeight,
                                      systolicPressure: isSkeleton
                                          ? 122
                                          : bodyMetrics[entry].systolicPressure,
                                      diastolicPressure: isSkeleton
                                          ? 78
                                          : bodyMetrics[entry]
                                              .diastolicPressure,
                                      heartRate: isSkeleton
                                          ? 98
                                          : bodyMetrics[entry].heartRate,
                                      showDivider: isSkeleton
                                          ? entry != 1
                                          : entry != bodyMetrics.length - 1,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Filter Periode
                        // Padding(
                        //   padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        //   child: Row(
                        //     children: [
                        //       const Icon(Icons.tune, color: Color(0xFF62748E)),
                        //       const SizedBox(width: 8),
                        //       const Text(
                        //         'Filter Periode',
                        //         style: TextStyle(
                        //           fontSize: 16,
                        //           fontWeight: FontWeight.w600,
                        //           color: Color(0xFF525252),
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        // const SizedBox(height: 16),

                        // Kondisi Section
                        // Padding(
                        //   padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        //   child: _SectionCard(
                        //     child: Column(
                        //       crossAxisAlignment: CrossAxisAlignment.start,
                        //       children: [
                        //         Row(
                        //           children: [
                        //             const Icon(Icons.favorite,
                        //                 color: Color(0xFF2D9744)),
                        //             const SizedBox(width: 8),
                        //             const Text(
                        //               'Kondisi',
                        //               style: TextStyle(
                        //                 fontSize: 16,
                        //                 fontWeight: FontWeight.w600,
                        //                 color: Color(0xFF525252),
                        //               ),
                        //             ),
                        //             const Spacer(),
                        //             _SectionAddButton(
                        //               onTap: () => _openSectionModal('Kondisi'),
                        //             ),
                        //           ],
                        //         ),
                        //         const SizedBox(height: 12),
                        //         if (conditions.isEmpty)
                        //           const Text(
                        //             'Belum ada kondisi hari ini',
                        //             style: TextStyle(
                        //               fontSize: 14,
                        //               color: Color(0xFF62748E),
                        //             ),
                        //           )
                        //         else
                        //           ...conditions.map((metric) {
                        //             final tag = metric.conditionTag ?? 'Kondisi';
                        //             return Padding(
                        //               padding: const EdgeInsets.only(bottom: 8),
                        //               child: _ConditionItem(
                        //                 title:
                        //                     tag[0].toUpperCase() + tag.substring(1),
                        //                 status:
                        //                     '${tag.toUpperCase()} - ${_formatTime(metric.timeStamp)}',
                        //                 icon: Icons.sentiment_satisfied,
                        //                 color: const Color(0xFF2D9744),
                        //                 onDelete: () {},
                        //               ),
                        //             );
                        //           }),
                        //       ],
                        //     ),
                        //   ),
                        // ),
                        // const SizedBox(height: 20),

                        // Gejala Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: _SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.info_outline,
                                        color: Color(0xFFE08B3D), size: 24),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Gejala',
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF525252),
                                      ),
                                    ),
                                    if (!isSkeleton) ...[
                                      const Spacer(),
                                      _SectionAddButton(
                                        onTap: () =>
                                            _openSectionModal('Gejala'),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  symptoms.isNotEmpty
                                      ? 'Total ${symptoms.length} gejala tercatat'
                                      : 'Tidak ada gejala hari ini',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF62748E),
                                  ),
                                ),
                                if (symptoms.isNotEmpty || isSkeleton) ...[
                                  const SizedBox(height: 10),
                                  ...(isSkeleton && symptoms.isEmpty
                                          ? List.generate(2, (index) => index)
                                          : symptoms.asMap().keys)
                                      .map(
                                    (entry) => Padding(
                                      padding: EdgeInsets.only(
                                        bottom: isSkeleton
                                            ? (entry == 1 ? 0 : 10)
                                            : (entry == symptoms.length - 1
                                                ? 0
                                                : 10),
                                      ),
                                      child: _SymptomEntryItem(
                                        name: isSkeleton
                                            ? 'Pusing'
                                            : symptoms[entry].symptomName,
                                        intensity: isSkeleton
                                            ? 4
                                            : symptoms[entry].intensity,
                                        note: isSkeleton
                                            ? 'Muncul setelah bangun tidur'
                                            : symptoms[entry].note,
                                        recordedTime: isSkeleton
                                            ? (entry == 0 ? '14:52' : '07:30')
                                            : _formatTime(
                                                symptoms[entry].timeStamp,
                                              ),
                                        showDivider: isSkeleton
                                            ? entry != 1
                                            : entry != symptoms.length - 1,
                                      ),
                                    ),
                                  ),
                                ],
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
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.directions_run,
                                        color: Color(0xFF285DBE), size: 24),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Aktivitas',
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF525252),
                                      ),
                                    ),
                                    if (!isSkeleton) ...[
                                      const Spacer(),
                                      _SectionAddButton(
                                        onTap: () =>
                                            _openSectionModal('Aktivitas'),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (activities.isEmpty && !isSkeleton)
                                  const Text(
                                    'Belum ada aktivitas hari ini',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF62748E),
                                    ),
                                  )
                                else
                                  ...(isSkeleton && activities.isEmpty
                                          ? List.generate(2, (index) => index)
                                          : activities.asMap().keys)
                                      .map(
                                    (entry) => Padding(
                                      padding: EdgeInsets.only(
                                        bottom: isSkeleton
                                            ? (entry == 1 ? 0 : 10)
                                            : (entry == activities.length - 1
                                                ? 0
                                                : 10),
                                      ),
                                      child: _ActivityEntryItem(
                                        name: isSkeleton
                                            ? 'Jalan kaki'
                                            : activities[entry].name,
                                        duration: isSkeleton
                                            ? 30
                                            : activities[entry].duration,
                                        heartRate: isSkeleton
                                            ? 98
                                            : activities[entry].heartRate,
                                        feeling: isSkeleton
                                            ? 'lebih baik'
                                            : activities[entry].userFeeling,
                                        recordedTime: isSkeleton
                                            ? (entry == 0 ? '14:53' : '14:52')
                                            : _formatTime(
                                                activities[entry].timeStamp,
                                              ),
                                        showDivider: isSkeleton
                                            ? entry != 1
                                            : entry != activities.length - 1,
                                      ),
                                    ),
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
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.restaurant,
                                        color: Color(0xFF2D9744), size: 24),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Konsumsi Harian',
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF525252),
                                      ),
                                    ),
                                    if (!isSkeleton) ...[
                                      const Spacer(),
                                      _SectionAddButton(
                                        onTap: () => _openSectionModal(
                                            'Konsumsi Harian'),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (consumptions.isEmpty && !isSkeleton)
                                  const Text(
                                    'Belum ada konsumsi hari ini',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF62748E),
                                    ),
                                  )
                                else
                                  ...(isSkeleton && consumptions.isEmpty
                                          ? List.generate(2, (index) => index)
                                          : consumptions.asMap().keys)
                                      .map(
                                    (entry) => Padding(
                                      padding: EdgeInsets.only(
                                        bottom: isSkeleton
                                            ? (entry == 1 ? 0 : 12)
                                            : (entry == consumptions.length - 1
                                                ? 0
                                                : 12),
                                      ),
                                      child: _ConsumptionEntryItem(
                                        typeLabel: isSkeleton
                                            ? 'Makanan'
                                            : _formatConsumptionType(
                                                consumptions[entry].type,
                                              ),
                                        title: isSkeleton
                                            ? (entry == 0
                                                ? 'Oatmeal'
                                                : 'Aspirin')
                                            : consumptions[entry].name,
                                        portion: isSkeleton
                                            ? (entry == 0
                                                ? '1 mangkuk'
                                                : '1 tablet')
                                            : consumptions[entry].portion,
                                        note: isSkeleton
                                            ? (entry == 0
                                                ? null
                                                : 'Sesudah makan malam')
                                            : consumptions[entry].note,
                                        recordedTime: isSkeleton
                                            ? (entry == 0 ? '14:53' : '21:15')
                                            : _formatTime(
                                                consumptions[entry].timeStamp,
                                              ),
                                        showDivider: isSkeleton
                                            ? entry != 1
                                            : entry != consumptions.length - 1,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Tidur Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: _SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.bedtime,
                                        color: Color(0xFF3B82F6), size: 24),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Tidur',
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF525252),
                                      ),
                                    ),
                                    if (!isSkeleton) ...[
                                      const Spacer(),
                                      _SectionAddButton(
                                        onTap: () => _openSectionModal('Tidur'),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if ((diary?.sleeps ?? []).isEmpty &&
                                    !isSkeleton)
                                  const Text(
                                    'Belum ada data tidur hari ini',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF62748E),
                                    ),
                                  )
                                else
                                  ...(isSkeleton &&
                                              (diary?.sleeps ?? []).isEmpty
                                          ? List.generate(1, (index) => index)
                                          : (diary?.sleeps ?? []).asMap().keys)
                                      .map(
                                    (entry) => Padding(
                                      padding: EdgeInsets.only(
                                        bottom: isSkeleton
                                            ? 0
                                            : (entry ==
                                                    (diary?.sleeps.length ??
                                                            0) -
                                                        1
                                                ? 0
                                                : 12),
                                      ),
                                      child: _SleepEntryItem(
                                        sleepTime: isSkeleton
                                            ? '22:30'
                                            : diary!.sleeps[entry].sleepTime,
                                        wakeTime: isSkeleton
                                            ? '06:30'
                                            : diary!.sleeps[entry].wakeTime,
                                        duration: isSkeleton
                                            ? 8
                                            : diary!.sleeps[entry]
                                                .sleepDurationHours,
                                        showDivider: isSkeleton
                                            ? false
                                            : entry !=
                                                (diary?.sleeps.length ?? 0) - 1,
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Text(
                              diaryState.error!,
                              style: const TextStyle(
                                color: Color(0xFFB91C1C),
                                fontSize: 14,
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
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 85,
        height: 38,
        // decoration: BoxDecoration(
        //   color: const Color(0xFFFFE7EE),
        //   borderRadius: BorderRadius.circular(19),
        // ),
        child: Row(
          children: [
            const Icon(
              Icons.add,
              color: Color(0xFFE64060),
              size: 22,
            ),
            const Text("Tambah",
                style: TextStyle(fontSize: 14, color: Color(0xFFE64060))),
          ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _BodyMetricEntryItem extends StatelessWidget {
  final String conditionLabel;
  final String recordedTime;
  final num? bodyHeight;
  final num? bodyWeight;
  final num? systolicPressure;
  final num? diastolicPressure;
  final num? heartRate;
  final bool showDivider;

  const _BodyMetricEntryItem({
    required this.conditionLabel,
    required this.recordedTime,
    required this.bodyHeight,
    required this.bodyWeight,
    required this.systolicPressure,
    required this.diastolicPressure,
    required this.heartRate,
    this.showDivider = false,
  });

  String _v(num? value, [String unit = '']) {
    if (value == null) return '-';
    return unit.isEmpty ? '$value' : '$value $unit';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$conditionLabel • $recordedTime',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tinggi ${_v(bodyHeight, 'cm')} | Berat ${_v(bodyWeight, 'kg')}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Tekanan ${_v(systolicPressure)}/${_v(diastolicPressure)} mmHg | Nadi ${_v(heartRate, 'BPM')}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF475569),
          ),
        ),
        if (showDivider) ...[
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFEFF2F6)),
        ],
      ],
    );
  }
}

class _SymptomEntryItem extends StatelessWidget {
  final String name;
  final num? intensity;
  final String? note;
  final String recordedTime;
  final bool showDivider;

  const _SymptomEntryItem({
    required this.name,
    required this.intensity,
    required this.note,
    required this.recordedTime,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 58,
          child: Text(
            recordedTime,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Intensitas ${intensity?.toString() ?? '-'}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                ),
              ),
              if ((note ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  note!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
              if (showDivider) ...[
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFEFF2F6)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityEntryItem extends StatelessWidget {
  final String name;
  final num? duration;
  final num? heartRate;
  final String? feeling;
  final String recordedTime;
  final bool showDivider;

  const _ActivityEntryItem({
    required this.name,
    required this.duration,
    required this.heartRate,
    required this.feeling,
    required this.recordedTime,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 58,
          child: Text(
            recordedTime,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${duration?.toString() ?? '-'} menit • ${heartRate?.toString() ?? '-'} BPM',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Perasaan: ${(feeling ?? '').isEmpty ? '-' : feeling}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              if (showDivider) ...[
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFEFF2F6)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SleepEntryItem extends StatelessWidget {
  final String sleepTime;
  final String wakeTime;
  final num? duration;
  final bool showDivider;

  const _SleepEntryItem({
    required this.sleepTime,
    required this.wakeTime,
    required this.duration,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.timer_outlined,
                size: 16, color: Color(0xFF3B82F6)),
            const SizedBox(width: 8),
            Text(
              'Tidur: $sleepTime - Bangun: $wakeTime',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Durasi: ${duration?.toStringAsFixed(1) ?? '-'} jam',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF475569),
          ),
        ),
        if (showDivider) ...[
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFEFF2F6)),
        ],
      ],
    );
  }
}

class _ConsumptionEntryItem extends StatelessWidget {
  final String typeLabel;
  final String title;
  final String? portion;
  final String? note;
  final String recordedTime;
  final bool showDivider;

  const _ConsumptionEntryItem({
    required this.typeLabel,
    required this.title,
    required this.portion,
    required this.note,
    required this.recordedTime,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 58,
          child: Text(
            recordedTime,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$typeLabel • ${(portion ?? '').isEmpty ? '-' : portion}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              if ((note ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  note!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
              if (showDivider) ...[
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFEFF2F6)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
