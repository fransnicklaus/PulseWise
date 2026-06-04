import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/network/network_error_utils.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/core/widgets/no_connection_state.dart';
import 'package:pulsewise/features/doctor/data/datasources/doctor_dashboard_api.dart';
import 'package:pulsewise/features/doctor/data/models/doctor_dashboard_models.dart';
import 'package:pulsewise/features/doctor/data/models/doctor_heart_risk_models.dart';
import 'package:pulsewise/features/doctor/presentation/providers/doctor_dashboard_provider.dart';
import 'package:pulsewise/features/home_dashboard/data/models/dashboard_overview_models.dart';
import 'package:pulsewise/features/home_dashboard/presentation/pages/patient_flutter.dart'
    show PredictionMetricCard, RecommendationItem;
import 'package:pulsewise/features/ml_recommendation/data/models/ml_recommendation_models.dart';

class DoctorPatientDashboardPage extends ConsumerStatefulWidget {
  const DoctorPatientDashboardPage({
    super.key,
    required this.patientId,
    this.initialSummary,
  });

  final String patientId;
  final DoctorDashboardPatientSummaryData? initialSummary;

  @override
  ConsumerState<DoctorPatientDashboardPage> createState() =>
      _DoctorPatientDashboardPageState();
}

class _DoctorDashboardTimePeriodOption {
  const _DoctorDashboardTimePeriodOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

class _DoctorPatientDashboardPageState
    extends ConsumerState<DoctorPatientDashboardPage> {
  static const List<_DoctorDashboardTimePeriodOption> _periodOptions = [
    _DoctorDashboardTimePeriodOption(
      id: 'last_7_days',
      label: '7 Hari Kebelakang',
    ),
    _DoctorDashboardTimePeriodOption(
      id: 'last_14_days',
      label: '14 Hari Kebelakang',
    ),
    _DoctorDashboardTimePeriodOption(
      id: 'last_30_days',
      label: '30 Hari Kebelakang',
    ),
    _DoctorDashboardTimePeriodOption(
      id: 'last_3_months',
      label: '3 Bulan Kebelakang',
    ),
    _DoctorDashboardTimePeriodOption(
      id: 'last_6_months',
      label: '6 Bulan Kebelakang',
    ),
    _DoctorDashboardTimePeriodOption(
      id: 'all',
      label: 'Semua Data',
    ),
  ];

  DoctorDashboardPatientSummaryData? _summary;
  DoctorDashboardPatientVitalsData? _vitals;
  MlRecommendationResponse? _latestRecommendation;
  late _DoctorDashboardTimePeriodOption _selectedPeriod;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isLoadingRecommendation = true;
  String? _error;
  Object? _errorCause;
  String? _recommendationError;
  Object? _recommendationErrorCause;

  @override
  void initState() {
    super.initState();
    _summary = widget.initialSummary;
    _selectedPeriod = _periodOptions.firstWhere(
      (period) => period.id == 'last_30_days',
      orElse: () => _periodOptions.first,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboard(refreshSummary: widget.initialSummary == null);
    });
  }

  bool _isNetworkError(Object? error) {
    return error != null && isNetworkRequestError(error);
  }

  Future<_DoctorRecommendationFetchResult> _loadRecommendationSafely(
    DoctorDashboardApi api,
  ) async {
    try {
      final recommendation =
          await api.fetchLatestPatientMlRecommendation(widget.patientId);
      return _DoctorRecommendationFetchResult(
        recommendation: recommendation,
      );
    } catch (error) {
      return _DoctorRecommendationFetchResult(
        error: error,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _loadDashboard({
    bool refreshSummary = true,
    bool refreshVitals = true,
    _DoctorDashboardTimePeriodOption? period,
    bool refreshRecommendation = true,
  }) async {
    if (!mounted) return;
    final targetPeriod = period ?? _selectedPeriod;
    final hasExistingData = _summary != null && _vitals != null;
    setState(() {
      _selectedPeriod = targetPeriod;
      _isLoading = !hasExistingData;
      _isRefreshing = hasExistingData;
      _error = null;
      _errorCause = null;
      if (refreshRecommendation) {
        _isLoadingRecommendation = true;
        _recommendationError = null;
        _recommendationErrorCause = null;
      }
    });

    try {
      final api = ref.read(doctorDashboardApiProvider);
      final recommendationFuture =
          refreshRecommendation ? _loadRecommendationSafely(api) : null;

      final futures = await Future.wait([
        if (refreshSummary) api.fetchPatientSummary(widget.patientId),
        if (refreshVitals)
          api.fetchPatientVitals(
            widget.patientId,
            timePeriod: targetPeriod.id,
          ),
      ]);

      DoctorDashboardPatientSummaryData? summary = _summary;
      DoctorDashboardPatientVitalsData? vitals = _vitals;
      MlRecommendationResponse? recommendation = _latestRecommendation;
      String? recommendationError = _recommendationError;
      Object? recommendationErrorCause = _recommendationErrorCause;

      var futureIndex = 0;
      if (refreshSummary) {
        summary =
            (futures[futureIndex] as DoctorDashboardPatientSummaryResponse)
                .data;
        futureIndex++;
      }
      if (refreshVitals) {
        vitals =
            (futures[futureIndex] as DoctorDashboardPatientVitalsResponse).data;
      }

      if (summary == null) {
        throw Exception('Ringkasan pasien tidak tersedia.');
      }
      if (vitals == null) {
        throw Exception('Data vital pasien tidak tersedia.');
      }

      if (refreshRecommendation && recommendationFuture != null) {
        final recommendationResult = await recommendationFuture;
        recommendationError = recommendationResult.errorMessage;
        recommendationErrorCause = recommendationResult.error;
        if (recommendationResult.hasResolvedData) {
          recommendation = recommendationResult.recommendation;
        }
      }

      if (!mounted) return;
      setState(() {
        _summary = summary;
        _vitals = vitals;
        _latestRecommendation = recommendation;
        _isLoading = false;
        _isRefreshing = false;
        _isLoadingRecommendation = false;
        _error = null;
        _errorCause = null;
        _recommendationError = recommendationError;
        _recommendationErrorCause = recommendationErrorCause;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _errorCause = error;
        _isLoading = false;
        _isRefreshing = false;
        if (refreshRecommendation) {
          _isLoadingRecommendation = false;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    const monthNames = [
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
    return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }

  String _formatDateTime(String? raw) {
    final parsed = DateTime.tryParse(raw ?? '');
    if (parsed == null) return '-';
    return _formatDate(parsed);
  }

  DashboardLatestVitals? get _latestVitals {
    final summaryLatest = _summary?.latestVitals;
    final seriesLatest = _vitals?.latestVitals;
    if (summaryLatest == null) return seriesLatest;
    if (seriesLatest == null) return summaryLatest;

    return DashboardLatestVitals(
      measuredAt: summaryLatest.measuredAt ?? seriesLatest.measuredAt,
      systolicBp: summaryLatest.systolicBp ?? seriesLatest.systolicBp,
      diastolicBp: summaryLatest.diastolicBp ?? seriesLatest.diastolicBp,
      heartRate: summaryLatest.heartRate ?? seriesLatest.heartRate,
      oxygenSaturation:
          summaryLatest.oxygenSaturation ?? seriesLatest.oxygenSaturation,
      weight: summaryLatest.weight ?? seriesLatest.weight,
      height: summaryLatest.height ?? seriesLatest.height,
      bmi: summaryLatest.bmi ?? seriesLatest.bmi,
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    final vitals = _vitals;
    final hasData = summary != null && vitals != null;
    final hasInitialNetworkFailure =
        _isNetworkError(_errorCause) && !hasData && !_isLoading;
    final hasInitialNonNetworkFailure = _error != null &&
        !_isNetworkError(_errorCause) &&
        !hasData &&
        !_isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: CustomAppBar(
        title: 'Dashboard Pasien',
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      body: SafeArea(
        child: !hasData && _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFE64060)),
              )
            : hasInitialNetworkFailure
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.68,
                        child: NoConnectionState.page(
                          title: 'Dashboard pasien belum bisa dimuat',
                          message:
                              'Kami belum bisa mengambil dashboard pasien karena koneksi internet tidak tersedia atau sedang tidak stabil.',
                          onRetry: () => _loadDashboard(refreshSummary: true),
                        ),
                      ),
                    ],
                  )
                : hasInitialNonNetworkFailure
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 80, 20, 24),
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Color(0xFFE64060),
                            size: 56,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFB91C1C),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _loadDashboard(refreshSummary: true),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFE64060),
                                side:
                                    const BorderSide(color: Color(0xFFE64060)),
                                minimumSize: const Size.fromHeight(52),
                              ),
                              icon: const Icon(Icons.refresh),
                              label: const Text(
                                'Muat Ulang Dashboard',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : !hasData
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 200),
                              Center(
                                child: Text('Data dashboard pasien kosong.'),
                              ),
                            ],
                          )
                        : RefreshIndicator(
                            onRefresh: () =>
                                _loadDashboard(refreshSummary: true),
                            color: const Color(0xFFE64060),
                            child: _DoctorPatientDashboardBody(
                              summary: summary,
                              vitals: vitals,
                              latestVitals: _latestVitals,
                              selectedPeriod: _selectedPeriod,
                              periodOptions: _periodOptions,
                              isRefreshing: _isRefreshing,
                              errorMessage: _error,
                              errorCause: _errorCause,
                              latestRecommendation: _latestRecommendation,
                              isLoadingRecommendation: _isLoadingRecommendation,
                              recommendationError: _recommendationError,
                              recommendationErrorCause:
                                  _recommendationErrorCause,
                              onPeriodChanged: (period) => _loadDashboard(
                                refreshSummary: false,
                                refreshVitals: true,
                                period: period,
                                refreshRecommendation: false,
                              ),
                              onRetry: () => _loadDashboard(
                                refreshSummary: false,
                                refreshVitals: true,
                                refreshRecommendation: false,
                              ),
                              onOpenDiaryHistory: () => context.push(
                                '/doctor/home/patients/${widget.patientId}/diary-history',
                              ),
                              onOpenHeartRiskPrediction: () => context.push(
                                '/doctor/home/patients/${widget.patientId}/heart-risk-model',
                                extra: DoctorHeartRiskEntryData(
                                  patient: summary.patient,
                                  latestVitals: _latestVitals,
                                ),
                              ),
                              onOpenHistory: () => context.push(
                                '/doctor/home/patients/${widget.patientId}/ml-recommendation-history',
                              ),
                              onReloadRecommendation: () => _loadDashboard(
                                refreshSummary: false,
                                refreshVitals: false,
                                refreshRecommendation: true,
                              ),
                              formatDate: _formatDate,
                              formatDateTime: _formatDateTime,
                            ),
                          ),
      ),
    );
  }
}

class _DoctorPatientDashboardBody extends StatelessWidget {
  const _DoctorPatientDashboardBody({
    required this.summary,
    required this.vitals,
    required this.latestVitals,
    required this.selectedPeriod,
    required this.periodOptions,
    required this.isRefreshing,
    required this.errorMessage,
    required this.errorCause,
    required this.latestRecommendation,
    required this.isLoadingRecommendation,
    required this.recommendationError,
    required this.recommendationErrorCause,
    required this.onPeriodChanged,
    required this.onRetry,
    required this.onOpenDiaryHistory,
    required this.onOpenHeartRiskPrediction,
    required this.onOpenHistory,
    required this.onReloadRecommendation,
    required this.formatDate,
    required this.formatDateTime,
  });

  final DoctorDashboardPatientSummaryData summary;
  final DoctorDashboardPatientVitalsData vitals;
  final DashboardLatestVitals? latestVitals;
  final _DoctorDashboardTimePeriodOption selectedPeriod;
  final List<_DoctorDashboardTimePeriodOption> periodOptions;
  final bool isRefreshing;
  final String? errorMessage;
  final Object? errorCause;
  final MlRecommendationResponse? latestRecommendation;
  final bool isLoadingRecommendation;
  final String? recommendationError;
  final Object? recommendationErrorCause;
  final ValueChanged<_DoctorDashboardTimePeriodOption> onPeriodChanged;
  final VoidCallback onRetry;
  final VoidCallback onOpenDiaryHistory;
  final VoidCallback onOpenHeartRiskPrediction;
  final VoidCallback onOpenHistory;
  final VoidCallback onReloadRecommendation;
  final String Function(DateTime? date) formatDate;
  final String Function(String? raw) formatDateTime;

  @override
  Widget build(BuildContext context) {
    final currentErrorCause = errorCause;
    final patient = summary.patient;
    final hrPoints =
        _buildChartPoints(vitals.series.timestamps, vitals.series.heartRate);
    final spo2Points = _buildChartPoints(
      vitals.series.timestamps,
      vitals.series.oxygenSaturation,
    );
    final weightPoints =
        _buildChartPoints(vitals.series.timestamps, vitals.series.weight);
    final bmiPoints =
        _buildChartPoints(vitals.series.timestamps, vitals.series.bmi);
    final bpSeries = _buildBloodPressureSeries(
      vitals.series.timestamps,
      vitals.series.systolicBp,
      vitals.series.diastolicBp,
    );
    final latestHeight =
        latestVitals?.height ?? _lastNonNull(vitals.series.height);

    return DefaultTabController(
      length: 2,
      child: NestedScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _DoctorPatientHeaderCard(
                  patient: patient,
                  latestUpdatedLabel:
                      'Terakhir diperbarui ${formatDateTime(latestVitals?.measuredAt)}',
                  onOpenDiaryHistory: onOpenDiaryHistory,
                  onOpenHeartRiskPrediction: onOpenHeartRiskPrediction,
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                const TabBar(
                  labelColor: Color(0xFFE13D5A),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Color(0xFFE13D5A),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.w300,
                    fontSize: 17,
                  ),
                  tabs: [
                    Tab(text: 'Prediksi'),
                    Tab(text: 'Dashboard Metrik'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          children: [
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: _DoctorPredictionSection(
                patient: patient,
                latestMeasuredAtLabel: formatDateTime(latestVitals?.measuredAt),
                latestRecommendation: latestRecommendation,
                isLoadingRecommendation: isLoadingRecommendation,
                recommendationError: recommendationError,
                recommendationErrorCause: recommendationErrorCause,
                onRetry: onReloadRecommendation,
                onOpenHistory: onOpenHistory,
              ),
            ),
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final fullWidth = constraints.maxWidth;
                  final twoColumns = fullWidth >= 1180;
                  final chartWidth =
                      twoColumns ? (fullWidth - 24) / 2 : fullWidth;
                  final summaryCardWidth =
                      fullWidth >= 640 ? (fullWidth - 24) / 2 : fullWidth;
                  final latestMetricWidth =
                      fullWidth >= 640 ? (fullWidth - 14) / 2 : fullWidth;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
                        child: DropdownButtonFormField<String>(
                          dropdownColor: Colors.white,
                          value: selectedPeriod.id,
                          items: periodOptions
                              .map(
                                (period) => DropdownMenuItem<String>(
                                  value: period.id,
                                  child: Text(
                                    period.label,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            final period = periodOptions.where((item) {
                              return item.id == value;
                            }).firstOrNull;
                            if (period == null) return;
                            onPeriodChanged(period);
                          },
                          decoration: InputDecoration(
                            labelText: 'Periode',
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFE13D5A),
                                width: 2,
                              ),
                            ),
                            labelStyle: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (isRefreshing)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(24, 12, 24, 0),
                          child: LinearProgressIndicator(
                            color: Color(0xFFE13D5A),
                          ),
                        ),
                      if (errorMessage != null &&
                          currentErrorCause != null &&
                          isNetworkRequestError(currentErrorCause))
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                          child: NoConnectionState.compact(
                            title: 'Koneksi terputus',
                            message:
                                'Dashboard terakhir tetap ditampilkan. Sambungkan internet lalu coba lagi.',
                            onRetry: onRetry,
                          ),
                        )
                      else if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                          child: _InlineErrorBanner(
                            message: 'Gagal memuat data periode terbaru.',
                            onRetry: onRetry,
                          ),
                        ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: summaryCardWidth,
                            child: _DoctorMiniStatCard(
                              title: 'Latest BMI',
                              value: latestVitals?.bmi == null
                                  ? '-'
                                  : latestVitals!.bmi!.toStringAsFixed(1),
                              background: Colors.white,
                              foreground: const Color(0xFF1A202C),
                            ),
                          ),
                          SizedBox(
                            width: summaryCardWidth,
                            child: _DoctorMiniStatCard(
                              title: 'Height',
                              value: latestHeight == null
                                  ? '-'
                                  : '${latestHeight.toStringAsFixed(0)} cm',
                              background: const Color(0xFFE13D5A),
                              foreground: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          SizedBox(
                            width: latestMetricWidth,
                            child: _LatestMetricCard(
                              title: 'Tekanan Darah',
                              value: latestVitals?.systolicBp != null &&
                                      latestVitals?.diastolicBp != null
                                  ? '${latestVitals!.systolicBp!.toStringAsFixed(0)}/${latestVitals!.diastolicBp!.toStringAsFixed(0)}'
                                  : '-/-',
                              unit: 'mmHg',
                              accent: _bloodPressureColor(
                                latestVitals?.systolicBp?.toDouble(),
                                latestVitals?.diastolicBp?.toDouble(),
                                summary.thresholds,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: latestMetricWidth,
                            child: _LatestMetricCard(
                              title: 'Detak Jantung',
                              value: _numDisplay(
                                latestVitals?.heartRate,
                                fractionDigits: 0,
                              ),
                              unit: 'bpm',
                              accent: _heartRateColor(
                                latestVitals?.heartRate?.toDouble(),
                                summary.thresholds,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: latestMetricWidth,
                            child: _LatestMetricCard(
                              title: 'SpO2',
                              value: _numDisplay(
                                latestVitals?.oxygenSaturation,
                                fractionDigits: 0,
                              ),
                              unit: '%',
                              accent: _spo2Color(
                                latestVitals?.oxygenSaturation?.toDouble(),
                                summary.thresholds,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: latestMetricWidth,
                            child: _LatestMetricCard(
                              title: 'BMI',
                              value: _numDisplay(latestVitals?.bmi),
                              unit: '',
                              accent: const Color(0xFF7C3AED),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        children: [
                          SizedBox(
                            width: chartWidth,
                            child: _MetricChartCard(
                              title: 'Detak Jantung',
                              subtitle:
                                  'Normal ${summary.thresholds.hrNormalMin}-${summary.thresholds.hrNormalMax} bpm',
                              chart: hrPoints.isEmpty
                                  ? const _EmptyChartPlaceholder(
                                      label: 'Belum ada data detak jantung',
                                    )
                                  : _SingleMetricLineChart(
                                      points: hrPoints,
                                      lineColor: const Color(0xFF2563EB),
                                      minY: math.min(
                                        50,
                                        summary.thresholds.hrNormalMin
                                                .toDouble() -
                                            15,
                                      ),
                                      maxY: math.max(
                                        120,
                                        summary.thresholds.hrNormalMax
                                                .toDouble() +
                                            15,
                                      ),
                                      horizontalLines: [
                                        summary.thresholds.hrNormalMin
                                            .toDouble(),
                                        summary.thresholds.hrNormalMax
                                            .toDouble(),
                                      ],
                                    ),
                            ),
                          ),
                          SizedBox(
                            width: chartWidth,
                            child: _MetricChartCard(
                              title: 'Tekanan Darah',
                              subtitle:
                                  'Sistolik dan diastolik sesuai periode terpilih',
                              chart: bpSeries.systolic.isEmpty ||
                                      bpSeries.diastolic.isEmpty
                                  ? const _EmptyChartPlaceholder(
                                      label: 'Belum ada data tekanan darah',
                                    )
                                  : _BloodPressureLineChart(
                                      systolic: bpSeries.systolic,
                                      diastolic: bpSeries.diastolic,
                                      horizontalLines: [
                                        summary.thresholds.bpNormalSystolicMax
                                            .toDouble(),
                                        summary.thresholds.bpStage1SystolicMin
                                            .toDouble(),
                                        summary.thresholds.bpStage2SystolicMin
                                            .toDouble(),
                                      ],
                                    ),
                            ),
                          ),
                          SizedBox(
                            width: chartWidth,
                            child: _MetricChartCard(
                              title: 'Saturasi Oksigen',
                              subtitle:
                                  'Waspada < ${summary.thresholds.spo2CautionThreshold}, kritis < ${summary.thresholds.spo2CriticalThreshold}',
                              chart: spo2Points.isEmpty
                                  ? const _EmptyChartPlaceholder(
                                      label: 'Belum ada data saturasi oksigen',
                                    )
                                  : _SingleMetricLineChart(
                                      points: spo2Points,
                                      lineColor: const Color(0xFF0EA5E9),
                                      minY: 85,
                                      maxY: 100,
                                      horizontalLines: [
                                        summary.thresholds.spo2CriticalThreshold
                                            .toDouble(),
                                        summary.thresholds.spo2CautionThreshold
                                            .toDouble(),
                                      ],
                                    ),
                            ),
                          ),
                          SizedBox(
                            width: chartWidth,
                            child: _MetricChartCard(
                              title: 'Berat Badan',
                              subtitle:
                                  'Perubahan berat badan sesuai periode terpilih',
                              chart: weightPoints.isEmpty
                                  ? const _EmptyChartPlaceholder(
                                      label: 'Belum ada data berat badan',
                                    )
                                  : _SingleMetricLineChart(
                                      points: weightPoints,
                                      lineColor: const Color(0xFF14B8A6),
                                      minY: _dynamicMin(weightPoints),
                                      maxY: _dynamicMax(weightPoints),
                                    ),
                            ),
                          ),
                          SizedBox(
                            width: chartWidth,
                            child: _MetricChartCard(
                              title: 'BMI',
                              subtitle:
                                  'Body mass index sesuai periode terpilih',
                              chart: bmiPoints.isEmpty
                                  ? const _EmptyChartPlaceholder(
                                      label: 'Belum ada data BMI',
                                    )
                                  : _SingleMetricLineChart(
                                      points: bmiPoints,
                                      lineColor: const Color(0xFF7C3AED),
                                      minY: _dynamicMin(bmiPoints),
                                      maxY: _dynamicMax(bmiPoints),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  _StickyTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFFFAFAFA),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.bottomCenter,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        child: tabBar,
      ),
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return oldDelegate.tabBar != tabBar;
  }
}

class _DoctorPatientHeaderCard extends StatelessWidget {
  const _DoctorPatientHeaderCard({
    required this.patient,
    required this.latestUpdatedLabel,
    required this.onOpenDiaryHistory,
    required this.onOpenHeartRiskPrediction,
  });

  final DashboardPatient patient;
  final String latestUpdatedLabel;
  final VoidCallback onOpenDiaryHistory;
  final VoidCallback onOpenHeartRiskPrediction;

  @override
  Widget build(BuildContext context) {
    final sexRaw = patient.sex?.trim();
    final properGender = (sexRaw == null || sexRaw.isEmpty)
        ? '-'
        : '${sexRaw[0].toUpperCase()}${sexRaw.substring(1).toLowerCase()}';
    final properName = patient.fullName
        .split(' ')
        .map((word) => word.isEmpty
            ? ''
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ')
        .trim();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DoctorPatientAvatar(
                avatarUrl: patient.avatarPhoto,
                initials: patient.initials,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      properName.isEmpty ? 'Pasien Tanpa Nama' : properName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A202C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _DoctorHeaderDetailItem(
                          label: 'Sex',
                          value: properGender,
                        ),
                        _DoctorHeaderDetailItem(
                          label: 'Date of Birth',
                          value: patient.dateOfBirth ?? '-',
                        ),
                        _DoctorHeaderDetailItem(
                          label: 'Age',
                          value: patient.age == null
                              ? '-'
                              : '${patient.age} Tahun',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              if (patient.email?.trim().isNotEmpty == true)
                _DoctorInfoPill(
                  icon: Icons.mail_outline_rounded,
                  label: patient.email!,
                ),
              if (patient.phone?.trim().isNotEmpty == true)
                _DoctorInfoPill(
                  icon: Icons.call_outlined,
                  label: patient.phone!,
                ),
              _DoctorInfoPill(
                icon: Icons.schedule_rounded,
                label: latestUpdatedLabel,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenDiaryHistory,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE13D5A),
                side: const BorderSide(color: Color(0xFFF3A5B6)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.menu_book_rounded, size: 22),
              label: const Text(
                'Lihat Riwayat Diari',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onOpenHeartRiskPrediction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE13D5A),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.monitor_heart_rounded, size: 22),
              label: const Text(
                'Lihat Prediksi Heart Risk',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorPatientAvatar extends StatelessWidget {
  const _DoctorPatientAvatar({
    required this.avatarUrl,
    required this.initials,
  });

  final String? avatarUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFE64060), Color(0xFFFF7A93)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE64060).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: hasAvatar
                  ? Image.network(
                      avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildFallbackAvatar(),
                    )
                  : _buildFallbackAvatar(),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFE64060),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackAvatar() {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Color(0xFFE64060),
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DoctorHeaderDetailItem extends StatelessWidget {
  const _DoctorHeaderDetailItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(color: Color(0xFF1A202C)),
          ),
        ],
      ),
    );
  }
}

class _DoctorInfoPill extends StatelessWidget {
  const _DoctorInfoPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFE13D5A)),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF475569),
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

class _DoctorPredictionSection extends StatelessWidget {
  const _DoctorPredictionSection({
    required this.patient,
    required this.latestMeasuredAtLabel,
    required this.latestRecommendation,
    required this.isLoadingRecommendation,
    required this.recommendationError,
    required this.recommendationErrorCause,
    required this.onRetry,
    required this.onOpenHistory,
  });

  final DashboardPatient patient;
  final String latestMeasuredAtLabel;
  final MlRecommendationResponse? latestRecommendation;
  final bool isLoadingRecommendation;
  final String? recommendationError;
  final Object? recommendationErrorCause;
  final VoidCallback onRetry;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final currentRecommendationErrorCause = recommendationErrorCause;
    final hasRecommendationData = latestRecommendation != null;
    final hasNetworkError = currentRecommendationErrorCause != null &&
        isNetworkRequestError(currentRecommendationErrorCause);

    if (isLoadingRecommendation && !hasRecommendationData) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFFE13D5A)),
              SizedBox(height: 16),
              Text(
                'Memuat hasil prediksi terbaru...',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (recommendationError != null && !hasRecommendationData) {
      if (hasNetworkError) {
        return NoConnectionState.card(
          title: 'Prediksi terbaru belum bisa dimuat',
          message:
              'Kami belum bisa mengambil prediksi terbaru karena koneksi internet tidak tersedia atau sedang tidak stabil.',
          onRetry: onRetry,
        );
      }

      return Column(
        children: [
          _InlineErrorBanner(
            message: recommendationError!,
            onRetry: onRetry,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenHistory,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE13D5A),
                side: const BorderSide(color: Color(0xFFE13D5A)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.history_rounded, size: 20),
              label: const Text(
                'Cek History',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final upstreamBody = latestRecommendation?.data?.upstream?.body;
    if (latestRecommendation != null && upstreamBody != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoadingRecommendation) ...[
            const ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(999)),
              child: LinearProgressIndicator(
                minHeight: 4,
                color: Color(0xFFE13D5A),
                backgroundColor: Color(0xFFFCE7EF),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (recommendationError != null && hasNetworkError) ...[
            NoConnectionState.compact(
              title: 'Prediksi gagal diperbarui',
              message:
                  'Prediksi terakhir tetap ditampilkan. Sambungkan internet lalu coba lagi.',
              onRetry: onRetry,
            ),
            const SizedBox(height: 16),
          ] else if (recommendationError != null) ...[
            _InlineErrorBanner(
              message: recommendationError!,
              onRetry: onRetry,
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE13D5A),
                    side: const BorderSide(color: Color(0xFFE13D5A)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.refresh, size: 22),
                  label: const Text(
                    'Muat Ulang',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenHistory,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE13D5A),
                    side: const BorderSide(color: Color(0xFFE13D5A)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.history, size: 22),
                  label: const Text(
                    'Cek History',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: PredictionMetricCard(
              title: 'Prediksi',
              icon: Icons.insights_rounded,
              iconColor: const Color(0xFFE13D5A),
              description:
                  'Dihasilkan pada: ${_doctorGeneratedDateStr(latestRecommendation)}',
              score: _doctorProbability(latestRecommendation),
            ),
          ),
          const SizedBox(height: 24),
          _DoctorRecommendationSection(mlRec: latestRecommendation),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEF2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Color(0xFFE13D5A),
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Prediksi terbaru belum tersedia',
                style: TextStyle(
                  color: Color(0xFF1A202C),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Belum ada hasil rekomendasi ML terbaru untuk pasien ini. Dashboard Metrik di sebelahnya tetap menampilkan ringkasan vital pasien dari hasil scan QR.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _DoctorInfoPill(
                    icon: Icons.person_outline_rounded,
                    label: patient.fullName.isEmpty
                        ? 'Pasien dipilih'
                        : patient.fullName,
                  ),
                  _DoctorInfoPill(
                    icon: Icons.schedule_rounded,
                    label: 'Update terakhir $latestMeasuredAtLabel',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onOpenHistory,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE13D5A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.history_rounded, size: 20),
                  label: const Text(
                    'Cek History',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE13D5A),
                    side: const BorderSide(color: Color(0xFFE13D5A)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text(
                    'Muat Ulang Prediksi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

class _DoctorRecommendationFetchResult {
  const _DoctorRecommendationFetchResult({
    this.recommendation,
    this.error,
    this.errorMessage,
  });

  final MlRecommendationResponse? recommendation;
  final Object? error;
  final String? errorMessage;

  bool get hasResolvedData => error == null;
}

class _DoctorRecommendationSection extends StatelessWidget {
  const _DoctorRecommendationSection({required this.mlRec});

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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.recommend,
                  color: Color(0xFFE13D5A),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Rekomendasi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A202C),
                ),
              ),
            ],
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
      ),
    );
  }
}

class _DoctorMiniStatCard extends StatelessWidget {
  const _DoctorMiniStatCard({
    required this.title,
    required this.value,
    required this.background,
    required this.foreground,
  });

  final String title;
  final String value;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
        border: background == Colors.white
            ? Border.all(color: const Color(0xFFE2E8F0))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: foreground
                  .withOpacity(foreground == Colors.white ? 0.88 : 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: foreground,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestMetricCard extends StatelessWidget {
  const _LatestMetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.accent,
  });

  final String title;
  final String value;
  final String unit;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 156,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                color: accent,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              unit.isEmpty ? 'latest value' : unit,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChartCard extends StatelessWidget {
  const _MetricChartCard({
    required this.title,
    required this.subtitle,
    required this.chart,
  });

  final String title;
  final String subtitle;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(height: 220, child: chart),
        ],
      ),
    );
  }
}

class _SingleMetricLineChart extends StatelessWidget {
  const _SingleMetricLineChart({
    required this.points,
    required this.lineColor,
    required this.minY,
    required this.maxY,
    this.horizontalLines = const [],
  });

  final List<_ChartPoint> points;
  final Color lineColor;
  final double minY;
  final double maxY;
  final List<double> horizontalLines;

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: math.max(points.length - 1, 0).toDouble(),
        minY: minY,
        maxY: maxY,
        lineTouchData: const LineTouchData(enabled: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _gridInterval(minY, maxY),
          getDrawingHorizontalLine: (_) => const FlLine(
            color: Color(0xFFF1F5F9),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: horizontalLines
              .map(
                (value) => HorizontalLine(
                  y: value,
                  color: const Color(0xFFE2E8F0),
                  strokeWidth: 1,
                  dashArray: const [6, 6],
                ),
              )
              .toList(),
        ),
        titlesData: _buildTitles(points, minY, maxY),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var index = 0; index < points.length; index++)
                FlSpot(index.toDouble(), points[index].value),
            ],
            isCurved: true,
            curveSmoothness: 0.25,
            color: lineColor,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3.8,
                  color: lineColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}

class _BloodPressureLineChart extends StatelessWidget {
  const _BloodPressureLineChart({
    required this.systolic,
    required this.diastolic,
    this.horizontalLines = const [],
  });

  final List<_ChartPoint> systolic;
  final List<_ChartPoint> diastolic;
  final List<double> horizontalLines;

  @override
  Widget build(BuildContext context) {
    final merged = [...systolic, ...diastolic];
    final minY = _dynamicMin(merged);
    final maxY = _dynamicMax(merged);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: math
            .max(
              math.max(systolic.length - 1, 0),
              math.max(diastolic.length - 1, 0),
            )
            .toDouble(),
        minY: minY,
        maxY: maxY,
        lineTouchData: const LineTouchData(enabled: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _gridInterval(minY, maxY),
          getDrawingHorizontalLine: (_) => const FlLine(
            color: Color(0xFFF1F5F9),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: horizontalLines
              .map(
                (value) => HorizontalLine(
                  y: value,
                  color: const Color(0xFFE2E8F0),
                  strokeWidth: 1,
                  dashArray: const [6, 6],
                ),
              )
              .toList(),
        ),
        titlesData: _buildTitles(systolic, minY, maxY),
        lineBarsData: [
          _buildLineBar(systolic, const Color(0xFFE64060)),
          _buildLineBar(diastolic, const Color(0xFF2563EB)),
        ],
      ),
    );
  }

  LineChartBarData _buildLineBar(List<_ChartPoint> points, Color color) {
    return LineChartBarData(
      spots: [
        for (var index = 0; index < points.length; index++)
          FlSpot(index.toDouble(), points[index].value),
      ],
      isCurved: true,
      curveSmoothness: 0.2,
      color: color,
      barWidth: 3,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 3.6,
            color: color,
            strokeWidth: 2,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(show: false),
    );
  }
}

class _EmptyChartPlaceholder extends StatelessWidget {
  const _EmptyChartPlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ChartPoint {
  const _ChartPoint({
    required this.timestamp,
    required this.value,
  });

  final DateTime timestamp;
  final double value;
}

class _BloodPressureSeries {
  const _BloodPressureSeries({
    required this.systolic,
    required this.diastolic,
  });

  final List<_ChartPoint> systolic;
  final List<_ChartPoint> diastolic;
}

FlTitlesData _buildTitles(List<_ChartPoint> points, double minY, double maxY) {
  return FlTitlesData(
    topTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    rightTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 38,
        interval: _gridInterval(minY, maxY),
        getTitlesWidget: (value, meta) {
          return SideTitleWidget(
            axisSide: meta.axisSide,
            space: 8,
            child: Text(
              value.toStringAsFixed(0),
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
              ),
            ),
          );
        },
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 30,
        interval: _xInterval(points.length),
        getTitlesWidget: (value, meta) {
          final index = value.round();
          if (index < 0 || index >= points.length) {
            return const SizedBox.shrink();
          }
          final point = points[index];
          return SideTitleWidget(
            axisSide: meta.axisSide,
            space: 8,
            child: Text(
              _shortDate(point.timestamp),
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
              ),
            ),
          );
        },
      ),
    ),
  );
}

List<_ChartPoint> _buildChartPoints(
  List<String> timestamps,
  List<num?> values,
) {
  final points = <_ChartPoint>[];
  final length = math.min(timestamps.length, values.length);

  for (var index = 0; index < length; index++) {
    final timestamp = DateTime.tryParse(timestamps[index]);
    final value = values[index];
    if (timestamp == null || value == null) continue;
    points.add(_ChartPoint(timestamp: timestamp, value: value.toDouble()));
  }

  return points;
}

_BloodPressureSeries _buildBloodPressureSeries(
  List<String> timestamps,
  List<num?> systolic,
  List<num?> diastolic,
) {
  final systolicPoints = <_ChartPoint>[];
  final diastolicPoints = <_ChartPoint>[];
  final length = math.min(
    timestamps.length,
    math.min(systolic.length, diastolic.length),
  );

  for (var index = 0; index < length; index++) {
    final timestamp = DateTime.tryParse(timestamps[index]);
    if (timestamp == null) continue;

    final systolicValue = systolic[index];
    final diastolicValue = diastolic[index];

    if (systolicValue != null) {
      systolicPoints.add(
        _ChartPoint(timestamp: timestamp, value: systolicValue.toDouble()),
      );
    }
    if (diastolicValue != null) {
      diastolicPoints.add(
        _ChartPoint(timestamp: timestamp, value: diastolicValue.toDouble()),
      );
    }
  }

  return _BloodPressureSeries(
    systolic: systolicPoints,
    diastolic: diastolicPoints,
  );
}

String _shortDate(DateTime value) {
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

  return '${value.day} ${months[value.month - 1]}';
}

double _dynamicMin(List<_ChartPoint> points) {
  if (points.isEmpty) return 0;
  final minValue = points.map((point) => point.value).reduce(math.min);
  return math.max(0, minValue - 5).toDouble();
}

double _dynamicMax(List<_ChartPoint> points) {
  if (points.isEmpty) return 100;
  final maxValue = points.map((point) => point.value).reduce(math.max);
  return maxValue + 5;
}

double _gridInterval(double minY, double maxY) {
  final range = (maxY - minY).abs();
  if (range <= 10) return 2;
  if (range <= 30) return 5;
  if (range <= 80) return 10;
  return 20;
}

double _xInterval(int length) {
  if (length <= 4) return 1;
  if (length <= 8) return 2;
  if (length <= 16) return 3;
  return 4;
}

String _numDisplay(num? value, {int fractionDigits = 1}) {
  if (value == null) return '-';
  return value.toStringAsFixed(fractionDigits);
}

double _doctorProbability(MlRecommendationResponse? prediction) {
  final recResult = prediction?.data?.upstream?.body?.recommendationResult;
  if (recResult == null) return 0;
  return recResult.currentRisk.clamp(0.0, 100.0);
}

String _doctorGeneratedDateStr(MlRecommendationResponse? prediction) {
  final generatedAt = prediction?.data?.generatedAt;
  if (generatedAt != null && generatedAt.isNotEmpty) {
    try {
      final date = DateTime.parse(generatedAt).toLocal();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$day/$month/$year $hour:$minute WIB';
    } catch (_) {}
  }
  return 'Hari Ini';
}

num? _lastNonNull(List<num?> values) {
  for (var index = values.length - 1; index >= 0; index--) {
    final value = values[index];
    if (value != null) return value;
  }
  return null;
}

Color _heartRateColor(
  double? value,
  DoctorDashboardThresholds thresholds,
) {
  if (value == null) return const Color(0xFF0F172A);
  if (value < thresholds.hrNormalMin || value > thresholds.hrNormalMax) {
    return const Color(0xFFE64060);
  }
  return const Color(0xFF2563EB);
}

Color _spo2Color(
  double? value,
  DoctorDashboardThresholds thresholds,
) {
  if (value == null) return const Color(0xFF0F172A);
  if (value < thresholds.spo2CriticalThreshold) {
    return const Color(0xFFDC2626);
  }
  if (value < thresholds.spo2CautionThreshold) {
    return const Color(0xFFF59E0B);
  }
  return const Color(0xFF0EA5E9);
}

Color _bloodPressureColor(
  double? systolic,
  double? diastolic,
  DoctorDashboardThresholds thresholds,
) {
  if (systolic == null || diastolic == null) return const Color(0xFF0F172A);
  if (systolic >= thresholds.bpStage2SystolicMin ||
      diastolic >= thresholds.bpStage2DiastolicMin) {
    return const Color(0xFFDC2626);
  }
  if ((systolic >= thresholds.bpStage1SystolicMin &&
          systolic <= thresholds.bpStage1SystolicMax) ||
      (diastolic >= thresholds.bpStage1DiastolicMin &&
          diastolic <= thresholds.bpStage1DiastolicMax)) {
    return const Color(0xFFF97316);
  }
  if (systolic >= thresholds.bpElevatedSystolicMin &&
      systolic <= thresholds.bpElevatedSystolicMax &&
      diastolic <= thresholds.bpElevatedDiastolicMax) {
    return const Color(0xFFFACC15);
  }
  return const Color(0xFF0F172A);
}

extension on DashboardPatient {
  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final words = fullName
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .toList();

    if (words.isEmpty) return 'PW';
    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }

    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}
