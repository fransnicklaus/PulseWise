import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/data/ml_readiness_mapping.dart';
import 'package:pulsewise/core/network/network_error_utils.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/core/widgets/no_connection_state.dart';
import 'package:pulsewise/features/dashboard_shell/presentation/providers/dashboard_provider.dart';
import 'package:pulsewise/features/diary/data/models/diary_models.dart';
import 'package:pulsewise/features/diary/presentation/providers/current_diary_provider.dart';
import 'package:pulsewise/features/home_dashboard/presentation/providers/dashboard_overview_provider.dart';
import 'package:pulsewise/features/medication/data/models/medication_models.dart';
import 'package:pulsewise/features/medication/presentation/providers/medication_calendar_provider.dart';
import 'package:pulsewise/features/profile/presentation/providers/profile_provider.dart';
import 'package:pulsewise/features/reports/presentation/pages/report_generator_flutter.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class PatientDashboardPage extends ConsumerStatefulWidget {
  const PatientDashboardPage({
    super.key,
    this.data,
    this.searchResults = const [],
    this.logoUrl,
    this.onSearchChanged,
    this.onPatientSelected,
    this.onTimePeriodChanged,
    this.onLogout,
    this.reportRepository,
    this.onPrintReport,
  });

  final PatientDashboardData? data;
  final List<PatientSearchResult> searchResults;
  final String? logoUrl;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<PatientSearchResult>? onPatientSelected;
  final ValueChanged<TimePeriodOption?>? onTimePeriodChanged;
  final VoidCallback? onLogout;
  final PatientReportRepository? reportRepository;
  final VoidCallback? onPrintReport;

  @override
  ConsumerState<PatientDashboardPage> createState() =>
      _PatientDashboardPageState();
}

class _PatientDashboardPageState extends ConsumerState<PatientDashboardPage> {
  late final TextEditingController _searchController;
  late TimePeriodOption? _selectedPeriod;
  PatientDashboardData? _dashboardData;
  bool _isLoadingDashboard = true;
  String? _dashboardError;
  Object? _dashboardErrorCause;

  static const List<TimePeriodOption> _periodOptions = [
    TimePeriodOption(id: 'last_7_days', label: '7 Hari Kebelakang'),
    TimePeriodOption(id: 'last_14_days', label: '14 Hari Kebelakang'),
    TimePeriodOption(id: 'last_30_days', label: '30 Hari Kebelakang'),
    TimePeriodOption(id: 'last_3_months', label: '3 Bulan Kebelakang'),
    TimePeriodOption(id: 'last_6_months', label: '6 Bulan Kebelakang'),
    TimePeriodOption(id: 'all', label: 'Semua Data'),
  ];

  final List<String> _missingFields = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _dashboardData = widget.data;
    _selectedPeriod = widget.data?.selectedPeriod ??
        _periodOptions.firstWhere(
          (period) => period.id == 'last_30_days',
          orElse: () => _periodOptions.first,
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
      ref.read(currentDiaryProvider.notifier).ensureCurrentDiaryLoaded();
    });
  }

  Future<void> _loadDashboardData({TimePeriodOption? period}) async {
    if (!mounted) return;

    final selectedPeriod = period ?? _selectedPeriod ?? _periodOptions[1];
    setState(() {
      _selectedPeriod = selectedPeriod;
      _isLoadingDashboard = true;
      _dashboardError = null;
      _dashboardErrorCause = null;
    });

    try {
      final api = ref.read(dashboardOverviewApiProvider);
      final vitals = await api.fetchDashboardVitals(selectedPeriod.id);
      String? authMeEmail;
      String? authMeAvatarUrl;
      try {
        final authMe = await ref.read(authMeProvider.future);
        authMeEmail = authMe.email;
        authMeAvatarUrl = authMe.avatarPhoto;
      } catch (_) {
        authMeEmail = null;
        authMeAvatarUrl = null;
      }

      final dashboardData = vitals.data;
      if (dashboardData == null) {
        throw Exception('Data ringkasan metrik belum tersedia.');
      }

      final patient = dashboardData.patient;

      final mappedData = PatientDashboardData(
        patient: PatientProfile(
          id: patient.patientId,
          firstName: patient.firstName,
          lastName: patient.lastName,
          sex: _normalizeNullable(patient.sex),
          dateOfBirth: _normalizeNullable(patient.dateOfBirth),
          phone: _normalizeNullable(patient.phone),
          email: _normalizeNullable(patient.email) ?? authMeEmail,
        ),
        periods: _periodOptions,
        selectedPeriod: selectedPeriod,
        avatarUrl: authMeAvatarUrl,
        heartRatePoints: _buildChartPoints(
          dashboardData.series.timestamps,
          dashboardData.series.heartRate,
        ),
        bloodPressurePoints: _buildBloodPressurePoints(
          dashboardData.series.timestamps,
          dashboardData.series.systolicBp,
          dashboardData.series.diastolicBp,
        ),
        spo2Points: _buildChartPoints(
          dashboardData.series.timestamps,
          dashboardData.series.oxygenSaturation,
        ),
        weightPoints: _buildChartPoints(
          dashboardData.series.timestamps,
          dashboardData.series.weight,
        ),
        bmiPoints: _buildChartPoints(
          dashboardData.series.timestamps,
          dashboardData.series.bmi,
        ),
        latestHeightCm: dashboardData.latestVitals?.height?.toDouble() ??
            (_lastNonNull(dashboardData.series.height) ?? 0).toDouble(),
        heartRateThreshold: const HeartRateThreshold(
          normalMin: 60,
          normalMax: 100,
        ),
        bloodPressureThreshold: const BloodPressureThreshold(
          normalSystolicMax: 120,
          normalDiastolicMax: 80,
          elevatedSystolicMin: 120,
          elevatedSystolicMax: 129,
          elevatedDiastolicMax: 80,
          stage1SystolicMin: 130,
          stage1SystolicMax: 139,
          stage1DiastolicMin: 80,
          stage1DiastolicMax: 89,
          stage2SystolicMin: 140,
          stage2DiastolicMin: 90,
        ),
        spo2Threshold: const Spo2Threshold(
          criticalThreshold: 90,
          cautionThreshold: 95,
        ),
        weightThreshold: const WeightThreshold(
          dailyIncreaseCriticalKg: 2,
        ),
      );

      if (!mounted) return;
      setState(() {
        _dashboardData = mappedData;
        _isLoadingDashboard = false;
        _dashboardError = null;
        _dashboardErrorCause = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dashboardError = e.toString().replaceFirst('Exception: ', '');
        _dashboardErrorCause = e;
        _isLoadingDashboard = false;
      });
    }
  }

  bool _isNetworkError(Object? error) {
    return error != null && isNetworkRequestError(error);
  }

  bool get _showMetricsOfflinePage {
    return _isNetworkError(_dashboardErrorCause) &&
        _dashboardData == null &&
        !_isLoadingDashboard;
  }

  bool get _showMetricsOfflineBanner {
    return _isNetworkError(_dashboardErrorCause) && _dashboardData != null;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MlReadinessGroup> get _readinessGroups => const [];

  Future<void> _handleReadinessGroupAction(MlReadinessGroup group) async {}

  IconData _readinessGroupIcon(MlReadinessGroupType type) {
    return Icons.info_outline_rounded;
  }

  Color _readinessGroupAccent(MlReadinessGroupType type) {
    return const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    final currentDiaryState = ref.watch(currentDiaryProvider);
    final routineInsightsQuery = _routineInsightsQuery();
    final routineAdherenceAsync =
        ref.watch(medicationCalendarRangeProvider(routineInsightsQuery));
    final data = _dashboardData ??
        _emptyDashboardData(_selectedPeriod ?? _periodOptions[1]);
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final sidebar = _DashboardSidebar(
      data: data,
      selectedPeriod: _selectedPeriod,
      onPeriodChanged: (period) {
        if (period == null) return;
        _loadDashboardData(period: period);
        widget.onTimePeriodChanged?.call(period);
      },
      onLogout: widget.onLogout,
      logoUrl: widget.logoUrl,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: CustomAppBar(
        title: 'Dasbor Insight',
        showBackButton: true,
        onBackPressed: () => context.pop(),
      ),
      // drawer: isDesktop
      //     ? null
      //     : Drawer(
      //         width: 320,
      //         child: SafeArea(child: sidebar),
      //       ),
      body: SafeArea(
        child: Row(
          children: [
            if (isDesktop) SizedBox(width: 320, child: sidebar),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final fullWidth = constraints.maxWidth;
                  final twoColumns = fullWidth >= 1180;
                  final chartWidth =
                      twoColumns ? (fullWidth - 24) / 2 : fullWidth;

                  return DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        Expanded(
                          child: NestedScrollView(
                            headerSliverBuilder: (context, innerBoxIsScrolled) {
                              return [
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: _PatientHeaderCard(
                                      patient: data.patient,
                                      avatarUrl: data.avatarUrl,
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
                                          fontSize: 17),
                                      unselectedLabelStyle: TextStyle(
                                          fontWeight: FontWeight.w300,
                                          fontSize: 17),
                                      tabs: [
                                        Tab(text: 'Ringkasan'),
                                        Tab(text: 'Grafik Metrik'),
                                      ],
                                    ),
                                  ),
                                ),
                              ];
                            },
                            body: TabBarView(
                              children: [
                                SingleChildScrollView(
                                  padding: const EdgeInsets.all(24),
                                  child: _buildWellnessInsightsTab(
                                    data,
                                    fullWidth,
                                    currentDiaryState,
                                    routineAdherenceAsync,
                                  ),
                                ),
                                // Tab 2: Dashboard charts and cards
                                SingleChildScrollView(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            0, 16, 0, 16),
                                        child: DropdownButtonFormField<String>(
                                          dropdownColor: Colors.white,
                                          value: _selectedPeriod?.id,
                                          items: data.periods
                                              .map(
                                                (period) =>
                                                    DropdownMenuItem<String>(
                                                  value: period.id,
                                                  child: Text(
                                                    period.label,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (value) {
                                            final period = data.periods
                                                .where((it) => it.id == value)
                                                .firstOrNull;
                                            if (period == null) return;
                                            _loadDashboardData(period: period);
                                          },
                                          decoration: InputDecoration(
                                            labelText: 'Periode',
                                            filled: true,
                                            fillColor: Colors.white,
                                            // border: OutlineInputBorder(
                                            //   borderRadius:
                                            //       BorderRadius.circular(16),
                                            //   borderSide: BorderSide.none,
                                            // ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              borderSide: const BorderSide(
                                                color: Color(
                                                    0xFFE2E8F0), // Subtle border color
                                                width: 1.5,
                                              ),
                                            ),
                                            // 2. Define the border when the user taps/focuses on it
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              borderSide: const BorderSide(
                                                color: Color(
                                                    0xFFE13D5A), // Blue border when focused
                                                width: 2.0,
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
                                      if (_isLoadingDashboard &&
                                          _dashboardData != null)
                                        const Padding(
                                          padding: EdgeInsets.fromLTRB(
                                              24, 12, 24, 0),
                                          child: LinearProgressIndicator(
                                            color: Color(0xFFE13D5A),
                                          ),
                                        ),
                                      if (_isLoadingDashboard &&
                                          _dashboardData == null)
                                        const Padding(
                                          padding:
                                              EdgeInsets.fromLTRB(0, 32, 0, 0),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              color: Color(0xFFE13D5A),
                                            ),
                                          ),
                                        ),
                                      if (_showMetricsOfflineBanner)
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              24, 12, 24, 0),
                                          child: NoConnectionState.compact(
                                            title: 'Koneksi terputus',
                                            message:
                                                'Data dashboard terakhir tetap ditampilkan. Sambungkan internet lalu coba lagi.',
                                            onRetry: _loadDashboardData,
                                          ),
                                        ),
                                      if (_showMetricsOfflinePage)
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              0, 12, 0, 0),
                                          child: NoConnectionState.card(
                                            title:
                                                'Dashboard metrik belum bisa dimuat',
                                            message:
                                                'Kami belum bisa mengambil data dashboard metrik untuk periode ini. Cek koneksi internet Anda lalu coba lagi.',
                                            onRetry: _loadDashboardData,
                                          ),
                                        ),
                                      if (_dashboardError != null &&
                                          !_showMetricsOfflineBanner &&
                                          !_showMetricsOfflinePage)
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              24, 12, 24, 0),
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF2F2),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                const Expanded(
                                                  child: Text(
                                                    'Gagal memuat data periode terbaru.',
                                                    style: TextStyle(
                                                      color: Color(0xFFB91C1C),
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: _loadDashboardData,
                                                  child:
                                                      const Text('Coba Lagi'),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      if (!_isLoadingDashboard &&
                                          _dashboardData != null) ...[
                                        LayoutBuilder(
                                          builder:
                                              (context, headerConstraints) {
                                            final twoSideBySide =
                                                headerConstraints.maxWidth >=
                                                    300;
                                            if (twoSideBySide) {
                                              return Row(
                                                children: [
                                                  Expanded(
                                                    child: _MiniStatCard(
                                                      title: 'BMI Terbaru',
                                                      value: data.latestBmi ==
                                                              null
                                                          ? '-'
                                                          : data.latestBmi!
                                                              .toStringAsFixed(
                                                                  1),
                                                      background: Colors.white,
                                                      foreground: const Color(
                                                          0xFF1A202C),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 24),
                                                  Expanded(
                                                    child: _MiniStatCard(
                                                      title: 'Tinggi Badan',
                                                      value:
                                                          '${data.latestHeightCm.toStringAsFixed(0)} cm',
                                                      background: const Color(
                                                          0xFFE13D5A),
                                                      foreground: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }

                                            return Column(
                                              children: [
                                                _MiniStatCard(
                                                  title: 'BMI Terbaru',
                                                  value: data.latestBmi == null
                                                      ? '-'
                                                      : data.latestBmi!
                                                          .toStringAsFixed(1),
                                                  background: Colors.white,
                                                  foreground:
                                                      const Color(0xFF1A202C),
                                                ),
                                                const SizedBox(height: 12),
                                                _MiniStatCard(
                                                  title: 'Tinggi Badan',
                                                  value:
                                                      '${data.latestHeightCm.toStringAsFixed(0)} cm',
                                                  background:
                                                      const Color(0xFFE13D5A),
                                                  foreground: Colors.white,
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 24),
                                        Wrap(
                                          spacing: 24,
                                          runSpacing: 24,
                                          children: [
                                            SizedBox(
                                              width: chartWidth,
                                              child: _WeightAndBodyCard(
                                                  data: data),
                                            ),
                                            SizedBox(
                                              width: chartWidth,
                                              child: _HeartRateCard(data: data),
                                            ),
                                            SizedBox(
                                              width: chartWidth,
                                              child: _BloodPressureCard(
                                                  data: data),
                                            ),
                                            SizedBox(
                                              width: chartWidth,
                                              child: _Spo2Card(data: data),
                                            ),
                                          ],
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWellnessInsightsTab(
    PatientDashboardData data,
    double fullWidth,
    CurrentDiaryState currentDiaryState,
    AsyncValue<MedicationCalendarResponse> routineAdherenceAsync,
  ) {
    if (_isLoadingDashboard && _dashboardData == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Color(0xFFE13D5A)),
        ),
      );
    }

    if (_showMetricsOfflinePage) {
      return NoConnectionState.card(
        title: 'Ringkasan belum bisa dimuat',
        message:
            'Kami belum bisa mengambil ringkasan metrik untuk periode ini. Cek koneksi internet Anda lalu coba lagi.',
        onRetry: _loadDashboardData,
      );
    }

    if (_dashboardError != null && _dashboardData == null) {
      return Container(
        width: fullWidth,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan belum tersedia',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _dashboardError ?? 'Gagal memuat data.',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadDashboardData,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE13D5A),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    final diary = currentDiaryState.diary;
    final heroSubtitle = _selectedPeriod?.label ?? 'Periode aktif';
    final latestSummaryTime = _buildLatestSummaryTime(data);
    final cardWidth = fullWidth >= 900 ? (fullWidth - 12) / 2 : fullWidth;
    final routineInsight = _routineInsight(routineAdherenceAsync);
    final completionCount = _completedDiarySections(diary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F3),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  heroSubtitle,
                  style: const TextStyle(
                    color: Color(0xFFE13D5A),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ringkasan wellness harian',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                latestSummaryTime,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _InsightChip(
                    label: 'Catatan hari ini ${completionCount.clamp(0, 4)}/4',
                  ),
                  _InsightChip(
                    label: routineInsight.chipLabel,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _WellnessHighlightCard(
                title: 'Aktivitas Hari Ini',
                value: _activityInsightValue(currentDiaryState),
                helper: _activityInsightHelper(currentDiaryState),
                icon: Icons.directions_walk_rounded,
                accentColor: const Color(0xFF0284C7),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _WellnessHighlightCard(
                title: 'Tidur Terakhir',
                value: _sleepInsightValue(currentDiaryState),
                helper: _sleepInsightHelper(currentDiaryState),
                icon: Icons.bedtime_rounded,
                accentColor: const Color(0xFF4F46E5),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _WellnessHighlightCard(
                title: 'Rutinitas 7 Hari',
                value: routineInsight.value,
                helper: routineInsight.helper,
                icon: Icons.event_note_rounded,
                accentColor: const Color(0xFFF59E0B),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _WellnessHighlightCard(
                title: 'Kelengkapan Catatan',
                value: '$completionCount/4 area',
                helper: _diaryCompletionHelper(diary),
                icon: Icons.checklist_rounded,
                accentColor: const Color(0xFF0F766E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildBodyTrendSummary(data),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stack = constraints.maxWidth < 520;
              final button = FilledButton.icon(
                onPressed: () {
                  ref.read(dashboardNavIndexProvider.notifier).state = 2;
                  context.go('/home');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE13D5A),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text(
                  'Buka Catatan',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              );

              const textSection = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Perbarui catatan harian',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Tambahkan asupan, aktivitas, tidur, dan metrik agar grafik wellness Anda tetap terisi.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              );

              if (stack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    textSection,
                    const SizedBox(height: 16),
                    SizedBox(width: double.infinity, child: button),
                  ],
                );
              }

              return Row(
                children: [
                  const Expanded(child: textSection),
                  const SizedBox(width: 16),
                  button,
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  String _buildLatestSummaryTime(PatientDashboardData data) {
    final dates = <DateTime>[
      for (final point in data.heartRatePoints) point.timestamp,
      for (final point in data.bloodPressurePoints) point.timestamp,
      for (final point in data.spo2Points) point.timestamp,
      for (final point in data.weightPoints) point.timestamp,
      for (final point in data.bmiPoints) point.timestamp,
    ]..sort((a, b) => b.compareTo(a));

    if (dates.isEmpty) {
      return 'Belum ada catatan metrik pada periode ini.';
    }

    final latest = dates.first;
    final label = _selectedPeriod?.label ?? 'periode yang dipilih';
    return 'Catatan terakhir tersedia pada ${_formatDashboardDateTime(latest)} untuk $label.';
  }

  MedicationCalendarRangeQuery _routineInsightsQuery() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return MedicationCalendarRangeQuery(
      from: today.subtract(const Duration(days: 6)),
      to: today,
    );
  }

  String _activityInsightValue(CurrentDiaryState state) {
    if (state.isLoading && state.diary == null) {
      return 'Memuat...';
    }

    final totalMinutes = _activityTotalMinutes(state.diary);
    if (totalMinutes <= 0) {
      return 'Belum ada';
    }

    return '$totalMinutes menit';
  }

  String _activityInsightHelper(CurrentDiaryState state) {
    if (state.isLoading && state.diary == null) {
      return 'Sedang memuat catatan aktivitas hari ini.';
    }

    final sessions = state.diary?.activities.length ?? 0;
    if (sessions == 0) {
      return 'Tambahkan aktivitas dari Catatan untuk melihat total harian.';
    }

    return '$sessions sesi tercatat hari ini.';
  }

  int _activityTotalMinutes(DiaryDetail? diary) {
    return (diary?.activities ?? const <DiaryActivity>[]).fold<int>(
      0,
      (total, item) => total + (item.duration?.round() ?? 0),
    );
  }

  String _sleepInsightValue(CurrentDiaryState state) {
    if (state.isLoading && state.diary == null) {
      return 'Memuat...';
    }

    final latestSleep = _latestSleepEntry(state.diary);
    final duration = latestSleep?.sleepDurationHours?.toDouble();
    if (latestSleep == null || duration == null || duration <= 0) {
      return 'Belum ada';
    }

    return '${duration.toStringAsFixed(1)} jam';
  }

  String _sleepInsightHelper(CurrentDiaryState state) {
    if (state.isLoading && state.diary == null) {
      return 'Sedang memuat catatan tidur terakhir.';
    }

    final latestSleep = _latestSleepEntry(state.diary);
    if (latestSleep == null) {
      return 'Tambahkan jam tidur untuk melihat pola istirahat terbaru.';
    }

    final sleepTime =
        latestSleep.sleepTime.isEmpty ? '--:--' : latestSleep.sleepTime;
    final wakeTime =
        latestSleep.wakeTime.isEmpty ? '--:--' : latestSleep.wakeTime;
    return 'Tidur $sleepTime - bangun $wakeTime.';
  }

  DiarySleep? _latestSleepEntry(DiaryDetail? diary) {
    final sleeps = diary?.sleeps ?? const <DiarySleep>[];
    if (sleeps.isEmpty) return null;
    return sleeps.last;
  }

  int _completedDiarySections(DiaryDetail? diary) {
    var completed = 0;
    if ((diary?.bodyMetrics ?? const <DiaryBodyMetric>[]).isNotEmpty) {
      completed++;
    }
    if ((diary?.activities ?? const <DiaryActivity>[]).isNotEmpty) {
      completed++;
    }
    if ((diary?.consumptions ?? const <DiaryConsumption>[]).isNotEmpty) {
      completed++;
    }
    if ((diary?.sleeps ?? const <DiarySleep>[]).isNotEmpty) {
      completed++;
    }
    return completed;
  }

  String _diaryCompletionHelper(DiaryDetail? diary) {
    final completed = _completedDiarySections(diary);
    if (completed == 0) {
      return 'Belum ada area catatan yang terisi hari ini.';
    }
    if (completed == 4) {
      return 'Semua area utama sudah terisi untuk hari ini.';
    }
    return 'Masih ada ${4 - completed} area yang bisa Anda lengkapi hari ini.';
  }

  _RoutineInsight _routineInsight(
    AsyncValue<MedicationCalendarResponse> asyncValue,
  ) {
    if (asyncValue.isLoading && !asyncValue.hasValue) {
      return const _RoutineInsight(
        value: 'Memuat...',
        helper: 'Sedang mengambil jadwal rutinitas 7 hari terakhir.',
        chipLabel: 'Rutinitas dimuat',
      );
    }

    final response = asyncValue.valueOrNull;
    if (response == null) {
      return const _RoutineInsight(
        value: 'Belum ada',
        helper: 'Belum ada jadwal rutinitas yang bisa diringkas.',
        chipLabel: 'Rutinitas belum ada',
      );
    }

    final items = response.items;
    if (items.isEmpty) {
      return const _RoutineInsight(
        value: 'Tidak ada jadwal',
        helper: 'Tidak ada rutinitas terjadwal dalam 7 hari terakhir.',
        chipLabel: '0 jadwal rutinitas',
      );
    }

    final takenCount = items.where((item) {
      final status = (item.status ?? '').trim().toLowerCase();
      return status == 'taken';
    }).length;
    final loggedCount = items.where((item) {
      final status = (item.status ?? '').trim().toLowerCase();
      return status == 'taken' || status == 'missed' || status == 'skipped';
    }).length;

    return _RoutineInsight(
      value: '$takenCount/${items.length} selesai',
      helper: '$loggedCount dari ${items.length} jadwal sudah diberi status.',
      chipLabel: '${items.length} jadwal rutinitas',
    );
  }

  Widget _buildBodyTrendSummary(PatientDashboardData data) {
    final weightTrend = _weightTrendText(data);
    final bmiValue =
        data.latestBmi == null ? '-' : data.latestBmi!.toStringAsFixed(1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tren Tubuh Sederhana',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ditampilkan sebagai perbandingan catatan terakhir tanpa penilaian medis.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BodyTrendTile(
                  label: 'Berat Badan',
                  value: data.latestWeight == null
                      ? '-'
                      : '${data.latestWeight!.toStringAsFixed(1)} kg',
                  helper: weightTrend,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BodyTrendTile(
                  label: 'BMI Terakhir',
                  value: bmiValue,
                  helper: '${data.bmiPoints.length} catatan pada periode ini.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _weightTrendText(PatientDashboardData data) {
    final latest = data.latestWeight;
    final previous = data.latestWeightPrevious;
    if (latest == null) {
      return 'Belum ada catatan berat badan terbaru.';
    }
    if (previous == null) {
      return 'Belum ada pembanding dari catatan sebelumnya.';
    }

    final delta = latest - previous;
    final sign = delta > 0 ? '+' : '';
    return 'Perubahan dari catatan sebelumnya: $sign${delta.toStringAsFixed(1)} kg.';
  }

  String _formatDashboardDateTime(DateTime dateTime) {
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

    final month = months[dateTime.month - 1];
    return '${dateTime.day} $month ${dateTime.year}, '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  PatientDashboardData _emptyDashboardData(TimePeriodOption selectedPeriod) {
    return PatientDashboardData(
      patient: const PatientProfile(
        id: '',
        firstName: '',
        lastName: '',
      ),
      periods: _periodOptions,
      selectedPeriod: selectedPeriod,
      heartRatePoints: const [],
      bloodPressurePoints: const [],
      spo2Points: const [],
      weightPoints: const [],
      bmiPoints: const [],
      latestHeightCm: 0,
      heartRateThreshold: const HeartRateThreshold(
        normalMin: 60,
        normalMax: 100,
      ),
      bloodPressureThreshold: const BloodPressureThreshold(
        normalSystolicMax: 120,
        normalDiastolicMax: 80,
        elevatedSystolicMin: 120,
        elevatedSystolicMax: 129,
        elevatedDiastolicMax: 80,
        stage1SystolicMin: 130,
        stage1SystolicMax: 139,
        stage1DiastolicMin: 80,
        stage1DiastolicMax: 89,
        stage2SystolicMin: 140,
        stage2DiastolicMin: 90,
      ),
      spo2Threshold: const Spo2Threshold(
        criticalThreshold: 90,
        cautionThreshold: 95,
      ),
      weightThreshold: const WeightThreshold(
        dailyIncreaseCriticalKg: 2,
      ),
    );
  }

  String? _normalizeNullable(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }

  List<ChartPoint> _buildChartPoints(
    List<String> timestamps,
    List<num?> values,
  ) {
    final length = math.min(timestamps.length, values.length);
    final points = <ChartPoint>[];

    for (var index = 0; index < length; index++) {
      final value = values[index];
      if (value == null) continue;

      final timestamp = DateTime.parse(timestamps[index]).toLocal();
      points.add(
        ChartPoint(
          timestamp: timestamp,
          value: value.toDouble(),
        ),
      );
    }

    return points;
  }

  List<BloodPressurePoint> _buildBloodPressurePoints(
    List<String> timestamps,
    List<num?> systolicValues,
    List<num?> diastolicValues,
  ) {
    final length = math.min(
      timestamps.length,
      math.min(systolicValues.length, diastolicValues.length),
    );
    final points = <BloodPressurePoint>[];

    for (var index = 0; index < length; index++) {
      final systolic = systolicValues[index];
      final diastolic = diastolicValues[index];
      if (systolic == null || diastolic == null) continue;

      final timestamp = DateTime.parse(timestamps[index]).toLocal();
      points.add(
        BloodPressurePoint(
          timestamp: timestamp,
          systolic: systolic.toDouble(),
          diastolic: diastolic.toDouble(),
        ),
      );
    }

    return points;
  }

  num? _lastNonNull(List<num?>? values) {
    if (values == null) return null;
    for (var index = values.length - 1; index >= 0; index--) {
      final value = values[index];
      if (value != null) return value;
    }
    return null;
  }

  Widget _buildNotReadySection(double fullWidth) {
    final readinessGroups = _readinessGroups;

    return Container(
      width: fullWidth,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 64, color: Color(0xFFE13D5A)),
          const SizedBox(height: 16),
          const Text(
            'Data Belum Lengkap',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Beberapa data profil dan catatan harian Anda belum lengkap untuk menyusun insight. Silakan lengkapi kuesioner atau catatan harian terlebih dahulu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          if (readinessGroups.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Area yang perlu dilengkapi (${readinessGroups.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1A202C),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ...readinessGroups.map((group) {
              final accent = _readinessGroupAccent(group.type);
              final previewLabels = group.fieldLabels.take(3).toList();
              final remainingCount =
                  group.fieldLabels.length - previewLabels.length;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _readinessGroupIcon(group.type),
                              color: accent,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group.title,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A202C),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  group.description,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF64748B),
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (previewLabels.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Text(
                          'Contoh data yang masih kosong:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...previewLabels.map(
                              (label) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: accent.withOpacity(0.20),
                                  ),
                                ),
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ),
                            if (remainingCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '+$remainingCount lainnya',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: accent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (group.hasAction) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: accent,
                              side: BorderSide(color: accent),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => _handleReadinessGroupAction(group),
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: Text(
                              group.buttonLabel!,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
          if (readinessGroups.isEmpty && _missingFields.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Data yang kurang:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A202C),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ..._missingFields
                .map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '• $f',
                          style: const TextStyle(
                            color: Color(0xFFE13D5A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ))
                .take(5),
            if (_missingFields.length > 5)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '• ...dan ${_missingFields.length - 5} lainnya',
                    style: const TextStyle(
                      color: Color(0xFFE13D5A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
          if (readinessGroups.isEmpty) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE13D5A),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                context.go('/home');
              },
              icon: const Icon(Icons.edit_document),
              label: const Text(
                'Lengkapi Form',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _getProbability() {
    return 0.0;
  }

  String _getGeneratedDateStr() {
    return 'Hari Ini';
  }

  Widget _buildRekomendasiSection() {
    return const SizedBox.shrink();
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  _StickyTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFFAFAFA),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}

class PatientDashboardData {
  const PatientDashboardData({
    required this.patient,
    required this.periods,
    required this.heartRatePoints,
    required this.bloodPressurePoints,
    required this.spo2Points,
    required this.weightPoints,
    required this.bmiPoints,
    required this.latestHeightCm,
    required this.heartRateThreshold,
    required this.bloodPressureThreshold,
    required this.spo2Threshold,
    required this.weightThreshold,
    this.avatarUrl,
    this.selectedPeriod,
  });

  final PatientProfile patient;
  final List<TimePeriodOption> periods;
  final TimePeriodOption? selectedPeriod;
  final List<ChartPoint> heartRatePoints;
  final List<BloodPressurePoint> bloodPressurePoints;
  final List<ChartPoint> spo2Points;
  final List<ChartPoint> weightPoints;
  final List<ChartPoint> bmiPoints;
  final double latestHeightCm;
  final String? avatarUrl;
  final HeartRateThreshold heartRateThreshold;
  final BloodPressureThreshold bloodPressureThreshold;
  final Spo2Threshold spo2Threshold;
  final WeightThreshold weightThreshold;

  double? get latestHeartRate => heartRatePoints.lastOrNull?.value;
  BloodPressurePoint? get latestBloodPressure => bloodPressurePoints.lastOrNull;
  double? get latestSpo2 => spo2Points.lastOrNull?.value;
  double? get latestWeight => weightPoints.lastOrNull?.value;
  double? get latestWeightPrevious => weightPoints.length > 1
      ? weightPoints[weightPoints.length - 2].value
      : null;
  double? get latestBmi => bmiPoints.lastOrNull?.value;
}

class PatientProfile {
  const PatientProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.sex,
    this.dateOfBirth,
    this.phone,
    this.email,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? sex;
  final String? dateOfBirth;
  final String? phone;
  final String? email;

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final first = firstName.isEmpty ? '' : firstName.substring(0, 1);
    final last = lastName.isEmpty ? '' : lastName.substring(0, 1);
    return '$first$last'.toUpperCase();
  }
}

class PatientSearchResult {
  const PatientSearchResult({
    required this.id,
    required this.name,
    this.subtitle,
  });

  final String id;
  final String name;
  final String? subtitle;
}

class TimePeriodOption {
  const TimePeriodOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

class ChartPoint {
  const ChartPoint({
    required this.timestamp,
    required this.value,
  });

  final DateTime timestamp;
  final double value;
}

class BloodPressurePoint {
  const BloodPressurePoint({
    required this.timestamp,
    required this.systolic,
    required this.diastolic,
  });

  final DateTime timestamp;
  final double systolic;
  final double diastolic;
}

class HeartRateThreshold {
  const HeartRateThreshold({
    required this.normalMin,
    required this.normalMax,
  });

  final double normalMin;
  final double normalMax;
}

class BloodPressureThreshold {
  const BloodPressureThreshold({
    required this.normalSystolicMax,
    required this.normalDiastolicMax,
    required this.elevatedSystolicMin,
    required this.elevatedSystolicMax,
    required this.elevatedDiastolicMax,
    required this.stage1SystolicMin,
    required this.stage1SystolicMax,
    required this.stage1DiastolicMin,
    required this.stage1DiastolicMax,
    required this.stage2SystolicMin,
    required this.stage2DiastolicMin,
  });

  final double normalSystolicMax;
  final double normalDiastolicMax;
  final double elevatedSystolicMin;
  final double elevatedSystolicMax;
  final double elevatedDiastolicMax;
  final double stage1SystolicMin;
  final double stage1SystolicMax;
  final double stage1DiastolicMin;
  final double stage1DiastolicMax;
  final double stage2SystolicMin;
  final double stage2DiastolicMin;
}

class Spo2Threshold {
  const Spo2Threshold({
    required this.criticalThreshold,
    required this.cautionThreshold,
  });

  final double criticalThreshold;
  final double cautionThreshold;
}

class WeightThreshold {
  const WeightThreshold({
    required this.dailyIncreaseCriticalKg,
  });

  final double dailyIncreaseCriticalKg;
}

class _DashboardSidebar extends StatelessWidget {
  const _DashboardSidebar({
    required this.data,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.onLogout,
    required this.logoUrl,
  });

  final PatientDashboardData data;
  final TimePeriodOption? selectedPeriod;
  final ValueChanged<TimePeriodOption?>? onPeriodChanged;
  final VoidCallback? onLogout;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Center(
              child: logoUrl == null
                  ? const Text(
                      'PulseWise',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE13D5A),
                      ),
                    )
                  : Image.network(logoUrl!, height: 40, fit: BoxFit.contain),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SidebarLabel('Akun Aktif'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.patient.fullName.isEmpty
                              ? 'Pengguna PulseWise'
                              : data.patient.fullName,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          data.patient.email?.trim().isNotEmpty == true
                              ? data.patient.email!
                              : 'Ringkasan wellness pribadi Anda',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _SidebarLabel('Rentang Waktu'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedPeriod?.id,
                    items: data.periods
                        .map(
                          (period) => DropdownMenuItem<String>(
                            value: period.id,
                            child: Text(period.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      final period = data.periods
                          .where((it) => it.id == value)
                          .firstOrNull;
                      onPeriodChanged?.call(period);
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: onLogout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE13D5A),
                      side: const BorderSide(color: Color(0xFFF99B9F)),
                      backgroundColor: const Color(0xFFFFF0F2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Logout'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarLabel extends StatelessWidget {
  const _SidebarLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFFE13D5A),
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _PatientHeaderCard extends StatelessWidget {
  const _PatientHeaderCard({
    required this.patient,
    this.avatarUrl,
  });

  final PatientProfile patient;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final sexRaw = patient.sex?.trim();
    final properGender = (sexRaw == null || sexRaw.isEmpty)
        ? '-'
        : '${sexRaw[0].toUpperCase()}${sexRaw.substring(1).toLowerCase()}';
    String properName = patient.fullName
        .split(' ')
        .map((word) => word.isEmpty
            ? ""
            : "${word[0].toUpperCase()}${word.substring(1).toLowerCase()}")
        .join(' ');
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PatientAvatar(avatarUrl: avatarUrl, initials: patient.initials),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      properName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A202C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _DetailItem(label: 'Jenis Kelamin', value: properGender),
                    _DetailItem(
                      label: 'Tanggal Lahir',
                      value: patient.dateOfBirth ?? '-',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientAvatar extends StatelessWidget {
  const _PatientAvatar({
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
              Icons.person,
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

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Color(0xFF1A202C),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      softWrap: true,
      overflow: TextOverflow.visible,
    );
  }
}

class PredictionMetricCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String description;
  final double score;
  final double chartHeight;

  const PredictionMetricCard({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.description,
    required this.score,
    this.chartHeight = 280,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1A202C),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Description Panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Text(
                  'Berikut adalah skor insight terbaru yang membantu Anda melihat ringkasan pola dari data yang tersedia saat ini.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A202C),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Gauge Section
          SizedBox(
            height: chartHeight,
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: 0,
                  maximum: 100,
                  startAngle: 180,
                  endAngle: 0,
                  canScaleToFit: true,
                  showLabels: false,
                  showTicks: false,
                  axisLineStyle: const AxisLineStyle(
                    thickness: 0.1,
                    thicknessUnit: GaugeSizeUnit.factor,
                    color: Color(0xFFF1F5F9),
                  ),
                  ranges: <GaugeRange>[
                    GaugeRange(
                        startValue: 0,
                        endValue: 60,
                        color: Colors.green,
                        startWidth: 15,
                        endWidth: 15),
                    GaugeRange(
                        startValue: 60,
                        endValue: 80,
                        color: Colors.orange,
                        startWidth: 15,
                        endWidth: 15),
                    GaugeRange(
                        startValue: 80,
                        endValue: 100,
                        color: Colors.red,
                        startWidth: 15,
                        endWidth: 15),
                  ],
                  pointers: <GaugePointer>[
                    // Pointer modern berbentuk segitiga terbalik
                    MarkerPointer(
                      value: score,
                      markerType: MarkerType.invertedTriangle,
                      color: const Color(0xFF1A202C),
                      markerHeight: 15,
                      markerWidth: 15,
                      // positionFactor: 0.08,
                      enableAnimation: true,
                      animationDuration: 1500,
                    ),
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      widget: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${score.toInt()}%',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A202C),
                            ),
                          ),
                          const Text(
                            'RISK SCORE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      // angle: 90,
                      // positionFactor: 0.5,
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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

class _HeartRateCard extends StatelessWidget {
  const _HeartRateCard({required this.data});

  final PatientDashboardData data;

  @override
  Widget build(BuildContext context) {
    final latest = data.latestHeartRate;
    return _MetricCard(
      title: 'Detak Jantung',
      icon: Icons.favorite_rounded,
      iconColor: const Color(0xFFE13D5A),
      legend: const _ChartLegend(items: [
        ChartLegendItem(color: Color(0xFFE13D5A), label: 'Catatan'),
      ]),
      chartHeight: 220,
      leadingPanel: _LatestValuePanel(
        label: 'Catatan Terakhir',
        value: latest?.toStringAsFixed(0) ?? '-',
        unit: 'bpm',
        valueColor: const Color(0xFF1A202C),
      ),
      chart: data.heartRatePoints.isEmpty
          ? const _EmptyChartPlaceholder(label: 'Belum ada data detak jantung')
          : _ThresholdLineChart(
              points: data.heartRatePoints,
              minY: _dynamicMin(data.heartRatePoints, fallback: 50),
              maxY: _dynamicMax(data.heartRatePoints, fallback: 120),
              lineBars: _buildSegmentBars(
                points: data.heartRatePoints,
                segmentColor: (_, __, ___) => const Color(0xFFE13D5A),
                dotColor: (_, __) => const Color(0xFFE13D5A),
              ),
              yTitle: 'bpm',
            ),
    );
  }
}

class _BloodPressureCard extends StatelessWidget {
  const _BloodPressureCard({required this.data});

  final PatientDashboardData data;

  @override
  Widget build(BuildContext context) {
    final latest = data.latestBloodPressure;
    final values = data.bloodPressurePoints;
    final allNumbers = [
      for (final point in values) point.systolic,
      for (final point in values) point.diastolic,
    ];

    return _MetricCard(
      title: 'Tekanan Darah',
      icon: Icons.monitor_heart,
      iconColor: const Color(0xFF2563EB),
      legend: const _ChartLegend(items: [
        ChartLegendItem(color: Color(0xFF2563EB), label: 'Sistolik'),
        ChartLegendItem(color: Color(0xFF0F766E), label: 'Diastolik'),
      ]),
      chartHeight: 220,
      leadingPanel: _LatestValuePanel(
        label: 'Catatan Terakhir',
        value: latest == null
            ? '-'
            : '${latest.systolic.toStringAsFixed(0)}/${latest.diastolic.toStringAsFixed(0)}',
        unit: 'mmHg',
        valueColor: const Color(0xFF1A202C),
        compact: true,
      ),
      chart: values.isEmpty
          ? const _EmptyChartPlaceholder(label: 'Belum ada data tekanan darah')
          : _ThresholdLineChart(
              points: values
                  .map((point) => ChartPoint(
                      timestamp: point.timestamp, value: point.systolic))
                  .toList(),
              minY:
                  math.max(40.0, (allNumbers.reduce(math.min) - 20)).toDouble(),
              maxY: allNumbers.reduce(math.max) + 20,
              lineBars: [
                ..._buildSegmentBars(
                  points: values
                      .map(
                        (point) => ChartPoint(
                          timestamp: point.timestamp,
                          value: point.systolic,
                        ),
                      )
                      .toList(),
                  segmentColor: (_, __, ___) => const Color(0xFF2563EB),
                  dotColor: (_, __) => const Color(0xFF2563EB),
                ),
                ..._buildSegmentBars(
                  points: values
                      .map(
                        (point) => ChartPoint(
                          timestamp: point.timestamp,
                          value: point.diastolic,
                        ),
                      )
                      .toList(),
                  segmentColor: (_, __, ___) => const Color(0xFF0F766E),
                  dotColor: (_, __) => const Color(0xFF0F766E),
                ),
              ],
              yTitle: 'mmHg',
            ),
    );
  }
}

class _Spo2Card extends StatelessWidget {
  const _Spo2Card({required this.data});

  final PatientDashboardData data;

  @override
  Widget build(BuildContext context) {
    final latest = data.latestSpo2;
    return _MetricCard(
      title: 'Saturasi Oksigen',
      icon: Icons.bubble_chart,
      iconColor: const Color(0xFF0EA5E9),
      legend: const _ChartLegend(items: [
        ChartLegendItem(color: Color(0xFF0EA5E9), label: 'Catatan'),
      ]),
      chartHeight: 220,
      leadingPanel: _LatestValuePanel(
        label: 'Catatan Terakhir',
        value: latest?.toStringAsFixed(0) ?? '-',
        unit: '%',
        valueColor: const Color(0xFF1A202C),
      ),
      chart: data.spo2Points.isEmpty
          ? const _EmptyChartPlaceholder(
              label: 'Belum ada data saturasi oksigen')
          : _ThresholdLineChart(
              points: data.spo2Points,
              minY: 80,
              maxY: 100,
              lineBars: _buildSegmentBars(
                points: data.spo2Points,
                segmentColor: (_, __, ___) => const Color(0xFF0EA5E9),
                dotColor: (_, __) => const Color(0xFF0EA5E9),
              ),
              yTitle: '%',
            ),
    );
  }
}

class _WeightAndBodyCard extends StatelessWidget {
  const _WeightAndBodyCard({required this.data});

  final PatientDashboardData data;

  @override
  Widget build(BuildContext context) {
    final latestWeight = data.latestWeight;
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 760;

        final weightCard = _MetricCard(
          title: 'Berat Badan',
          icon: Icons.monitor_weight_outlined,
          iconColor: const Color(0xFFF59E0B),
          legend: const _ChartLegend(items: [
            ChartLegendItem(color: Color(0xFFF59E0B), label: 'Catatan'),
          ]),
          chartHeight: 190,
          verticalBody: true,
          leadingPanel: Center(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: latestWeight?.toStringAsFixed(1) ?? '-',
                    style: const TextStyle(
                      color: Color(0xFF1A202C),
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const TextSpan(
                    text: ' kg',
                    style: TextStyle(
                      color: Color(0xFF4A5568),
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          chart: data.weightPoints.isEmpty
              ? const _EmptyChartPlaceholder(
                  label: 'Belum ada data berat badan')
              : _ThresholdLineChart(
                  points: data.weightPoints,
                  minY: _dynamicMin(data.weightPoints, fallback: 60),
                  maxY: _dynamicMax(data.weightPoints, fallback: 100),
                  lineBars: _buildSegmentBars(
                    points: data.weightPoints,
                    segmentColor: (_, __, ___) => const Color(0xFFF59E0B),
                    dotColor: (_, __) => const Color(0xFFF59E0B),
                  ),
                  yTitle: 'kg',
                ),
        );

        if (stacked) {
          return Column(
            children: [
              SizedBox(height: 420, child: weightCard),
            ],
          );
        }

        return SizedBox(
          height: 420,
          child: Row(
            children: [
              Expanded(flex: 2, child: weightCard),
            ],
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.leadingPanel,
    required this.chart,
    this.legend,
    this.chartHeight = 220,
    this.verticalBody = false,
  });

  final String title;
  final IconData icon;
  final Widget leadingPanel;
  final Color iconColor;
  final Widget chart;
  final Widget? legend;
  final double chartHeight;
  final bool verticalBody;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(icon, color: iconColor, size: 30),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF1A202C),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              // Container(
              //   width: 44,
              //   height: 44,
              //   decoration: BoxDecoration(
              //     color: const Color(0xFFFFF0F2),
              //     borderRadius: BorderRadius.circular(22),
              //   ),
              //   child: Icon(icon, color: const Color(0xFFE13D5A)),
              // ),
            ],
          ),
          const SizedBox(height: 20),
          if (verticalBody) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(22),
              ),
              child: leadingPanel,
            ),
            const SizedBox(height: 12),
            if (legend != null) ...[
              legend!,
              const SizedBox(height: 12),
            ],
            SizedBox(height: chartHeight, child: chart),
          ] else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final stack = constraints.maxWidth < 620;
                if (stack) {
                  return Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: leadingPanel,
                      ),
                      const SizedBox(height: 12),
                      if (legend != null) ...[
                        legend!,
                        const SizedBox(height: 12),
                      ],
                      SizedBox(height: chartHeight, child: chart),
                    ],
                  );
                }

                return Row(
                  children: [
                    Container(
                      width: 190,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: leadingPanel,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          if (legend != null) ...[
                            legend!,
                            const SizedBox(height: 12),
                          ],
                          SizedBox(height: chartHeight, child: chart),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _LatestValuePanel extends StatelessWidget {
  const _LatestValuePanel({
    required this.label,
    required this.value,
    required this.unit,
    required this.valueColor,
    this.compact = false,
  });

  final String label;
  final String value;
  final String unit;
  final Color valueColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: valueColor,
            fontSize: compact ? 40 : 47,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          unit,
          style: const TextStyle(
            color: Color(0xFF4A5568),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _InsightChip extends StatelessWidget {
  const _InsightChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BodyTrendTile extends StatelessWidget {
  const _BodyTrendTile({
    required this.label,
    required this.value,
    required this.helper,
  });

  final String label;
  final String value;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            helper,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineInsight {
  const _RoutineInsight({
    required this.value,
    required this.helper,
    required this.chipLabel,
  });

  final String value;
  final String helper;
  final String chipLabel;
}

class _WellnessHighlightCard extends StatelessWidget {
  const _WellnessHighlightCard({
    required this.title,
    required this.value,
    required this.helper,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String value;
  final String helper;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            helper,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
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
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
        border: background == Colors.white
            ? Border.all(color: const Color(0xFFF1F5F9))
            : null,
      ),
      child: Column(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: foreground
                  .withOpacity(background == Colors.white ? 0.55 : 0.85),
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: foreground,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class ChartLegendItem {
  const ChartLegendItem({required this.color, required this.label});

  final Color color;
  final String label;
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.items});

  final List<ChartLegendItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: items.map((it) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: it.color,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white, width: 0.5),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              it.label,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _ThresholdLineChart extends StatelessWidget {
  const _ThresholdLineChart({
    required this.points,
    required this.lineBars,
    required this.yTitle,
    this.minY,
    this.maxY,
    this.horizontalLines = const [],
  });

  final List<ChartPoint> points;
  final List<LineChartBarData> lineBars;
  final String yTitle;
  final double? minY;
  final double? maxY;
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
          horizontalInterval: _gridInterval(minY ?? 0, maxY ?? 100),
          drawVerticalLine: false,
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
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            // drawBelowEverything: true,
            axisNameWidget: Text(
              yTitle,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            // axisNameWidget: Padding(
            //   padding: const EdgeInsets.only(bottom: 8),
            //   child: Text(
            //     yTitle,
            //     style: const TextStyle(
            //       color: Color(0xFF94A3B8),
            //       fontSize: 11,
            //       fontWeight: FontWeight.w700,
            //     ),
            //   ),
            // ),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 37,
              interval: _gridInterval(minY ?? 0, maxY ?? 100),
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
              reservedSize: 34,
              interval: _xInterval(points.length),
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 10,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _shortDate(points[index].timestamp),
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: lineBars,
      ),
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

List<LineChartBarData> _buildSegmentBars({
  required List<ChartPoint> points,
  required Color Function(int index, ChartPoint current, ChartPoint? previous)
      segmentColor,
  required Color Function(int index, ChartPoint point) dotColor,
}) {
  if (points.isEmpty) {
    return const [];
  }

  final bars = <LineChartBarData>[];

  if (points.length == 1) {
    bars.add(
      LineChartBarData(
        spots: [FlSpot(0, points.first.value)],
        isCurved: false,
        color: Colors.transparent,
        barWidth: 0.01,
        belowBarData: BarAreaData(show: false),
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, bar, index) {
            return FlDotCirclePainter(
              radius: 4.5,
              color: dotColor(index, points[index]),
              strokeWidth: 2,
              strokeColor: Colors.white,
            );
          },
        ),
      ),
    );
    return bars;
  }

  for (var index = 1; index < points.length; index++) {
    final previous = points[index - 1];
    final current = points[index];
    bars.add(
      LineChartBarData(
        spots: [
          FlSpot((index - 1).toDouble(), previous.value),
          FlSpot(index.toDouble(), current.value),
        ],
        isCurved: true,
        curveSmoothness: 0.2,
        color: segmentColor(index, current, previous),
        barWidth: 3,
        belowBarData: BarAreaData(show: false),
        dotData: const FlDotData(show: false),
      ),
    );
  }

  bars.add(
    LineChartBarData(
      spots: [
        for (var index = 0; index < points.length; index++)
          FlSpot(index.toDouble(), points[index].value),
      ],
      isCurved: true,
      curveSmoothness: 0.2,
      color: Colors.transparent,
      barWidth: 0.01,
      belowBarData: BarAreaData(show: false),
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) {
          return FlDotCirclePainter(
            radius: 4.5,
            color: dotColor(index, points[index]),
            strokeWidth: 2,
            strokeColor: Colors.white,
          );
        },
      ),
    ),
  );

  return bars;
}

double _dynamicMin(List<ChartPoint> points, {required double fallback}) {
  if (points.isEmpty) {
    return fallback;
  }
  final minValue = points.map((point) => point.value).reduce(math.min);
  return math.max(0.0, minValue - 5).toDouble();
}

double _dynamicMax(List<ChartPoint> points, {required double fallback}) {
  if (points.isEmpty) {
    return fallback;
  }
  final maxValue = points.map((point) => point.value).reduce(math.max);
  return maxValue + 5;
}

double _gridInterval(double minY, double maxY) {
  final range = (maxY - minY).abs();
  if (range <= 10) {
    return 2.0;
  }
  if (range <= 30) {
    return 5.0;
  }
  if (range <= 80) {
    return 10.0;
  }
  return 20.0;
}

double _xInterval(int length) {
  if (length <= 4) {
    return 1.0;
  }
  if (length <= 8) {
    return 2.0;
  }
  if (length <= 16) {
    return 3.0;
  }
  return 4.0;
}

String _shortDate(DateTime value) {
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
  return '${value.day} ${months[value.month - 1]}';
}

Color _heartRateValueColor(double value, HeartRateThreshold threshold) {
  if (value < threshold.normalMin || value > threshold.normalMax) {
    return const Color(0xFFE13D5A);
  }
  return const Color(0xFF1A202C);
}

Color _heartRateChartColor(double value, HeartRateThreshold threshold) {
  if (value < threshold.normalMin || value > threshold.normalMax) {
    return const Color(0xFFDC2626);
  }
  return const Color(0xFF2563EB);
}

Color _bloodPressureValueColor(
  double systolic,
  double diastolic,
  BloodPressureThreshold threshold,
) {
  if (systolic >= threshold.stage2SystolicMin ||
      diastolic >= threshold.stage2DiastolicMin) {
    return const Color(0xFFE13D5A);
  }
  if ((systolic >= threshold.stage1SystolicMin &&
          systolic <= threshold.stage1SystolicMax) ||
      (diastolic >= threshold.stage1DiastolicMin &&
          diastolic <= threshold.stage1DiastolicMax)) {
    return const Color(0xFFF97316);
  }
  if (systolic >= threshold.elevatedSystolicMin &&
      systolic <= threshold.elevatedSystolicMax &&
      diastolic < threshold.elevatedDiastolicMax) {
    return const Color(0xFFFACC15);
  }
  return const Color(0xFF1A202C);
}

Color _systolicChartColor(
  double systolic,
  double diastolic,
  BloodPressureThreshold threshold,
) {
  if (systolic >= threshold.stage2SystolicMin ||
      diastolic >= threshold.stage2DiastolicMin) {
    return const Color(0xFFDC2626);
  }
  if ((systolic >= threshold.stage1SystolicMin &&
          systolic <= threshold.stage1SystolicMax) ||
      (diastolic >= threshold.stage1DiastolicMin &&
          diastolic <= threshold.stage1DiastolicMax)) {
    return const Color(0xFFF97316);
  }
  if (systolic >= threshold.elevatedSystolicMin &&
      systolic <= threshold.elevatedSystolicMax &&
      diastolic < threshold.elevatedDiastolicMax) {
    return const Color(0xFFFCD34D);
  }
  return const Color(0xFF2563EB);
}

Color _diastolicChartColor(
  double systolic,
  double diastolic,
  BloodPressureThreshold threshold,
) {
  if (systolic >= threshold.stage2SystolicMin ||
      diastolic >= threshold.stage2DiastolicMin) {
    return const Color(0xFFE13D5A);
  }
  if ((systolic >= threshold.stage1SystolicMin &&
          systolic <= threshold.stage1SystolicMax) ||
      (diastolic >= threshold.stage1DiastolicMin &&
          diastolic <= threshold.stage1DiastolicMax)) {
    return const Color(0xFFF97316);
  }
  if (systolic >= threshold.elevatedSystolicMin &&
      systolic <= threshold.elevatedSystolicMax &&
      diastolic <= threshold.elevatedDiastolicMax) {
    return const Color(0xFFFACC15);
  }
  return const Color(0xFF10B981);
}

Color _spo2ValueColor(double value, Spo2Threshold threshold) {
  if (value < threshold.criticalThreshold) {
    return const Color(0xFFE13D5A);
  }
  if (value < threshold.cautionThreshold) {
    return const Color(0xFFFACC15);
  }
  return const Color(0xFF1A202C);
}

Color _spo2ChartColor(double value, Spo2Threshold threshold) {
  if (value < threshold.criticalThreshold) {
    return const Color(0xFFDC2626);
  }
  if (value < threshold.cautionThreshold) {
    return const Color(0xFFFCD34D);
  }
  return const Color(0xFF2563EB);
}

Color _weightColor(
  double currentWeight,
  double? previousWeight,
  WeightThreshold threshold,
) {
  if (previousWeight == null) {
    return const Color(0xFF2563EB);
  }
  final change = (currentWeight - previousWeight).abs();
  if (change > threshold.dailyIncreaseCriticalKg) {
    return const Color(0xFFE13D5A);
  }
  return const Color(0xFF2563EB);
}

extension<T> on Iterable<T> {
  T? get lastOrNull => isEmpty ? null : last;
  T? get firstOrNull => isEmpty ? null : first;
}
