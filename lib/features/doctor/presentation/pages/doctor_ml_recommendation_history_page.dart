import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/features/doctor/presentation/providers/doctor_recommendation_history_provider.dart';
import 'package:pulsewise/features/home_dashboard/presentation/pages/patient_flutter.dart'
    show RecommendationItem;
import 'package:pulsewise/features/ml_recommendation/data/models/ml_recommendation_models.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class DoctorMlRecommendationHistoryPage extends ConsumerStatefulWidget {
  const DoctorMlRecommendationHistoryPage({
    super.key,
    required this.patientId,
  });

  final String patientId;

  @override
  ConsumerState<DoctorMlRecommendationHistoryPage> createState() =>
      _DoctorMlRecommendationHistoryPageState();
}

class _DoctorMlRecommendationHistoryPageState
    extends ConsumerState<DoctorMlRecommendationHistoryPage> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _itemKeys = <String, GlobalKey>{};
  String? _expandedId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(
            doctorRecommendationHistoryNotifierProvider(widget.patientId)
                .notifier,
          )
          .loadRecommendationHistory(page: 1, limit: 10);
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
      ref
          .read(
            doctorRecommendationHistoryNotifierProvider(widget.patientId)
                .notifier,
          )
          .loadNextPage();
    }
  }

  Future<void> _toggleEntry(String resultId) async {
    final isExpanded = _expandedId == resultId;
    setState(() {
      _expandedId = isExpanded ? null : resultId;
    });

    if (isExpanded) return;

    await ref
        .read(
          doctorRecommendationHistoryNotifierProvider(widget.patientId)
              .notifier,
        )
        .loadRecommendationDetail(resultId);
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _itemKeys[resultId];
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

  @override
  Widget build(BuildContext context) {
    final state = ref
        .watch(doctorRecommendationHistoryNotifierProvider(widget.patientId));

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
            .read(
              doctorRecommendationHistoryNotifierProvider(widget.patientId)
                  .notifier,
            )
            .refreshHistory(),
        color: const Color(0xFFE64060),
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints:
                BoxConstraints(minHeight: MediaQuery.of(context).size.height),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 18, 16, 6),
                  child: Text(
                    'Riwayat rekomendasi terbaru pasien yang pernah dibuka dari dashboard dokter.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                ),
                if (state.isLoading)
                  const SizedBox(
                    height: 240,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE64060),
                      ),
                    ),
                  )
                else if (state.error != null && state.items.isEmpty)
                  SizedBox(
                    height: 240,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          state.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFB91C1C),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                          ),
                        ),
                      ),
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
                    final resultId = item.resultId;
                    final detail = state.detailsByResultId[resultId];
                    final isDetailLoading =
                        state.loadingDetailResultIds.contains(resultId);
                    final detailError = state.detailErrorsByResultId[resultId];
                    final date = _formatSimpleDate(item.generatedAt);
                    final dateTime = _formatDateWithTime(item.generatedAt);
                    final isExpanded = _expandedId == resultId;

                    return Padding(
                      key: _itemKeys[resultId] ??= GlobalKey(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _toggleEntry(resultId),
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
                                    duration: const Duration(milliseconds: 220),
                                    child: const Icon(
                                      Icons.chevron_right,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                              ClipRect(
                                child: AnimatedSize(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeInOutCubic,
                                  alignment: Alignment.topCenter,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 180),
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
                                              'expanded-$resultId',
                                            ),
                                            padding:
                                                const EdgeInsets.only(top: 12),
                                            child: _DoctorExpandedHistoryArea(
                                              detail: detail,
                                              isLoading: isDetailLoading,
                                              error: detailError,
                                            ),
                                          )
                                        : const SizedBox(
                                            key: ValueKey<String>('collapsed'),
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
                if (state.isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 18),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          color: Color(0xFFE64060),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DoctorExpandedHistoryArea extends StatelessWidget {
  const _DoctorExpandedHistoryArea({
    required this.detail,
    required this.isLoading,
    this.error,
  });

  final MlRecommendationResponse? detail;
  final bool isLoading;
  final String? error;

  @override
  Widget build(BuildContext context) {
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
        detail?.data?.upstream?.body?.recommendationResult.currentRisk ?? 0;
    final currentRiskPercentage = currentRisk.toStringAsFixed(1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prediksi',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 24),
          SfLinearGauge(
            minimum: 0,
            maximum: 100,
            orientation: LinearGaugeOrientation.horizontal,
            ranges: const <LinearGaugeRange>[
              LinearGaugeRange(
                startValue: 0,
                endValue: 60,
                color: Colors.green,
              ),
              LinearGaugeRange(
                startValue: 60,
                endValue: 80,
                color: Colors.orange,
              ),
              LinearGaugeRange(
                startValue: 80,
                endValue: 100,
                color: Colors.red,
              ),
            ],
            markerPointers: [
              LinearShapePointer(
                value: currentRisk,
                shapeType: LinearShapePointerType.invertedTriangle,
                color: Colors.black,
                position: LinearElementPosition.outside,
              ),
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
          _DoctorHistoryRecommendationSection(mlRec: detail),
        ],
      ),
    );
  }
}

class _DoctorHistoryRecommendationSection extends StatelessWidget {
  const _DoctorHistoryRecommendationSection({required this.mlRec});

  final MlRecommendationResponse? mlRec;

  @override
  Widget build(BuildContext context) {
    final lifestyle =
        mlRec?.data?.upstream?.body?.recommendationResult.lifestyle ?? [];
    final recommendationIncrease = lifestyle
        .where((item) => item.comparison.toLowerCase().contains('tingkat'))
        .toList();
    final recommendationDecrease = lifestyle
        .where((item) => item.comparison.toLowerCase().contains('kurang'))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rekomendasi',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A202C),
          ),
        ),
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
    );
  }
}

String _formatSimpleDate(String isoString) {
  final dateTime = DateTime.parse(isoString);
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
}

String _formatDateWithTime(String isoString) {
  final dateTime = DateTime.parse(isoString).toLocal();
  const months = [
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
    'Dec',
  ];

  final day = dateTime.day.toString();
  final month = months[dateTime.month - 1];
  final year = dateTime.year;
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');

  return '$day $month $year, $hour:$minute';
}
