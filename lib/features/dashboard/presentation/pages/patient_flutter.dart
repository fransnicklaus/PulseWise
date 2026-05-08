import 'dart:convert';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/features/dashboard/presentation/providers/profile_provider.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import 'report_generator_flutter.dart';

class PatientDashboardPage extends ConsumerStatefulWidget {
  const PatientDashboardPage({
    super.key,
    required this.data,
    this.searchResults = const [],
    this.logoUrl,
    this.onSearchChanged,
    this.onPatientSelected,
    this.onTimePeriodChanged,
    this.onLogout,
    this.reportRepository,
    this.onPrintReport,
  });

  final PatientDashboardData data;
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

  bool _isLoadingLast = true;
  bool _isCheckingMl = false;
  Map<String, dynamic>? _lastAssessment;
  List<String> _missingFields = [];
  MlRecommendationResponse? _mlRecommendation;
  MlRecommendationResponse? _mlPredictionResult;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedPeriod = widget.data.selectedPeriod;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
    });
  }

  Future<void> _fetchInitialData() async {
    if (!mounted) return;
    setState(() => _isLoadingLast = true);
    try {
      final api = ref.read(profileApiProvider);

      final futures = await Future.wait([
        api.fetchLatestMlAssessment().catchError((e) {
          debugPrint('Error fetching last assessment: $e');
          return <String, dynamic>{};
        }),
        api.fetchLatestMlRecommendation().catchError((e) {
          debugPrint('Error fetching last ML recommendation: $e');
          return null; // Return null instead of empty map since it expects MlRecommendationResponse?
        }),
      ]);

      final last = futures[0] as Map<String, dynamic>?;
      final rec = futures[1] as MlRecommendationResponse?;

      if (mounted) {
        setState(() {
          _lastAssessment = last != null && last.isNotEmpty ? last : null;
          if (rec != null && rec.success) {
            _mlRecommendation = rec;
            _mlPredictionResult = rec.data?.upstream != null ? rec : null;
          }
          _isLoadingLast = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching initial data: $e');
      if (mounted) {
        setState(() {
          _isLoadingLast = false;
        });
      }
    }
  }

  Future<void> _checkMlReadinessAndPredict() async {
    if (!mounted) return;
    setState(() {
      _isCheckingMl = true;
      _missingFields = [];
    });
    try {
      final date = DateTime.now().toIso8601String().split('T').first;
      final api = ref.read(profileApiProvider);
      final readiness = await api.fetchMlReadiness(date);

      final isReady = readiness['ready'] == true;
      if (isReady) {
        // await api.fetchMlPrediction(date); // Not used currently, just call
        final rec = await api.fetchMlRecommendations(date);
        if (mounted) {
          setState(() {
            // Kita map rec result sebagai prediction result jika available
            if (rec != null && rec.data?.upstream != null) {
              _mlPredictionResult = rec;
            }
            _mlRecommendation = rec;
            _isCheckingMl = false;
          });
        }
      } else {
        final missing = (readiness['missingFields'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        if (mounted) {
          setState(() {
            _missingFields = missing;
            _isCheckingMl = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking ML readiness: $e');
      if (mounted) {
        setState(() {
          _isCheckingMl = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleGenerateReport() async {
    final repository = widget.reportRepository;
    if (repository == null) {
      return;
    }

    await showPatientReportFlow(
      context,
      patientId: widget.data.patient.id,
      repository: repository,
      onPrintRequested: widget.onPrintReport,
    );
  }

  void _handleSearchChanged(String value) {
    setState(() {});
    widget.onSearchChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final sidebar = _DashboardSidebar(
      data: widget.data,
      searchController: _searchController,
      searchResults: widget.searchResults,
      selectedPeriod: _selectedPeriod,
      onSearchChanged: _handleSearchChanged,
      onPatientSelected: widget.onPatientSelected,
      onPeriodChanged: (period) {
        setState(() => _selectedPeriod = period);
        widget.onTimePeriodChanged?.call(period);
      },
      onGenerateReport:
          widget.reportRepository == null ? null : _handleGenerateReport,
      onLogout: widget.onLogout,
      logoUrl: widget.logoUrl,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: CustomAppBar(
        title: 'Dashboard Pasien',
        // subtitle: 'Hubungi segera jika diperlukan',
        showBackButton: true,
        onBackPressed: () => context.pop(),
        action: IconButton(
          icon: const Icon(Icons.print, color: Colors.white),
          onPressed: () => context.push('/home/patient-dashboard/print'),
        ),
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
                    child: NestedScrollView(
                      headerSliverBuilder: (context, innerBoxIsScrolled) {
                        return [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: _PatientHeaderCard(
                                patient: widget.data.patient,
                                avatarUrl: widget.data.avatarUrl,
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
                                    fontWeight: FontWeight.bold, fontSize: 17),
                                unselectedLabelStyle: TextStyle(
                                    fontWeight: FontWeight.w300, fontSize: 17),
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
                          // Tab 1: Prediction results + Rekomendasi
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: _isLoadingLast
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(40),
                                      child: CircularProgressIndicator(
                                        color: Color(0xFFE13D5A),
                                      ),
                                    ),
                                  )
                                : _isCheckingMl
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(40),
                                          child: Column(
                                            children: [
                                              CircularProgressIndicator(
                                                color: Color(0xFFE13D5A),
                                              ),
                                              SizedBox(height: 16),
                                              Text(
                                                'Mengecek kesiapan data dan\nmemproses prediksi...',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : _mlRecommendation != null
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton.icon(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFFE13D5A),
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 12),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                  ),
                                                  onPressed:
                                                      _checkMlReadinessAndPredict,
                                                  icon: const Icon(
                                                      Icons.refresh,
                                                      size: 28),
                                                  label: const Text(
                                                      'Jalankan Prediksi Lagi',
                                                      style: TextStyle(
                                                          fontSize: 18)),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: OutlinedButton.icon(
                                                      style: OutlinedButton
                                                          .styleFrom(
                                                        foregroundColor:
                                                            const Color(
                                                                0xFFE13D5A),
                                                        side: const BorderSide(
                                                            color: Color(
                                                                0xFFE13D5A)),
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 12),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                      ),
                                                      onPressed: () => context.push(
                                                          '/home/patient-dashboard/ml-assessment'),
                                                      icon: const Icon(
                                                          Icons.edit_document,
                                                          size: 28),
                                                      label: const Text(
                                                          'Isi Form',
                                                          style: TextStyle(
                                                              fontSize: 18)),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: OutlinedButton.icon(
                                                      style: OutlinedButton
                                                          .styleFrom(
                                                        foregroundColor:
                                                            const Color(
                                                                0xFFE13D5A),
                                                        side: const BorderSide(
                                                            color: Color(
                                                                0xFFE13D5A)),
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 12),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                      ),
                                                      onPressed: () => context.push(
                                                          '/home/patient-dashboard/ml-recommendation-history'),
                                                      icon: const Icon(
                                                          Icons.history,
                                                          size: 28),
                                                      label: const Text(
                                                          'Cek History',
                                                          style: TextStyle(
                                                              fontSize: 18)),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 24),
                                              if (_mlPredictionResult !=
                                                  null) ...[
                                                SizedBox(
                                                  width: fullWidth,
                                                  child: PredictionMetricCard(
                                                    title: 'Prediksi',
                                                    icon:
                                                        Icons.insights_rounded,
                                                    iconColor:
                                                        const Color(0xFFE13D5A),
                                                    description:
                                                        'Dihasilkan pada: ${_getGeneratedDateStr()}',
                                                    score: _getProbability(),
                                                  ),
                                                ),
                                                const SizedBox(height: 24),
                                              ],
                                              _buildRekomendasiSection(
                                                  _mlRecommendation),
                                            ],
                                          )
                                        : _missingFields.isNotEmpty
                                            ? _buildNotReadySection(fullWidth)
                                            : Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const SizedBox(height: 24),
                                                  Center(
                                                    child: ElevatedButton.icon(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                                0xFFE13D5A),
                                                        foregroundColor:
                                                            Colors.white,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 24,
                                                          vertical: 16,
                                                        ),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(16),
                                                        ),
                                                      ),
                                                      onPressed:
                                                          _checkMlReadinessAndPredict,
                                                      icon: const Icon(
                                                          Icons.analytics),
                                                      label: const Text(
                                                        'Cek Prediksi ML Hari Ini',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(height: 16),
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: FilledButton.icon(
                                                      onPressed: () => context.push(
                                                          '/home/patient-dashboard/ml-assessment'),
                                                      style: FilledButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                                0xFFE64060),
                                                        foregroundColor:
                                                            Colors.white,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 14),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(14),
                                                        ),
                                                      ),
                                                      icon: const Icon(
                                                          Icons
                                                              .assignment_turned_in_rounded,
                                                          size: 18),
                                                      label: const Text(
                                                        'Isi Form Asesmen',
                                                        style: TextStyle(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w700),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                          ),
                          // Tab 2: Dashboard charts and cards
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LayoutBuilder(
                                  builder: (context, headerConstraints) {
                                    final twoSideBySide =
                                        headerConstraints.maxWidth >= 300;
                                    if (twoSideBySide) {
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: _MiniStatCard(
                                              title: 'Latest BMI',
                                              value:
                                                  widget.data.latestBmi == null
                                                      ? '-'
                                                      : widget.data.latestBmi!
                                                          .toStringAsFixed(1),
                                              background: Colors.white,
                                              foreground:
                                                  const Color(0xFF1A202C),
                                            ),
                                          ),
                                          const SizedBox(width: 24),
                                          Expanded(
                                            child: _MiniStatCard(
                                              title: 'Height',
                                              value:
                                                  '${widget.data.latestHeightCm.toStringAsFixed(0)} cm',
                                              background:
                                                  const Color(0xFFE13D5A),
                                              foreground: Colors.white,
                                            ),
                                          ),
                                        ],
                                      );
                                    }

                                    return Column(
                                      children: [
                                        _MiniStatCard(
                                          title: 'Latest BMI',
                                          value: widget.data.latestBmi == null
                                              ? '-'
                                              : widget.data.latestBmi!
                                                  .toStringAsFixed(1),
                                          background: Colors.white,
                                          foreground: const Color(0xFF1A202C),
                                        ),
                                        const SizedBox(height: 12),
                                        _MiniStatCard(
                                          title: 'Height',
                                          value:
                                              '${widget.data.latestHeightCm.toStringAsFixed(0)} cm',
                                          background: const Color(0xFFE13D5A),
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
                                      child:
                                          _WeightAndBodyCard(data: widget.data),
                                    ),
                                    SizedBox(
                                      width: chartWidth,
                                      child: _HeartRateCard(data: widget.data),
                                    ),
                                    SizedBox(
                                      width: chartWidth,
                                      child:
                                          _BloodPressureCard(data: widget.data),
                                    ),
                                    SizedBox(
                                      width: chartWidth,
                                      child: _Spo2Card(data: widget.data),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildNotReadySection(double fullWidth) {
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
            'Beberapa data kesehatan pasien belum lengkap untuk melakukan prediksi ML. Silakan lengkapi form kuisioner atau data harian.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          if (_missingFields.isNotEmpty) ...[
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
          const SizedBox(height: 32),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE13D5A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              context.push('/home/patient-dashboard/ml-assessment');
            },
            icon: const Icon(Icons.edit_document),
            label: const Text(
              'Lengkapi Form',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          )
        ],
      ),
    );
  }

  double _getProbability() {
    if (_mlPredictionResult == null) return 0.0;
    try {
      final recResult =
          _mlPredictionResult?.data?.upstream?.body?.recommendationResult;
      if (recResult != null) {
        if (recResult.currentRisk > 0) {
          final val = recResult.currentRisk;
          return val.clamp(0.0, 100.0);
        }
      }
    } catch (_) {}
    return 0.0;
  }

  String _getGeneratedDateStr() {
    if (_mlPredictionResult == null) return 'Hari Ini';
    final genAt = _mlPredictionResult?.data?.generatedAt;
    if (genAt != null && genAt.isNotEmpty) {
      try {
        final date = DateTime.parse(genAt).toLocal();
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
                child: const Icon(Icons.recommend, color: Color(0xFFE13D5A)),
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
            // final rec = item.recommendedValueInterval;
            // final changeStatus = item.changeStatus;
            // String action = '';

            return RecommendationItem(
              title: title,
              // description: item.description,
              action: 'increase',
            );
          }),
          ...recommendationDecrease.map((item) {
            final title =
                item.comparison.isNotEmpty ? item.comparison : item.description;
            // final rec = item.recommendedValueInterval;
            // final changeStatus = item.changeStatus;
            // String action = '';

            return RecommendationItem(
              title: title,
              // description: item.description,
              action: 'decrease',
            );
          }),
        ],
      ),
    );
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
    required this.searchController,
    required this.searchResults,
    required this.selectedPeriod,
    required this.onSearchChanged,
    required this.onPatientSelected,
    required this.onPeriodChanged,
    required this.onGenerateReport,
    required this.onLogout,
    required this.logoUrl,
  });

  final PatientDashboardData data;
  final TextEditingController searchController;
  final List<PatientSearchResult> searchResults;
  final TimePeriodOption? selectedPeriod;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<PatientSearchResult>? onPatientSelected;
  final ValueChanged<TimePeriodOption?>? onPeriodChanged;
  final VoidCallback? onGenerateReport;
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
                  const _SidebarLabel('Search Patient'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Find patient...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (searchController.text.isNotEmpty &&
                      searchResults.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: searchResults.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, index) {
                          final item = searchResults[index];
                          return ListTile(
                            title: Text(item.name),
                            subtitle: item.subtitle == null
                                ? null
                                : Text(item.subtitle!),
                            onTap: () => onPatientSelected?.call(item),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const _SidebarLabel('Time Period'),
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
                  FilledButton.icon(
                    onPressed: onGenerateReport,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE13D5A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: const Icon(Icons.description_rounded),
                    label: const Text('Generate Report'),
                  ),
                  const SizedBox(height: 12),
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
    String properGender =
        patient.sex![0].toUpperCase() + patient.sex!.substring(1).toLowerCase();
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
                    _DetailItem(label: 'Sex', value: properGender),
                    _DetailItem(
                      label: 'Date of Birth',
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF1A202C),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
                Text(
                  'Berikut adalah skor risiko kesehatan terbaru pasien yang menunjukkan probabilitas komplikasi serius dalam waktu dekat',
                  style: const TextStyle(
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
    final latestColor = latest == null
        ? const Color(0xFF1A202C)
        : _heartRateValueColor(latest, data.heartRateThreshold);

    return _MetricCard(
      title: 'Heart Rate',
      icon: Icons.favorite_rounded,
      iconColor: const Color(0xFFE13D5A),
      legend: const _ChartLegend(items: [
        ChartLegendItem(color: Color(0xFF2563EB), label: 'Normal'),
        ChartLegendItem(color: Color(0xFFDC2626), label: 'Out of range'),
      ]),
      chartHeight: 220,
      leadingPanel: _LatestValuePanel(
        label: 'Latest Reading',
        value: latest?.toStringAsFixed(0) ?? '-',
        unit: 'bpm',
        valueColor: latestColor,
      ),
      chart: data.heartRatePoints.isEmpty
          ? const _EmptyChartPlaceholder(label: 'No heart rate data')
          : _ThresholdLineChart(
              points: data.heartRatePoints,
              minY: math
                  .min(50.0, data.heartRateThreshold.normalMin - 15)
                  .toDouble(),
              maxY: math
                  .max(120.0, data.heartRateThreshold.normalMax + 15)
                  .toDouble(),
              horizontalLines: [
                data.heartRateThreshold.normalMin,
                data.heartRateThreshold.normalMax,
              ],
              lineBars: _buildSegmentBars(
                points: data.heartRatePoints,
                segmentColor: (index, current, previous) {
                  return _heartRateChartColor(
                    current.value,
                    data.heartRateThreshold,
                  );
                },
                dotColor: (index, point) {
                  return _heartRateChartColor(
                    point.value,
                    data.heartRateThreshold,
                  );
                },
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
    final latestColor = latest == null
        ? const Color(0xFF1A202C)
        : _bloodPressureValueColor(
            latest.systolic,
            latest.diastolic,
            data.bloodPressureThreshold,
          );

    final values = data.bloodPressurePoints;
    final allNumbers = [
      for (final point in values) point.systolic,
      for (final point in values) point.diastolic,
    ];

    return _MetricCard(
      title: 'Blood Pressure',
      icon: Icons.monitor_heart,
      iconColor: Colors.blue,
      legend: const _ChartLegend(items: [
        ChartLegendItem(color: Color(0xFF2563EB), label: 'Systolic'),
        ChartLegendItem(color: Color(0xFF10B981), label: 'Diastolic'),
      ]),
      chartHeight: 220,
      leadingPanel: _LatestValuePanel(
        label: 'Latest Reading',
        value: latest == null
            ? '-'
            : '${latest.systolic.toStringAsFixed(0)}/${latest.diastolic.toStringAsFixed(0)}',
        unit: 'mmHg',
        valueColor: latestColor,
        compact: true,
      ),
      chart: values.isEmpty
          ? const _EmptyChartPlaceholder(label: 'No blood pressure data')
          : _ThresholdLineChart(
              points: values
                  .map((point) => ChartPoint(
                      timestamp: point.timestamp, value: point.systolic))
                  .toList(),
              minY:
                  math.max(40.0, (allNumbers.reduce(math.min) - 20)).toDouble(),
              maxY: allNumbers.reduce(math.max) + 20,
              horizontalLines: [
                data.bloodPressureThreshold.normalSystolicMax,
                data.bloodPressureThreshold.stage1SystolicMin,
                data.bloodPressureThreshold.stage2SystolicMin,
              ],
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
                  segmentColor: (index, current, previous) {
                    final raw = values[index];
                    return _systolicChartColor(
                      raw.systolic,
                      raw.diastolic,
                      data.bloodPressureThreshold,
                    );
                  },
                  dotColor: (index, point) {
                    final raw = values[index];
                    return _systolicChartColor(
                      raw.systolic,
                      raw.diastolic,
                      data.bloodPressureThreshold,
                    );
                  },
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
                  segmentColor: (index, current, previous) {
                    final raw = values[index];
                    return _diastolicChartColor(
                      raw.systolic,
                      raw.diastolic,
                      data.bloodPressureThreshold,
                    );
                  },
                  dotColor: (index, point) {
                    final raw = values[index];
                    return _diastolicChartColor(
                      raw.systolic,
                      raw.diastolic,
                      data.bloodPressureThreshold,
                    );
                  },
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
    final latestColor = latest == null
        ? const Color(0xFF1A202C)
        : _spo2ValueColor(latest, data.spo2Threshold);

    return _MetricCard(
      title: 'Oxygen Saturation (SpO2)',
      icon: Icons.bubble_chart,
      iconColor: Colors.green[700]!,
      legend: const _ChartLegend(items: [
        ChartLegendItem(color: Color(0xFF2563EB), label: 'Normal'),
        ChartLegendItem(color: Color(0xFFFCD34D), label: 'Caution'),
        ChartLegendItem(color: Color(0xFFDC2626), label: 'Critical'),
      ]),
      chartHeight: 220,
      leadingPanel: _LatestValuePanel(
        label: 'Latest SpO2',
        value: latest?.toStringAsFixed(0) ?? '-',
        unit: '%',
        valueColor: latestColor,
      ),
      chart: data.spo2Points.isEmpty
          ? const _EmptyChartPlaceholder(label: 'No SpO2 data')
          : _ThresholdLineChart(
              points: data.spo2Points,
              minY: 80,
              maxY: 100,
              horizontalLines: [
                data.spo2Threshold.criticalThreshold,
                data.spo2Threshold.cautionThreshold,
              ],
              lineBars: _buildSegmentBars(
                points: data.spo2Points,
                segmentColor: (index, current, previous) {
                  return _spo2ChartColor(current.value, data.spo2Threshold);
                },
                dotColor: (index, point) {
                  return _spo2ChartColor(point.value, data.spo2Threshold);
                },
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
    final latestWeightColor = latestWeight == null
        ? const Color(0xFF1A202C)
        : _weightColor(
            latestWeight,
            data.latestWeightPrevious,
            data.weightThreshold,
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 760;

        final weightCard = _MetricCard(
          title: 'Weight',
          icon: Icons.monitor_weight_outlined,
          iconColor: Colors.yellow[700]!,
          legend: const _ChartLegend(items: [
            ChartLegendItem(color: Color(0xFF2563EB), label: 'Recent'),
            ChartLegendItem(color: Color(0xFFE13D5A), label: 'Large change'),
          ]),
          chartHeight: 190,
          verticalBody: true,
          leadingPanel: Center(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: latestWeight?.toStringAsFixed(1) ?? '-',
                    style: TextStyle(
                      color: latestWeightColor,
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
              ? const _EmptyChartPlaceholder(label: 'No weight data')
              : _ThresholdLineChart(
                  points: data.weightPoints,
                  minY: _dynamicMin(data.weightPoints, fallback: 60),
                  maxY: _dynamicMax(data.weightPoints, fallback: 100),
                  lineBars: _buildSegmentBars(
                    points: data.weightPoints,
                    segmentColor: (index, current, previous) {
                      return _weightColor(
                        current.value,
                        previous?.value,
                        data.weightThreshold,
                      );
                    },
                    dotColor: (index, point) {
                      final previous =
                          index > 0 ? data.weightPoints[index - 1].value : null;
                      return _weightColor(
                        point.value,
                        previous,
                        data.weightThreshold,
                      );
                    },
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
