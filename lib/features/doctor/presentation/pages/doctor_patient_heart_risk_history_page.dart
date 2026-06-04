import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/network/network_error_utils.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/core/widgets/no_connection_state.dart';
import 'package:pulsewise/features/doctor/data/models/doctor_heart_risk_models.dart';
import 'package:pulsewise/features/doctor/presentation/providers/doctor_dashboard_provider.dart';
import 'package:pulsewise/features/home_dashboard/data/models/dashboard_overview_models.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class DoctorPatientHeartRiskHistoryPage extends ConsumerStatefulWidget {
  const DoctorPatientHeartRiskHistoryPage({
    super.key,
    required this.patientId,
    this.entryData,
  });

  final String patientId;
  final DoctorHeartRiskEntryData? entryData;

  @override
  ConsumerState<DoctorPatientHeartRiskHistoryPage> createState() =>
      _DoctorPatientHeartRiskHistoryPageState();
}

class _DoctorPatientHeartRiskHistoryPageState
    extends ConsumerState<DoctorPatientHeartRiskHistoryPage> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _itemKeys = <String, GlobalKey>{};

  List<DoctorHeartRiskPredictionResult> _items =
      <DoctorHeartRiskPredictionResult>[];
  final Map<String, DoctorHeartRiskPredictionResult> _detailsByResultId =
      <String, DoctorHeartRiskPredictionResult>{};
  final Set<String> _loadingDetailResultIds = <String>{};
  final Map<String, String> _detailErrorsByResultId = <String, String>{};
  final Map<String, Object> _detailErrorCausesByResultId = <String, Object>{};

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  Object? _errorCause;
  int _page = 1;
  int _limit = 10;
  int _totalPages = 1;
  DateTime? _startDate;
  DateTime? _endDate;
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
      _loadNextPage();
    }
  }

  void _loadThisMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    _loadHistory(
      page: 1,
      limit: 10,
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
  }

  Future<void> _loadHistory({
    int page = 1,
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
    bool append = false,
  }) async {
    if (!mounted) return;
    if (append && (_isLoading || _isLoadingMore)) return;

    setState(() {
      _isLoading = !append;
      _isLoadingMore = append;
      _error = null;
      _errorCause = null;
      _page = page;
      _limit = limit;
      _startDate = startDate;
      _endDate = endDate;
    });

    try {
      final response = await ref
          .read(doctorDashboardApiProvider)
          .fetchPatientHeartRiskPredictionHistory(
            widget.patientId,
            page: page,
            limit: limit,
            startDate: startDate,
            endDate: endDate,
          );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _items = append ? [..._items, ...response.items] : response.items;
        _page = response.page;
        _limit = response.limit;
        _totalPages = response.totalPages;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _error = error.toString().replaceFirst('Exception: ', '');
        _errorCause = error;
      });
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || _isLoadingMore) return;
    if (_page >= _totalPages) return;

    await _loadHistory(
      page: _page + 1,
      limit: _limit,
      startDate: _startDate,
      endDate: _endDate,
      append: true,
    );
  }

  Future<void> _refreshHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!mounted) return;

    setState(() {
      _expandedId = null;
      _detailsByResultId.clear();
      _detailErrorsByResultId.clear();
      _detailErrorCausesByResultId.clear();
      _loadingDetailResultIds.clear();
    });

    await _loadHistory(
      page: 1,
      limit: _limit,
      startDate: startDate ?? _startDate,
      endDate: endDate ?? _endDate,
    );
  }

  Future<void> _loadHistoryDetail(String resultId) async {
    if (_detailsByResultId.containsKey(resultId)) return;
    if (_loadingDetailResultIds.contains(resultId)) return;
    if (!mounted) return;

    setState(() {
      _loadingDetailResultIds.add(resultId);
      _detailErrorsByResultId.remove(resultId);
      _detailErrorCausesByResultId.remove(resultId);
    });

    try {
      final detail = await ref
          .read(doctorDashboardApiProvider)
          .fetchPatientHeartRiskPredictionHistoryDetail(
            widget.patientId,
            resultId,
          );

      if (!mounted) return;

      setState(() {
        _detailsByResultId[resultId] = detail;
        _loadingDetailResultIds.remove(resultId);
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadingDetailResultIds.remove(resultId);
        _detailErrorsByResultId[resultId] =
            error.toString().replaceFirst('Exception: ', '');
        _detailErrorCausesByResultId[resultId] = error;
      });
    }
  }

  Future<void> _toggleEntry(String resultId) async {
    final isExpanded = _expandedId == resultId;
    setState(() {
      _expandedId = isExpanded ? null : resultId;
    });

    if (isExpanded) return;

    await _loadHistoryDetail(resultId);
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

  DateTime _asDateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final currentStart = _startDate ?? DateTime(now.year, now.month, 1);
    final currentEnd = _endDate ?? DateTime(now.year, now.month + 1, 0);

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

    await _refreshHistory(
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final currentStart = _startDate ?? DateTime(now.year, now.month, 1);
    final currentEnd = _endDate ?? DateTime(now.year, now.month + 1, 0);

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

    await _refreshHistory(
      startDate: startDate,
      endDate: endDate,
    );
  }

  bool _isNetworkError(Object? error) {
    return error != null && isNetworkRequestError(error);
  }

  String get _subtitle {
    final fullName = _patientFullName(widget.entryData?.patient);
    return fullName.isEmpty ? 'Second ML Pasien' : fullName;
  }

  @override
  Widget build(BuildContext context) {
    final startLabel =
        _startDate != null ? _formatFilterDate(_startDate) : 'Start date';
    final endLabel =
        _endDate != null ? _formatFilterDate(_endDate) : 'End date';
    final showInitialLoading = _isLoading && _items.isEmpty;
    final showOfflinePage =
        _isNetworkError(_errorCause) && _items.isEmpty && !_isLoading;
    final showOfflineBanner = _isNetworkError(_errorCause) && _items.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CustomAppBar(
        title: 'Riwayat Prediksi Heart Risk',
        subtitle: _subtitle,
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshHistory(),
        color: const Color(0xFFE64060),
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: 16,
                    left: 16,
                    right: 16,
                    bottom: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.event_available, size: 18),
                          label: Text(
                            startLabel,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 18),
                          ),
                          onPressed: _isLoading ? null : _pickStartDate,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF475569),
                            side: const BorderSide(color: Color(0xFFD9E2EC)),
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
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 18),
                          ),
                          onPressed: _isLoading ? null : _pickEndDate,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF475569),
                            side: const BorderSide(color: Color(0xFFD9E2EC)),
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
                if (showOfflineBanner)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: NoConnectionState.compact(
                      title: 'Riwayat prediksi belum tersinkron',
                      message:
                          'Data terakhir tetap ditampilkan. Sambungkan internet lalu tarik untuk memuat ulang.',
                      onRetry: () => _refreshHistory(),
                    ),
                  ),
                if (showInitialLoading)
                  const SizedBox(
                    height: 240,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE64060),
                      ),
                    ),
                  )
                else if (showOfflinePage)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: NoConnectionState.card(
                      title: 'Riwayat prediksi belum bisa dimuat',
                      message:
                          'Kami belum bisa mengambil riwayat prediksi heart risk untuk periode ini. Cek koneksi internet Anda lalu coba lagi.',
                      onRetry: () => _refreshHistory(),
                    ),
                  )
                else if (_error != null && _items.isEmpty)
                  SizedBox(
                    height: 240,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _error!,
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
                else if (_items.isEmpty)
                  const SizedBox(
                    height: 240,
                    child: Center(
                      child: Text(
                        'Belum ada riwayat prediksi heart risk',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                else
                  ..._items.map((item) {
                    final resultId = item.resultId;
                    final detail = _detailsByResultId[resultId];
                    final isDetailLoading =
                        _loadingDetailResultIds.contains(resultId);
                    final detailError = _detailErrorsByResultId[resultId];
                    final detailErrorCause =
                        _detailErrorCausesByResultId[resultId];
                    final date = _formatHistoryDate(item.generatedAt);
                    final dateTime = _formatDateTime(item.generatedAt);
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
                                            child:
                                                _ExpandedHeartRiskHistoryArea(
                                              detail: detail,
                                              isLoading: isDetailLoading,
                                              error: detailError,
                                              errorCause: detailErrorCause,
                                              onRetry: () => _loadHistoryDetail(
                                                resultId,
                                              ),
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
                if (_isLoadingMore)
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

class _ExpandedHeartRiskHistoryArea extends StatelessWidget {
  const _ExpandedHeartRiskHistoryArea({
    required this.detail,
    required this.isLoading,
    required this.onRetry,
    this.error,
    this.errorCause,
  });

  final DoctorHeartRiskPredictionResult? detail;
  final bool isLoading;
  final String? error;
  final Object? errorCause;
  final VoidCallback onRetry;

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
      if (errorCause != null && isNetworkRequestError(errorCause!)) {
        return NoConnectionState.card(
          title: 'Detail prediksi belum bisa dimuat',
          message:
              'Koneksi internet sedang bermasalah. Sambungkan lagi lalu coba muat detail ini.',
          onRetry: onRetry,
        );
      }

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

    final upstream = detail!.upstream?.body;
    final probability = ((upstream?.probability ?? 0) * 100).toDouble();
    final threshold = ((upstream?.threshold ?? 0) * 100).toDouble();
    final riskLevel = (upstream?.riskLevel ?? '').trim();

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
            ranges: <LinearGaugeRange>[
              LinearGaugeRange(
                startValue: 0,
                endValue: threshold <= 0 ? 43 : threshold,
                color: Colors.green,
              ),
              LinearGaugeRange(
                startValue: threshold <= 0 ? 43 : threshold,
                endValue: 100,
                color: Colors.red,
              ),
            ],
            markerPointers: [
              LinearShapePointer(
                value: probability.clamp(0, 100),
                shapeType: LinearShapePointerType.invertedTriangle,
                color: Colors.black,
                position: LinearElementPosition.outside,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Risiko Saat Ini: ${probability.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A202C),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _riskChipBackground(riskLevel),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _riskLabel(riskLevel),
                style: TextStyle(
                  color: _riskChipForeground(riskLevel),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _HeartRiskDetailInfoRow(
                  label: 'Threshold',
                  value: '${threshold.toStringAsFixed(0)}%',
                ),
                _HeartRiskDetailInfoRow(
                  label: 'Tanggal Assessment',
                  value: detail!.sourceSummary?.assessmentDate ?? '-',
                ),
                _HeartRiskDetailInfoRow(
                  label: 'Periode',
                  value: _windowLabel(detail!.window),
                ),
                _HeartRiskDetailInfoRow(
                  label: 'Generated',
                  value: _formatDateTime(detail!.generatedAt),
                ),
                _HeartRiskDetailInfoRow(
                  label: 'Created At',
                  value: _formatDateTime(detail!.createdAt),
                  isLast: true,
                ),
              ],
            ),
          ),
          if (detail!.assessment != null) ...[
            const SizedBox(height: 20),
            const Text(
              'Asesmen',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A202C),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _HeartRiskDetailInfoRow(
                    label: 'Tanggal Asesmen',
                    value: detail!.assessment!.assessmentDate ?? '-',
                  ),
                  _HeartRiskDetailInfoRow(
                    label: 'Usia',
                    value: detail!.assessment!.age?.toString() ?? '-',
                  ),
                  _HeartRiskDetailInfoRow(
                    label: 'Jenis Kelamin',
                    value: heartRiskEnumLabel('sex', detail!.assessment!.sex),
                  ),
                  _HeartRiskDetailInfoRow(
                    label: 'Jenis Nyeri Dada',
                    value: heartRiskEnumLabel(
                      'chest_pain_type',
                      detail!.assessment!.chestPainType,
                    ),
                  ),
                  _HeartRiskDetailInfoRow(
                    label: 'Tekanan Darah Sistolik',
                    value: _numLabel(detail!.assessment!.restingBpS),
                  ),
                  _HeartRiskDetailInfoRow(
                    label: 'Gula Darah Puasa',
                    value: heartRiskEnumLabel(
                      'fasting_blood_sugar',
                      detail!.assessment!.fastingBloodSugar,
                    ),
                  ),
                  _HeartRiskDetailInfoRow(
                    label: 'Detak Jantung Maksimum',
                    value: _numLabel(detail!.assessment!.maxHeartRate),
                  ),
                  _HeartRiskDetailInfoRow(
                    label: 'Angina Saat Aktivitas',
                    value: heartRiskEnumLabel(
                      'exercise_angina',
                      detail!.assessment!.exerciseAngina,
                    ),
                  ),
                  _HeartRiskDetailInfoRow(
                    label: 'Old Peak',
                    value: _numLabel(detail!.assessment!.oldPeak),
                  ),
                  _HeartRiskDetailInfoRow(
                    label: 'Kemiringan ST',
                    value: heartRiskEnumLabel(
                      'st_slope',
                      detail!.assessment!.stSlope,
                    ),
                  ),
                  _HeartRiskDetailInfoRow(
                    label: 'Diperbarui',
                    value: _formatDateTime(detail!.assessment!.updatedAt),
                    isLast: true,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _windowLabel(DoctorHeartRiskPredictionWindow? window) {
    final start = window?.startDate?.trim() ?? '';
    final end = window?.endDate?.trim() ?? '';
    if (start.isEmpty && end.isEmpty) return '-';
    if (start.isNotEmpty && end.isNotEmpty) return '$start - $end';
    return start.isNotEmpty ? start : end;
  }

  static String _riskLabel(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return 'Risiko Tinggi';
      case 'medium':
        return 'Risiko Sedang';
      case 'low':
        return 'Risiko Rendah';
      default:
        return riskLevel.isEmpty ? 'Belum Diketahui' : riskLevel;
    }
  }

  static Color _riskChipBackground(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return const Color(0xFFFEE2E2);
      case 'medium':
        return const Color(0xFFFFF7ED);
      case 'low':
      default:
        return const Color(0xFFECFDF3);
    }
  }

  static Color _riskChipForeground(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return const Color(0xFFB91C1C);
      case 'medium':
        return const Color(0xFFC2410C);
      case 'low':
      default:
        return const Color(0xFF15803D);
    }
  }

  static String _numLabel(num? value) {
    if (value == null) return '-';
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }
}

class _HeartRiskDetailInfoRow extends StatelessWidget {
  const _HeartRiskDetailInfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _patientFullName(DashboardPatient? patient) {
  if (patient == null) return '';

  final firstName = patient.firstName.trim();
  final lastName = patient.lastName.trim();
  return '$firstName $lastName'.trim();
}

String _formatFilterDate(DateTime? date) {
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

String _formatHistoryDate(DateTime? value) {
  if (value == null) return '-';
  final local = value.toLocal();
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

  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

String _formatDateTime(DateTime? value) {
  if (value == null) return '-';
  final local = value.toLocal();
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
  final day = local.day.toString().padLeft(2, '0');
  final month = months[local.month - 1];
  final year = local.year;
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day $month $year, $hour:$minute';
}
