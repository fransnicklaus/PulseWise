// import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/features/ml_recommendation/data/models/ml_recommendation_models.dart';
import 'package:pulsewise/features/ml_recommendation/presentation/providers/recommendation_history_provider.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../../../../core/widgets/custom_app_bar.dart';

class MlRecommendationHistoryPage extends ConsumerStatefulWidget {
  const MlRecommendationHistoryPage({super.key});

  @override
  ConsumerState<MlRecommendationHistoryPage> createState() =>
      _MlRecommendationHistoryPageState();
}

class _MlRecommendationHistoryPageState
    extends ConsumerState<MlRecommendationHistoryPage> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _itemKeys = <String, GlobalKey>{};
  String? _expandedId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadThisMonth();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 220;
    if (_scrollController.position.pixels >= threshold) {
      ref.read(recommendationHistoryNotifierProvider.notifier).loadNextPage();
    }
  }

  void _loadThisMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    ref
        .read(recommendationHistoryNotifierProvider.notifier)
        .loadRecommendationHistory(
          page: 1,
          limit: 10,
          startDate: startOfMonth,
          endDate: endOfMonth,
        );
  }

  void _toggleEntry(String id) async {
    final isExpanded = _expandedId == id;
    setState(() {
      _expandedId = _expandedId == id ? null : id;
    });

    if (isExpanded) return;

    await ref
        .read(recommendationHistoryNotifierProvider.notifier)
        .loadRecommendationDetail(id);
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _itemKeys[id];
      final ctx = key?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  String formatToCustomDate(String isoString) {
    // 1. Parse the string to a DateTime object
    DateTime dateTime = DateTime.parse(isoString);

    // 2. Define the month names
    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Des'
    ];

    // 3. Extract parts
    String day = dateTime.day.toString();
    String month = months[dateTime.month - 1]; // -1 because months are 1-12
    int year = dateTime.year;

    // 4. Return the combined string
    return "$day $month $year";
  }

  String formatWithTime(String isoString) {
    DateTime dateTime = DateTime.parse(isoString);

    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    // Date parts
    String day = dateTime.day.toString();
    String month = months[dateTime.month - 1];
    int year = dateTime.year;
    Duration offset = DateTime.now().timeZoneOffset;

    // Ambil jam dan menit dari durasi offset
    int offsetHour = offset.inHours;

    // Time parts (padded to 2 digits)
    String hour = (dateTime.hour + offsetHour).toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');

    return "$day $month $year, $hour:$minute";
  }

  DateTime _asDateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final state = ref.read(recommendationHistoryNotifierProvider);
    final currentStart = state.startDate ?? DateTime(now.year, now.month, 1);
    final currentEnd = state.endDate ?? DateTime(now.year, now.month + 1, 0);

    final picked = await showDatePicker(
      context: context,
      initialDate: currentStart,
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
    );

    if (picked == null || !mounted) return;

    var startDate = _asDateOnly(picked);
    var endDate = _asDateOnly(currentEnd);

    if (startDate.isAfter(endDate)) {
      endDate = startDate;
    }

    setState(() {
      _expandedId = null;
    });

    await ref
        .read(recommendationHistoryNotifierProvider.notifier)
        .loadRecommendationHistory(
          page: 1,
          limit: 10,
          startDate: startDate,
          endDate: endDate,
        );
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final state = ref.read(recommendationHistoryNotifierProvider);
    final currentStart = state.startDate ?? DateTime(now.year, now.month, 1);
    final currentEnd = state.endDate ?? DateTime(now.year, now.month + 1, 0);

    final picked = await showDatePicker(
      context: context,
      initialDate: currentEnd,
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
    );

    if (picked == null || !mounted) return;

    var startDate = _asDateOnly(currentStart);
    var endDate = _asDateOnly(picked);

    if (endDate.isBefore(startDate)) {
      startDate = endDate;
    }

    setState(() {
      _expandedId = null;
    });

    await ref
        .read(recommendationHistoryNotifierProvider.notifier)
        .loadRecommendationHistory(
          page: 1,
          limit: 10,
          startDate: startDate,
          endDate: endDate,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recommendationHistoryNotifierProvider);
    final startLabel =
        state.startDate != null ? _formatDate(state.startDate) : 'Start date';
    final endLabel =
        state.endDate != null ? _formatDate(state.endDate) : 'End date';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      extendBody: true,
      appBar: CustomAppBar(
        title: 'Riwayat Prediksi ML',
        subtitle: 'Hasil Prediksi & Rekomendasi',
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(recommendationHistoryNotifierProvider.notifier)
            .refreshHistory(),
        color: const Color(0xFFE64060),
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
                constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 16, left: 16, right: 16, bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.event_available, size: 18),
                              label: Text(
                                startLabel,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 18),
                              ),
                              onPressed:
                                  state.isLoading ? null : _pickStartDate,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF475569),
                                side:
                                    const BorderSide(color: Color(0xFFD9E2EC)),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '-',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.event, size: 18),
                              label: Text(
                                endLabel,
                                style: TextStyle(fontSize: 18),
                              ),
                              onPressed: state.isLoading ? null : _pickEndDate,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF475569),
                                side:
                                    const BorderSide(color: Color(0xFFD9E2EC)),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (state.isLoading)
                      const SizedBox(
                        height: 240,
                        child: Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFE64060)),
                        ),
                      )
                    else if (state.items.isEmpty)
                      const SizedBox(
                        height: 240,
                        child: Center(
                          child: Text(
                            'Belum ada riwayat prediksi ML',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                    else
                      ...state.items.map((item) {
                        // final id = state.items.indexWhere((e) => e.resultId == item.resultId);
                        final id = item.resultId;
                        final detail = state.detailsByDiaryId[id];
                        final isDetailLoading =
                            state.loadingDetailDiaryIds.contains(id);
                        final detailError = state.detailErrorsByDiaryId[id];
                        // return _itemKeys[id] ??= GlobalKey();
                        // final id = item.resultId as String;
                        final date = formatToCustomDate(item.generatedAt);
                        final dateTime = formatWithTime(item.generatedAt);
                        // final cleanDate = formatToCustomDate(
                        //     date.toIso8601String().split('T')[0]);

                        final isExpanded = _expandedId == id;

                        return Padding(
                          key: _itemKeys[id],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 7,
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _toggleEntry(id),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              date,
                                              style: const TextStyle(
                                                color: Color(0xFF1E293B),
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              'Dibuat $dateTime',
                                              style: const TextStyle(
                                                color: Color(0xFF64748B),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      AnimatedRotation(
                                        turns: isExpanded ? 0.25 : 0,
                                        duration:
                                            const Duration(milliseconds: 220),
                                        child: const Icon(
                                          Icons.chevron_right,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                  ClipRect(
                                    child: AnimatedSize(
                                      duration:
                                          const Duration(milliseconds: 220),
                                      curve: Curves.easeInOutCubic,
                                      alignment: Alignment.topCenter,
                                      child: AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 180),
                                        switchInCurve: Curves.easeOut,
                                        switchOutCurve: Curves.easeIn,
                                        transitionBuilder: (child, animation) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          );
                                        },
                                        child: isExpanded
                                            ? Padding(
                                                key: ValueKey<String>(
                                                  'expanded-$id',
                                                ),
                                                padding: const EdgeInsets.only(
                                                    top: 12),
                                                // child: Text('this works'),
                                                child: _ExpandedArea(
                                                  detail: detail,
                                                  isLoading: isDetailLoading,
                                                  error: detailError,
                                                ),
                                              )
                                            : const SizedBox(
                                                key: ValueKey<String>(
                                                    'collapsed'),
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    //   SliverPadding(
                    //     padding: const EdgeInsets.symmetric(vertical: 16),
                    //     sliver: SliverList(
                    //       delegate: SliverChildBuilderDelegate(
                    //         (context, index) {
                    //           final item = state.items[index];
                    //           final id = item.resultId as String;
                    //           final date = formatToCustomDate(item.generatedAt);
                    //           final dateTime = formatWithTime(item.generatedAt);
                    //           // final cleanDate = formatToCustomDate(
                    //           //     date.toIso8601String().split('T')[0]);

                    //           final isExpanded = _expandedId == id;

                    //           return Padding(
                    //             key: _itemKeys[id],
                    //             padding: const EdgeInsets.symmetric(
                    //                 horizontal: 16, vertical: 7),
                    //             child: InkWell(
                    //               borderRadius: BorderRadius.circular(16),
                    //               onTap: () => _toggleEntry(id),
                    //               child: Container(
                    //                 padding: const EdgeInsets.all(16),
                    //                 decoration: BoxDecoration(
                    //                   color: Colors.white,
                    //                   borderRadius: BorderRadius.circular(16),
                    //                   boxShadow: [
                    //                     BoxShadow(
                    //                       color: Colors.black.withOpacity(0.03),
                    //                       blurRadius: 10,
                    //                       offset: const Offset(0, 4),
                    //                     ),
                    //                   ],
                    //                 ),
                    //                 child: Column(
                    //                   crossAxisAlignment:
                    //                       CrossAxisAlignment.start,
                    //                   children: [
                    //                     Row(
                    //                       children: [
                    //                         Expanded(
                    //                           child: Column(
                    //                             crossAxisAlignment:
                    //                                 CrossAxisAlignment.start,
                    //                             children: [
                    //                               Text(
                    //                                 date,
                    //                                 style: const TextStyle(
                    //                                   color: Color(0xFF1E293B),
                    //                                   fontSize: 17,
                    //                                   fontWeight:
                    //                                       FontWeight.w700,
                    //                                 ),
                    //                               ),
                    //                               const SizedBox(height: 3),
                    //                               Text(
                    //                                 'Dibuat $dateTime',
                    //                                 style: const TextStyle(
                    //                                   color: Color(0xFF64748B),
                    //                                   fontSize: 13,
                    //                                   fontWeight:
                    //                                       FontWeight.w500,
                    //                                 ),
                    //                               ),
                    //                             ],
                    //                           ),
                    //                         ),
                    //                         AnimatedRotation(
                    //                           turns: isExpanded ? 0.25 : 0,
                    //                           duration: const Duration(
                    //                               milliseconds: 220),
                    //                           child: const Icon(
                    //                             Icons.chevron_right,
                    //                             color: Color(0xFF94A3B8),
                    //                           ),
                    //                         ),
                    //                       ],
                    //                     ),
                    //                   ],
                    //                 ),
                    //               ),
                    //             ),
                    //           );
                    //         },
                    //         childCount: state.items.length,
                    //       ),
                    //     ),
                    //   ),
                    // if (state.error != null && state.items.isEmpty)
                    //   Padding(
                    //     padding: const EdgeInsets.symmetric(
                    //         horizontal: 16, vertical: 14),
                    //     child: Text(
                    //       state.error!,
                    //       style: const TextStyle(
                    //         color: Color(0xFFB91C1C),
                    //         fontSize: 13,
                    //       ),
                    //     ),
                    //   ),
                    // if (state.error != null && state.items.isEmpty)
                    //   Padding(
                    //     padding: const EdgeInsets.symmetric(
                    //         horizontal: 16, vertical: 14),
                    //     child: Text(
                    //       state.error!,
                    //       style: const TextStyle(
                    //         color: Color(0xFFB91C1C),
                    //         fontSize: 13,
                    //       ),
                    //     ),
                    //   ),
                    // if (state.isLoadingMore)
                    //   const Padding(
                    //     padding: EdgeInsets.only(top: 8, bottom: 18),
                    //     child: Center(
                    //       child: SizedBox(
                    //         width: 22,
                    //         height: 22,
                    //         child: CircularProgressIndicator(
                    //           strokeWidth: 2.3,
                    //           color: Color(0xFFE64060),
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                  ],
                ))),
      ),
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agt',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}

class _ExpandedArea extends StatelessWidget {
  final MlRecommendationResponse? detail;
  final bool isLoading;
  final String? error;

  const _ExpandedArea(
      {required this.detail, required this.isLoading, this.error});

  @override
  Widget build(BuildContext context) {
    // final state = ref.watch(recommendationhistoryNotifier);
    // final _mlPredictionResult = detail!.data;
    // final currentRisk =
    //     _mlPredictionResult?.upstream?.body?.recommendationResult.currentRisk;
    // final _mlRecommendation = detail;

    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(
            color: Color(0xFFE13D5A),
          ),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            error!,
            style: const TextStyle(
              color: Color(0xFFB91C1C),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    if (detail == null) {
      return const SizedBox.shrink();
    }
    final currentRisk =
        detail!.data!.upstream!.body!.recommendationResult.currentRisk;
    final currentRiskPercentage = currentRisk.toStringAsFixed(1);
    return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Prediksi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A202C),
                )),
            const SizedBox(height: 24),
            SfLinearGauge(
              minimum: 0,
              maximum: 100,
              orientation: LinearGaugeOrientation.horizontal,
              ranges: const <LinearGaugeRange>[
                LinearGaugeRange(
                    startValue: 0, endValue: 60, color: Colors.green),
                LinearGaugeRange(
                    startValue: 60, endValue: 80, color: Colors.orange),
                LinearGaugeRange(
                    startValue: 80, endValue: 100, color: Colors.red),
              ],
              markerPointers: [
                LinearShapePointer(
                  value: currentRisk,
                  shapeType: LinearShapePointerType.invertedTriangle,
                  color: Colors.black,
                  position: LinearElementPosition.outside,
                ),
                // LinearWidgetPointer(
                //   value: 48000,
                //   child: Container(width: 2, height: 40, color: Colors.black),
                // )
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Risiko Saat Ini: $currentRiskPercentage%',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A202C),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            _buildRekomendasiSection(detail),
          ],
        ));
  }
}

Widget _buildRekomendasiSection(MlRecommendationResponse? mlRec) {
  final lifestyle =
      mlRec?.data?.upstream?.body?.recommendationResult.lifestyle ?? [];
  final recommendationIncrease = lifestyle
      .where((r) => r.comparison.toLowerCase().contains('tingkat'))
      .toList();
  final recommendationDecrease = lifestyle
      .where((r) => r.comparison.toLowerCase().contains('kurang'))
      .toList();

  return Container(
    width: double.infinity,
    // padding: const EdgeInsets.all(24),
    // decoration: BoxDecoration(
    //   color: Colors.white,
    //   borderRadius: BorderRadius.circular(24),
    //   border: Border.all(color: const Color(0xFFF1F5F9)),
    // ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row(
        //   children: [
        //     Container(
        //       padding: const EdgeInsets.all(10),
        //       decoration: BoxDecoration(
        //         color: const Color(0xFFFFF0F2),
        //         borderRadius: BorderRadius.circular(12),
        //       ),
        //       child: const Icon(Icons.recommend, color: Color(0xFFE13D5A)),
        //     ),
        //     const SizedBox(width: 16),
        //     const Text(
        //       'Rekomendasi',
        //       style: TextStyle(
        //         fontSize: 20,
        //         fontWeight: FontWeight.bold,
        //         color: Color(0xFF1A202C),
        //       ),
        //     ),
        //   ],
        // ),
        const Text('Rekomendasi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A202C),
            )),
        const SizedBox(height: 20),
        if (lifestyle.isEmpty)
          const Text(
            'Tidak ada rekomendasi spesifik saat ini.',
            style: TextStyle(color: Color(0xFF4A5568)),
          ),
        ...recommendationIncrease.map((item) {
          final title =
              item.comparison.isNotEmpty ? item.comparison : item.description;

          return RecommendationItem(
            title: title,
            action: 'increase',
          );
        }),
        ...recommendationDecrease.map((item) {
          final title =
              item.comparison.isNotEmpty ? item.comparison : item.description;

          return RecommendationItem(
            title: title,
            action: 'decrease',
          );
        }),
      ],
    ),
  );
}

class RecommendationItem extends StatelessWidget {
  final String title;
  // final String description;
  final String action; // 'increase', 'decrease', or ''

  const RecommendationItem({
    super.key,
    required this.title,
    // required this.description,
    this.action = '',
  });

  @override
  Widget build(BuildContext context) {
    Color? actionColor;
    IconData? actionIcon;

    if (action == 'increase') {
      actionColor = Colors.green;
      actionIcon = Icons.arrow_upward;
    } else if (action == 'decrease') {
      actionColor = Colors.red;
      actionIcon = Icons.arrow_downward;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (actionIcon != null)
          CircleAvatar(
            backgroundColor: actionColor!.withOpacity(0.2),
            radius: 10,
            child: Icon(actionIcon, size: 16, color: actionColor),
          ),
        if (actionIcon != null) const SizedBox(width: 8),
        Expanded(
          // Expanded harus di luar Padding jika ini di dalam Row
          child: Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 12, left: 4),
            child: Text(
              title,
              softWrap: true, // Memastikan teks membungkus
              overflow: TextOverflow
                  .visible, // Atau TextOverflow.ellipsis jika ingin dipotong titik-titik
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A202C),
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
